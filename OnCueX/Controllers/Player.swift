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

var inFormatDescription:AVAudioFormat = AVAudioFormat(standardFormatWithSampleRate: AVAudioSession.sharedInstance().sampleRate, channels: 2)
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
//        if self.spotifyNode == nil {
//            self.spotifyNode = AVAudioPlayerNode()
//            self.engine.attachNode(self.spotifyNode!)
//            print(hasNewBuffer.frameLength)
//            print(hasNewBuffer.frameCapacity)
//            print(hasNewBuffer.format)
//            self.engine.connect(self.spotifyNode!, to: self.engine.mainMixerNode, format: hasNewBuffer.format)
//            self.spotifyNode!.play()
//        }
//        self.spotifyNode!.scheduleBuffer(hasNewBuffer, completionHandler: nil)
        self.playerNode.scheduleBuffer(hasNewBuffer, completionHandler: nil)
        self.playerNode.play()
    }
}

protocol AudioProviderDelegate:class {
    func provider(provider:AudioProvider?, hasNewBuffer:AVAudioPCMBuffer)
}

protocol AudioProvider {
    weak var delegate:AudioProviderDelegate? { get set }
    func startProvidingAudio(track:Playable)
}

class LibraryAudioProvider: AudioProvider {
    var delegate:AudioProviderDelegate?
    
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
        
        lazy var audioConverter:AudioConverterRef = {
            var ref:AudioConverterRef = nil
            var outFormat = self.converter!.floatingPointAudioDescription
            var inFormat = self.inFormat!.streamDescription
            AudioConverterNew(inFormat, &outFormat, &ref)
            
            return ref
        }()
        var inFormat:AVAudioFormat?
        var converter:AEFloatConverter?
        override func attemptToDeliverAudioFrames(audioFrames: UnsafePointer<Void>, ofCount frameCount: Int, var streamDescription audioDescription: AudioStreamBasicDescription) -> Int {
            if self.converter == nil {
                self.converter = AEFloatConverter(sourceFormat: audioDescription)
            }
            
            let intArray = UnsafeMutableBufferPointer<Int16>(start: UnsafeMutablePointer<Int16>(audioFrames), count: frameCount)
            let buf = AudioBuffer(intArray, numberOfChannels:Int(audioDescription.mChannelsPerFrame))
            let bufList: UnsafeMutableAudioBufferListPointer = AudioBufferList.allocate(maximumBuffers: 1)
            bufList.unsafeMutablePointer.memory.mBuffers = buf
            
            self.inFormat = AVAudioFormat(streamDescription: &audioDescription)
            if let delegate = self.providerDelegate {
                let buffer = AVAudioPCMBuffer(PCMFormat: AVAudioFormat(streamDescription: &audioDescription), frameCapacity: AVAudioFrameCount(frameCount))
                if buffer.floatChannelData != nil {
                } else if buffer.int16ChannelData != nil {
//                    buffer.int16ChannelData.memory.initializeFrom(UnsafeMutablePointer<Int16>(audioFrames), count: frameCount)

                    let intArray = UnsafeMutableBufferPointer<Int16>(start: UnsafeMutablePointer<Int16>(audioFrames), count: frameCount)

                    for var x = 0; x < frameCount; x += buffer.stride {
                        buffer.int16ChannelData.memory[x].value = intArray[x].value
                    }
//                    buffer.mutableAudioBufferList.memory.mNumberBuffers = 1
//                    buffer.mutableAudioBufferList.memory.mBuffers.mNumberChannels = audioDescription.mChannelsPerFrame
//                    buffer.mutableAudioBufferList.memory.mBuffers.mData = UnsafeMutablePointer<Void>(audioFrames)
//                    buffer.mutableAudioBufferList.memory.mBuffers.mDataByteSize = audioDescription.mBytesPerFrame * UInt32(frameCount)
                    //                    buffer.int16ChannelData.memory.initializeFrom(UnsafeMutablePointer<Int16>(audioFrames), count: frameCount)
//                    let bufList = buffer.mutableAudioBufferList
//                    bufList.memory.mBuffers.mData.put(audioFrames.memory)
                } else if buffer.int32ChannelData != nil {
                    buffer.int32ChannelData.memory[0] = UnsafePointer<Int32>(audioFrames)[0]
                    buffer.int32ChannelData.memory[1] = UnsafePointer<Int32>(audioFrames)[1]

                }
                print(buffer.debugDescription)
                buffer.frameLength = AVAudioFrameCount(frameCount)
                print(buffer.debugDescription)
                var desc = self.converter!.floatingPointAudioDescription
                let floatBuffer = AVAudioPCMBuffer(PCMFormat: AVAudioFormat(streamDescription: &desc), frameCapacity: AVAudioFrameCount(frameCount))
                AEFloatConverterToFloat(self.converter!, buffer.mutableAudioBufferList, floatBuffer.floatChannelData, UInt32(frameCount))

//                floatBuffer.floatChannelData.memory.initializeFrom(UnsafeMutablePointer<Float>(buffer.int16ChannelData), count: frameCount)
//                AEFloatConverterToFloatBufferList(self.converter!, bufList.unsafeMutablePointer, floatBuffer.mutableAudioBufferList, UInt32(frameCount))
                var outBytes:UInt32 = UInt32(frameCount * Int(inFormatDescription.streamDescription.memory.mBytesPerFrame))
            
//                let status = AudioConverterConvertComplexBuffer(self.audioConverter, UInt32(frameCount), bufList.unsafeMutablePointer, floatBuffer.mutableAudioBufferList)
//                print(UInt32(frameCount * Int(audioDescription.mBytesPerFrame)))
//                var databuffer = floatBuffer.floatChannelData.memory
//                let status = AudioConverterConvertBuffer(self.audioConverter, UInt32(frameCount * Int(audioDescription.mBytesPerFrame / audioDescription.mChannelsPerFrame)), audioFrames, &outBytes, databuffer)
//                print(status)
//                print(outBytes)
                floatBuffer.frameLength = AVAudioFrameCount(frameCount)

                delegate.provider(self.provider, hasNewBuffer: floatBuffer)
            }
            return 0
        }
    }
    
    let audioController = SpotifyCoreAudioController()
    lazy var streamController:SPTAudioStreamingController = SPTAudioStreamingController(clientId: _spotifyController.clientID, audioController: self.audioController)
}
