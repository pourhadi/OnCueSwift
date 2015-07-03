//
//  Player.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/30/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import CoreAudio
import TheAmazingAudioEngine

let _player = Player()

var FloatDescription:AudioStreamBasicDescription = {
    var outputFormat = AudioStreamBasicDescription()
    outputFormat.mFormatID = kAudioFormatLinearPCM;
    outputFormat.mFormatFlags       = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsFloat;
    outputFormat.mSampleRate        = 44100;
    outputFormat.mChannelsPerFrame  = 2;
    outputFormat.mBitsPerChannel    = 32;
    outputFormat.mBytesPerPacket    = (outputFormat.mBitsPerChannel / 8) * outputFormat.mChannelsPerFrame;
    outputFormat.mFramesPerPacket   = 1;
    outputFormat.mBytesPerFrame     = outputFormat.mBytesPerPacket;
    return outputFormat
    }()

var inFormatDescription:AVAudioFormat?
class Player: AudioProviderDelegate {
    var engine:AVAudioEngine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    var spotifyNode:AVAudioPlayerNode?
    init() {
        self.configure()
        self.startSession()
    }
    
    func configure() {
        let mainMixer = self.engine.mainMixerNode
        
        self.engine.attachNode(self.playerNode);
        self.engine.connect(self.playerNode, to: mainMixer, format: nil)
        inFormatDescription = mainMixer.inputFormatForBus(0)
    }
    
    
    
    var frameIndex = 0
    var audioFile = ExtAudioFileRef()
    
    func play(track:TrackItem) {
        do {
//            let file = try AVAudioFile(forReading: track.assetURL)
//            let buffer = AVAudioPCMBuffer(PCMFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
//            try  file.readIntoBuffer(buffer)
//            
//            self.playerNode.scheduleBuffer(buffer, completionHandler: nil)
////            

            if !self.engine.running {
                try self.engine.start()
            }
            if track.source == .Spotify {
                self.spotifyProvider.startProvidingAudio(track)
            } else {
                self.libraryProvider.startProvidingAudio(track)
            }
            
        } catch { print("error") }
    }
    
    func startSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
        } catch {
            print("session error")
        }
        
    }
    
    lazy var libraryProvider:LibraryAudioProvider = {
        let provider = LibraryAudioProvider()
        provider.delegate = self
        return provider
        }()
    
    lazy var spotifyProvider:SpotifyAudioProvider = {
       let provider = SpotifyAudioProvider()
        provider.delegate = self
        return provider
    }()
    
    func provider(provider:AudioProvider?, hasNewBuffer:AVAudioPCMBuffer) {
        if let provider = provider {
//            if provider.isEqual(self.spotifyProvider) {
//                if self.spotifyNode == nil {
//                    self.spotifyNode = AVAudioPlayerNode()
//                    self.engine.attachNode(self.spotifyNode!)
//                    print(hasNewBuffer.frameLength)
//                    print(hasNewBuffer.frameCapacity)
//                    print(hasNewBuffer.format)
//                    self.engine.connect(self.spotifyNode!, to: self.engine.mainMixerNode, format: hasNewBuffer.format)
//                    self.spotifyNode!.play()
//                }
//                self.spotifyNode!.scheduleBuffer(hasNewBuffer, completionHandler: nil)
//            }
//            return
        }
        
        self.playerNode.scheduleBuffer(hasNewBuffer, completionHandler: nil)
        self.playerNode.play()
    }
}

protocol AudioProviderDelegate:class {
    func provider(provider:AudioProvider?, hasNewBuffer:AVAudioPCMBuffer)
}

protocol AudioProvider: Identifiable {
    weak var delegate:AudioProviderDelegate? { get set }
    func startProvidingAudio(track:Playable)
}

class LibraryAudioProvider: AudioProvider {
    var delegate:AudioProviderDelegate?
    
    var identifier:String {
        return "Library"
    }
    
