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

let _player = Player()

class Player: AudioProviderDelegate {
    var engine:AVAudioEngine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    
    init() {
        self.configure()
        self.startSession()
    }
    
    func configure() {
        let mainMixer = self.engine.mainMixerNode
        
        self.engine.attachNode(self.playerNode);
        self.engine.connect(self.playerNode, to: mainMixer, format: nil)
    }
    
    let description:AudioStreamBasicDescription = {
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
    
    var frameIndex = 0
    var audioFile = ExtAudioFileRef()
    
    func play(track:TrackItem) {
        do {
//            let file = try AVAudioFile(forReading: url)
//            let buffer = AVAudioPCMBuffer(PCMFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
//            try  file.readIntoBuffer(buffer)
//            
//            self.playerNode.scheduleBuffer(buffer, completionHandler: nil)
            
            if track.source == .Spotify {
                self.spotifyProvider.startProvidingAudio(track)
            }
            
            if !self.engine.running {
                try self.engine.start()
            }
            self.playerNode.play()
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
    
    lazy var spotifyProvider:SpotifyAudioProvider = {
       let provider = SpotifyAudioProvider()
        provider.delegate = self
        return provider
    }()
    
    func provider(provider:AudioProvider?, hasNewBuffer:AVAudioPCMBuffer) {
        self.playerNode.scheduleBuffer(hasNewBuffer, completionHandler: nil)
    }
}

protocol AudioProviderDelegate:class {
    func provider(provider:AudioProvider?, hasNewBuffer:AVAudioPCMBuffer)
}

protocol AudioProvider {
    weak var delegate:AudioProviderDelegate? { get set }
    func startProvidingAudio(track:Playable)
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
        override func attemptToDeliverAudioFrames(audioFrames: UnsafePointer<Void>, ofCount frameCount: Int, var streamDescription audioDescription: AudioStreamBasicDescription) -> Int {
            if let delegate = self.providerDelegate {
                let buffer = AVAudioPCMBuffer(PCMFormat: AVAudioFormat(streamDescription: &audioDescription), frameCapacity: AVAudioFrameCount(frameCount))
                buffer.frameLength = AVAudioFrameCount(frameCount)
                buffer.int32ChannelData.memory.assignFrom(UnsafeMutablePointer<Int32>(audioFrames), count: frameCount)
                delegate.provider(self.provider, hasNewBuffer: buffer)
            }
            return 0
        }
    }
    
    let audioController = SpotifyCoreAudioController()
    lazy var streamController:SPTAudioStreamingController = SPTAudioStreamingController(clientId: _spotifyController.clientID, audioController: self.audioController)
}
