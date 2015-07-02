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
    
/*AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
NSError *error;

// set the session category
bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);

double hwSampleRate = 44100.0;
success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);

NSTimeInterval ioBufferDuration = 0.0029;
success = [sessionInstance setPreferredIOBufferDuration:ioBufferDuration error:&error];
if (!success) NSLog(@"Error setting preferred io buffer duration! %@\n", [error localizedDescription]);

*/

//    func play(item:MPMediaItem) {
//        let url = item.assetURL!
//        ExtAudioFileOpenURL(url as CFURL, &audioFile)
//        
//        var totalFrames:Int64 = 0
//        var dataSize:UInt32 = UInt32(sizeof(Int64))
//        ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileLengthFrames, &dataSize, &totalFrames)
//        
//        var desc = AudioStreamBasicDescription()
//        dataSize = UInt32(sizeof(AudioStreamBasicDescription))
//        ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileDataFormat, &dataSize, &desc)
//        
//        ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, UInt32(sizeof(AudioStreamBasicDescription)), &desc)
//        
//        self.frameIndex = 0
//    }
}
