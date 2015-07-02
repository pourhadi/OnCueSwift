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

class Player {
    var engine:AVAudioEngine = AVAudioEngine()
    let libraryPlayerNode = AVAudioPlayerNode()
    
    init() {
        self.configure()
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
    
    var audioFile = UnsafeMutablePointer<ExtAudioFileRef>()
    func play(item:MPMediaItem) {
        let url = item.assetURL!
        ExtAudioFileOpenURL(url as CFURL, audioFile)
        
        let totalFrames = UnsafeMutablePointer<Int64>()
        let dataSize = UnsafeMutablePointer<UInt32>()
        dataSize.initialize(UInt32(sizeof(Int64)))
        ExtAudioFileGetProperty(audioFile.memory, kExtAudioFileProperty_FileLengthFrames, dataSize, totalFrames)
        
    }
}
