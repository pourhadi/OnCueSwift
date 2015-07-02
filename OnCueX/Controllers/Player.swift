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
    let libraryPlayerNode = AVAudioPlayerNode()
    
    init() {
        self.configure()
        self.startSession()
    }
    
    func configure() {
        let mainMixer = self.engine.mainMixerNode
        
        self.engine.attachNode(self.libraryPlayerNode);
        self.engine.connect(self.libraryPlayerNode, to: mainMixer, format: nil)
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
    
    func play(url:NSURL) {
        do {
            let file = try AVAudioFile(forReading: url)
            let buffer = AVAudioPCMBuffer(PCMFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
            try  file.readIntoBuffer(buffer)
            
            self.libraryPlayerNode.scheduleBuffer(buffer, completionHandler: nil)
            if !self.engine.running {
                try self.engine.start()
            }
            self.libraryPlayerNode.play()
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
    
    func provider(provider:AudioProvider, hasNewBuffer:AVAudioPCMBuffer) {
        
    }
}

protocol AudioProviderDelegate:class {
    func provider(provider:AudioProvider, hasNewBuffer:AVAudioPCMBuffer)
}

protocol AudioProvider {
    weak var delegate:AudioProviderDelegate? { get set }
    func startProvidingAudio(track:Playable)
}

class SpotifyAudioProvider: AudioProvider {
    var delegate:AudioProviderDelegate? {
        set {
            self.audioController.providerDelegate = newValue
        }
        get {
            return self.audioController.providerDelegate
        }
    }
    
    func startProvidingAudio(track: Playable) {
        
    }
    
    class SpotifyCoreAudioController : SPTCoreAudioController {
        weak var providerDelegate:AudioProviderDelegate?

        override func attemptToDeliverAudioFrames(audioFrames: UnsafePointer<Void>, ofCount frameCount: Int, var streamDescription audioDescription: AudioStreamBasicDescription) -> Int {
            if let delegate = self.providerDelegate {
                let buffer = AVAudioPCMBuffer(PCMFormat: AVAudioFormat(streamDescription: &audioDescription), frameCapacity: AVAudioFrameCount(frameCount))
                buffer.floatChannelData.memory.initialize(Float(audioFrames.memory))
            }
            return 0
        }
    }
    
    let audioController = SpotifyCoreAudioController()
    lazy var streamController:SPTAudioStreamingController = SPTAudioStreamingController(clientId: _spotifyController.clientID, audioController: self.audioController)
}
