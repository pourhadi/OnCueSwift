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
        struct RenderContextInfo {
            var delegate:AudioProviderDelegate
            var outputUnit:AudioUnit
            var formatDescription:AVAudioFormat
        }
        
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
        
        var genericNode:AUNode = 0
        var genericDescription: AudioComponentDescription  = {
            var cd:AudioComponentDescription = AudioComponentDescription(componentType: OSType(kAudioUnitType_Output),componentSubType: OSType(kAudioUnitSubType_GenericOutput),componentManufacturer: OSType(kAudioUnitManufacturer_Apple),componentFlags: 0,componentFlagsMask: 0)
            return cd
        }()

        override func connectOutputBus(sourceOutputBusNumber: UInt32, ofNode sourceNode: AUNode, toInputBus destinationInputBusNumber: UInt32, ofNode destinationNode: AUNode, inGraph graph: AUGraph) throws {
//            do { try super.connectOutputBus(sourceOutputBusNumber, ofNode: sourceNode, toInputBus: destinationInputBusNumber, ofNode: destinationNode, inGraph: graph) } catch { print("error") }

            if self.genericNode == 0 {
                AUGraphAddNode(graph, &genericDescription, &genericNode)
                
                let audioUnit:UnsafeMutablePointer<AudioUnit> = UnsafeMutablePointer<AudioUnit>()
                let outDesc:UnsafeMutablePointer<AudioComponentDescription> = nil
                AUGraphNodeInfo(graph, genericNode, outDesc, audioUnit)
                
                let inputUnit:UnsafeMutablePointer<AudioUnit> = nil
                AUGraphNodeInfo(graph, sourceNode, outDesc, inputUnit)
                
                let val:UInt32 = 4096
                var maxFramesSlice:UInt32 = val
                AudioUnitSetProperty (
                    audioUnit.memory,
                    kAudioUnitProperty_MaximumFramesPerSlice,
                    kAudioUnitScope_Global,
                    0,
                    &maxFramesSlice,
                    UInt32(sizeof (UInt32))
                )
                
                var inputDescription:AudioStreamBasicDescription = AudioStreamBasicDescription()
                var size:UInt32 = UInt32(sizeof(AudioStreamBasicDescription))
                AudioUnitGetProperty(inputUnit.memory, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &inputDescription, &size)
                size = UInt32(sizeof(AudioStreamBasicDescription))
//                var descPointer = UnsafePointer<AudioStreamBasicDescription>(&inputDescription)
                AudioUnitSetProperty(audioUnit.memory, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &inputDescription, size)
                AudioUnitSetProperty(audioUnit.memory, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, inFormatDescription!.streamDescription, size)
                AUGraphConnectNodeInput(graph, sourceNode, sourceOutputBusNumber, genericNode, 0)
                
                let callback:AURenderCallbackStruct = AURenderCallbackStruct(inputProc: { (inRefCon, acitonFlags, timeStamp, inBusNumber, inNumberFrames, buffer) -> OSStatus in
                    let pointer = UnsafeMutablePointer<RenderContextInfo>(inRefCon)
                    let del:AudioProviderDelegate = pointer.memory.delegate
                    let audioUnit = pointer.memory.outputUnit
                    
                    AudioUnitRender(audioUnit, acitonFlags, timeStamp, inBusNumber, inNumberFrames, buffer)
                    let avBuffer = AVAudioPCMBuffer(PCMFormat: pointer.memory.formatDescription, frameCapacity: AVAudioFrameCount(inNumberFrames))
                    avBuffer.mutableAudioBufferList.memory = buffer.memory
                    del.provider(nil, hasNewBuffer: avBuffer)
                    print("render called back")
                    return 0
                    }, inputProcRefCon: nil)
                
                let contextInfo = RenderContextInfo(delegate: self.providerDelegate!, outputUnit: audioUnit.memory, formatDescription:inFormatDescription!)
                
                let pointer:UnsafeMutablePointer<RenderContextInfo> = UnsafeMutablePointer<RenderContextInfo>()
                pointer.memory = contextInfo
                AUGraphAddRenderNotify(graph, callback.inputProc, pointer)
            }
            
            
            
        }
        
        /*
        override func attemptToDeliverAudioFrames(audioFrames: UnsafePointer<Void>, ofCount frameCount: Int, var streamDescription audioDescription: AudioStreamBasicDescription) -> Int {
            self.inFormat = AVAudioFormat(streamDescription: &audioDescription)
            if let delegate = self.providerDelegate {
                let buffer = AVAudioPCMBuffer(PCMFormat: AVAudioFormat(streamDescription: &audioDescription), frameCapacity: AVAudioFrameCount(frameCount))
                
/*AudioBuffer buf;
buf.mData = (void*)audioFrames;
buf.mDataByteSize = (UInt32)audioDescription.mBytesPerFrame * (UInt32)frameCount;
buf.mNumberChannels = audioDescription.mChannelsPerFrame;

AudioBufferList list;
list.mNumberBuffers = 1;
list.mBuffers[0] = buf;*/
                
                var mem = audioFrames.memory
                let buf = AudioBuffer(mNumberChannels: UInt32(audioDescription.mChannelsPerFrame), mDataByteSize: audioDescription.mBytesPerFrame * UInt32(frameCount), mData: &mem)
                var list = AudioBufferList(mNumberBuffers: 1, mBuffers: buf)
                buffer.mutableAudioBufferList.memory = list
//                if buffer.floatChannelData != nil {
//                } else if buffer.int16ChannelData != nil {
//                    var intBuffer = UnsafeBufferPointer(start:audioFrames, count:frameCount)
//                    
//                    for var x = 0; x < frameCount; x += buffer.stride {
//                        buffer.int16ChannelData[x].memory = Int16(intBuffer[x])
////                        print(Int16(y))
//                        print(buffer.int16ChannelData[x].memory)
////                        lval.value = intArray[x].value
////                        print(lval.value)
//                        //                        buffer.int16ChannelData.memory[x] = intArray[x]
//                    }
//                } else if buffer.int32ChannelData != nil {
//                    buffer.int32ChannelData.memory[0] = UnsafePointer<Int32>(audioFrames)[0]
//                    buffer.int32ChannelData.memory[1] = UnsafePointer<Int32>(audioFrames)[1]
//                    
//                }
                buffer.frameLength = AVAudioFrameCount(frameCount)
                let floatBuffer = AVAudioPCMBuffer(PCMFormat: inFormatDescription!, frameCapacity: AVAudioFrameCount(frameCount))
                
                let status = AudioConverterConvertComplexBuffer(self.audioConverter, UInt32(frameCount), &list, floatBuffer.mutableAudioBufferList)
                floatBuffer.frameLength = AVAudioFrameCount(frameCount)
                print(status)
                print(floatBuffer)
                delegate.provider(self.provider, hasNewBuffer: floatBuffer)
            }
            return 0
        }
*/
    }
    
    let audioController = SpotifyCoreAudioController()
    lazy var streamController:SPTAudioStreamingController = SPTAudioStreamingController(clientId: _spotifyController.clientID, audioController: self.audioController)
}