    func startProvidingAudio(track: Playable) {
        do {
            let file = try AVAudioFile(forReading: track.assetURL)
            let buffer = AVAudioPCMBuffer(PCMFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
            try  file.readIntoBuffer(buffer)
            if let del = self.delegate {
                del.provider(self, hasNewBuffer: buffer)
            }
        } catch {
            print("error")
        }
    }
    
}

class SpotifyAudioProvider: AudioProvider {
    
    var identifier:String {
        return "Spotify"
    }
    
    var delegate:AudioProviderDelegate? {
        set {
            self.audioController.providerDelegate = newValue
            self.audioController.provider = self
        }
        get {
            return self.audioController.providerDelegate
        }
    }
    
    func startProvidingAudio(track: Playable) {
        if !self.streamController.loggedIn {
            self.streamController.loginWithSession(_spotifyController.session!, callback: { (error) -> Void in
                self.streamController.playURIs([track.assetURL], withOptions: nil, callback: { (error) -> Void in
                    
                })
            })
        } else {
            self.streamController.playURIs([track.assetURL], withOptions: nil, callback: { (error) -> Void in
                
            })
        }
    }
    
    class SpotifyCoreAudioController : SPTCoreAudioController {
        weak var providerDelegate:AudioProviderDelegate?
        weak var provider:SpotifyAudioProvider?
        
         @available(iOS 9.0, *)
        lazy var avConverter:AVAudioConverter = {
            return AVAudioConverter(fromFormat: self.inFormat!, toFormat: inFormatDescription!)
        }()
        
        lazy var audioConverter:AudioConverterRef = {
            var ref:AudioConverterRef = nil
            var outFormat = inFormatDescription!.streamDescription
            var inFormat = self.inFormat!.streamDescription
            AudioConverterNew(inFormat, outFormat, &ref)
            
            return ref
            }()
        var inFormat:AVAudioFormat?
        var converter:AEFloatConverter?
        override func attemptToDeliverAudioFrames(audioFrames: UnsafePointer<Void>, ofCount frameCount: Int, var streamDescription audioDescription: AudioStreamBasicDescription) -> Int {
            self.inFormat = AVAudioFormat(streamDescription: &audioDescription)
            if let delegate = self.providerDelegate {
                let buffer = AVAudioPCMBuffer(PCMFormat: AVAudioFormat(streamDescription: &audioDescription), frameCapacity: AVAudioFrameCount(frameCount))
                if buffer.floatChannelData != nil {
                } else if buffer.int16ChannelData != nil {
                    let intArray = UnsafeMutableBufferPointer<Int16>(start: UnsafeMutablePointer<Int16>(audioFrames), count: frameCount)
                    
                    for var x = 0; x < frameCount; x += buffer.stride {
                        var lval = buffer.int16ChannelData.memory[x]
                        lval.value = intArray[x].value
                        //                        buffer.int16ChannelData.memory[x] = intArray[x]
                    }
                } else if buffer.int32ChannelData != nil {
                    buffer.int32ChannelData.memory[0] = UnsafePointer<Int32>(audioFrames)[0]
                    buffer.int32ChannelData.memory[1] = UnsafePointer<Int32>(audioFrames)[1]
                    
                }
                buffer.frameLength = AVAudioFrameCount(frameCount)
                let floatBuffer = AVAudioPCMBuffer(PCMFormat: inFormatDescription!, frameCapacity: AVAudioFrameCount(frameCount))
                
                AudioConverterConvertComplexBuffer(self.audioConverter, UInt32(frameCount), buffer.audioBufferList, floatBuffer.mutableAudioBufferList)
                delegate.provider(self.provider, hasNewBuffer: floatBuffer)
            }
            return 0
        }
    }
    
    let audioController = SpotifyCoreAudioController()
    lazy var streamController:SPTAudioStreamingController = SPTAudioStreamingController(clientId: _spotifyController.clientID, audioController: self.audioController)
}
