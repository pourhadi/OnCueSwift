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

func checkError(error:OSStatus, _ operation:String?) {
//    print("status:\(error) for: \(operation)")
    guard error != noErr else { return }
    
    print("error: \(error) \(operation)")
}

var clientFormat:AudioStreamBasicDescription = {
    var clientFormat = AudioStreamBasicDescription()
    clientFormat.mFormatID = kAudioFormatLinearPCM;
    clientFormat.mFormatFlags       = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsFloat;
    clientFormat.mSampleRate        = 44100;
    clientFormat.mChannelsPerFrame  = 2;
    clientFormat.mBitsPerChannel    = 32;
    clientFormat.mBytesPerPacket    = (clientFormat.mBitsPerChannel / 8) * clientFormat.mChannelsPerFrame;
    clientFormat.mFramesPerPacket   = 1;
    clientFormat.mBytesPerFrame     = clientFormat.mBytesPerPacket;
    return clientFormat
}()

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
    
    func provider(provider:AudioProvider?, var format:AudioStreamBasicDescription) {
        
    }
    
    func configure() {
        let mainMixer = self.engine.mainMixerNode
        
        self.engine.attachNode(self.playerNode);
        self.engine.connect(self.playerNode, to: mainMixer, format: nil)
        inFormatDescription = mainMixer.inputFormatForBus(0)
    }
    
    let audioPlayer = CoreAudioPlayer()
    
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

            audioPlayer.currentTrack = track
            audioPlayer.playing = true
//            if !self.engine.running {
//                try self.engine.start()
//            }
//            if track.source == .Spotify {
//                self.spotifyProvider.startProvidingAudio(track)
//            } else {
//                self.libraryProvider.startProvidingAudio(track)
//            }
            
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
    func provider(provider:AudioProvider?, var format:AudioStreamBasicDescription)
}

protocol AudioProvider: class, Identifiable {
    weak var delegate:AudioProviderDelegate? { get set }
    func startProvidingAudio(track:Playable)
    var ready:Bool { get }
    var outputFormat:AudioStreamBasicDescription? { get set }
    func readFrames(var frames:UInt32, bufferList:UnsafeMutablePointer<AudioBufferList>, bufferSize:UnsafeMutablePointer<UInt32>)
}

class LibraryAudioProvider: AudioProvider {
    
    var outputFormat:AudioStreamBasicDescription?
    
    var ready = false
    
    func readFrames(frames:UInt32, bufferList:UnsafeMutablePointer<AudioBufferList>, bufferSize:UnsafeMutablePointer<UInt32>) {
        
        checkError(ExtAudioFileSeek(self.audioFile, self.frameIndex), "seek audio file")
        var readFrames:UInt32 = frames
        checkError(ExtAudioFileRead(self.audioFile, &readFrames, bufferList), "read audio file")
        self.frameIndex += Int64(readFrames)
        bufferSize.memory = bufferList.memory.mBuffers.mDataByteSize / UInt32(sizeof(Float32))
    
    }
    
    var buffer = CircularBuffer()
    
    var delegate:AudioProviderDelegate?
    
    var identifier:String {
        return "Library"
    }
    
    var audioFile:ExtAudioFileRef = ExtAudioFileRef()
    var clientFormat = AudioStreamBasicDescription()
    var frameIndex:Int64 = 0
    func startProvidingAudio(track: Playable) {
        checkError(ExtAudioFileOpenURL(track.assetURL, &audioFile), "open url")
        
        var totalFrames:Int64 = 0
        var dataSize:UInt32 = UInt32(sizeof(Int64))
        checkError(ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileLengthFrames, &dataSize, &totalFrames), "get file frames")
        
        var asbd = AudioStreamBasicDescription()
        dataSize = UInt32(sizeof(AudioStreamBasicDescription))
        
        checkError(ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileDataFormat, &dataSize, &asbd), "get file data format")
        
        if let delegate = self.delegate {
            delegate.provider(self, format: clientFormat)
        }
        if let format = self.outputFormat {
            var format = format
            checkError(ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, UInt32(sizeof(AudioStreamBasicDescription)), &format), "set file client format")
        }
//        self.clientFormat = clientFormat
        
        self.frameIndex = 0
        self.ready = true
    }
    
}

class SpotifyAudioProvider: AudioProvider {
    var outputFormat:AudioStreamBasicDescription? {
        get {
            return self.audioController.outputFormat
        }
        set {
            self.audioController.outputFormat = newValue
        }
    }

    var ready = false
    func readFrames(frames:UInt32, bufferList:UnsafeMutablePointer<AudioBufferList>, bufferSize:UnsafeMutablePointer<UInt32>) {
        if let output = self.outputFormat {
            let outSample = bufferList.memory.mBuffers.mData
            memset(outSample, 0, Int(frames * output.mBytesPerFrame * 2));
            let copiedSize = self.buffer.copy(Int32(frames)*Int32(output.mBytesPerFrame) * 2, intoBuffer: outSample)
            bufferList.memory.mBuffers.mDataByteSize = UInt32(copiedSize)
        }
    }
    var buffer:CircularBuffer {
        return self.audioController.buffer
    }

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
                    self.ready = true
                })
            })
        } else {
            self.streamController.playURIs([track.assetURL], withOptions: nil, callback: { (error) -> Void in
                self.ready = true
            })
        }
    }
    
    class SpotifyCoreAudioController : SPTCoreAudioController {
        var buffer = CircularBuffer()
        var outputFormat:AudioStreamBasicDescription?

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
        
        var audioConverter:AudioConverterRef?
        var inFormat:AVAudioFormat?
        var converter:AEFloatConverter?
        
        var genericUnit:AudioUnit = AudioUnit()
        var genericNode:AUNode = AUNode()
        var genericDescription: AudioComponentDescription  =  AudioComponentDescription(componentType: OSType(kAudioUnitType_Output),componentSubType: OSType(kAudioUnitSubType_GenericOutput),componentManufacturer: OSType(kAudioUnitManufacturer_Apple),componentFlags: 0,componentFlagsMask: 0)


        /*
        override func connectOutputBus(sourceOutputBusNumber: UInt32, ofNode sourceNode: AUNode, toInputBus destinationInputBusNumber: UInt32, ofNode destinationNode: AUNode, inGraph graph: AUGraph) throws {
/*
            if self.genericNode == 0 {
                var status = AUGraphAddNode(graph, &genericDescription, &genericNode)
                print("add: \(status)")
                var outDesc:AudioComponentDescription = AudioComponentDescription()
                AUGraphNodeInfo(graph, genericNode, &outDesc, &genericUnit)
                
                var inputUnit:AudioUnit = AudioUnit()
                AUGraphNodeInfo(graph, sourceNode, &outDesc, &inputUnit)
                
                let val:UInt32 = 4096
                var maxFramesSlice:UInt32 = val
                AudioUnitSetProperty (
                    genericUnit,
                    kAudioUnitProperty_MaximumFramesPerSlice,
                    kAudioUnitScope_Global,
                    0,
                    &maxFramesSlice,
                    UInt32(sizeof (UInt32))
                )
                
                var inputDescription:AudioStreamBasicDescription = AudioStreamBasicDescription()
                var size:UInt32 = UInt32(sizeof(AudioStreamBasicDescription))
                AudioUnitGetProperty(inputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &inputDescription, &size)
                size = UInt32(sizeof(AudioStreamBasicDescription))
//                var descPointer = UnsafePointer<AudioStreamBasicDescription>(&inputDescription)
                AudioUnitSetProperty(genericUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &inputDescription, size)
                AudioUnitSetProperty(genericUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, inFormatDescription!.streamDescription, size)
                AUGraphConnectNodeInput(graph, sourceNode, sourceOutputBusNumber, genericNode, 0)
                AUGraphConnectNodeInput(graph, genericNode, 0, destinationNode, destinationInputBusNumber)

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
                
                var contextInfo = RenderContextInfo(delegate: self.providerDelegate!, outputUnit: genericUnit, formatDescription:inFormatDescription!)
                AudioOutputUnitStart(genericUnit)
                AudioUnitAddRenderNotify(genericUnit, callback.inputProc, &contextInfo)
            }
            */
            do { try super.connectOutputBus(sourceOutputBusNumber, ofNode: sourceNode, toInputBus: destinationInputBusNumber, ofNode: destinationNode, inGraph: graph) } catch { print("error") }

            
        }
        */
        
        override func attemptToDeliverAudioFrames(audioFrames: UnsafePointer<Void>, ofCount frameCount: Int, streamDescription audioDescription: AudioStreamBasicDescription) -> Int {
            if let format = self.outputFormat {
                if self.audioConverter == nil {
                    var ref:AudioConverterRef = AudioConverterRef()
                    var outFormat = format
                    var inFormat = audioDescription
                    checkError(AudioConverterNew(&inFormat, &outFormat, &ref), "Create audio converter")
                    self.audioConverter = ref
                }
                var outSize:UInt32 = 0
                var outBuff:Void = Void()
                
                var inAudioBufferList:AudioBufferList = AudioBufferList()
                AEInitAudioBufferList(&inAudioBufferList, Int32(sizeof(AudioBufferList)), audioDescription, UnsafeMutablePointer<Void>(audioFrames), Int32(audioDescription.mBytesPerFrame) * Int32(frameCount) * 2)
                let outBufferList = AEAllocateAndInitAudioBufferList(format, Int32(frameCount))
                
                checkError(AudioConverterConvertComplexBuffer(self.audioConverter!, UInt32(frameCount), &inAudioBufferList, outBufferList), "converting audio")
                
//                checkError(AudioConverterConvertBuffer(self.audioConverter!, UInt32(frameCount) * UInt32(audioDescription.mBytesPerFrame) * 2, audioFrames, &outSize, &outBuff), "converting audio")
                self.buffer.add(outBufferList.memory.mBuffers.mData, length: Int32(outBufferList.memory.mBuffers.mDataByteSize))
            }
            return frameCount
        }
        
        /*self.inFormat = AVAudioFormat(streamDescription: &audioDescription)
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

struct ProviderPointer {
    var provider:AudioProvider
}

class CoreAudioPlayer:AudioProviderDelegate {
    
    var playing:Bool = false {
        didSet {
            var isPlaying:Boolean = 0
            checkError(AUGraphIsRunning(self.graph, &isPlaying), "check if graph is running")
            if self.playing && isPlaying == 0 {
                print("opening graph")
                checkError(AUGraphOpen(self.graph), "open graph")
            } else if !self.playing && isPlaying != 0 {
                AUGraphStop(self.graph)
            }
        }
    }
    
    var currentTrack:TrackItem? {
        didSet {
            if let track = self.currentTrack {
                if let providerIndex = self.providers.index(track.source) {
                    let provider = self.providers[providerIndex]
                    provider.startProvidingAudio(track as Playable)
                }
            }
        }
    }
    
    var providers:[AudioProvider] = [LibraryAudioProvider(), SpotifyAudioProvider()]
    
    var graph:AUGraph
    var ioUnit:AudioUnit
    var ioNode:AUNode
    var mixerUnit:AudioUnit
    var mixerNode:AUNode

    func callbackFunc(inRefCon:UnsafeMutablePointer<Void>, renderFlags:UnsafeMutablePointer<AudioUnitRenderActionFlags>, timeStamp:UnsafePointer<AudioTimeStamp>, outputBus:UInt32, numFrames:UInt32, bufferList:UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        
        
        return 0
    }
    
    var callback:AURenderCallback = { (inRefCon, renderFlags, timeStamp, outputBus, numFrames, bufferList) -> OSStatus in
        
        
        var pointer = UnsafeMutablePointer<ProviderPointer>(inRefCon)
        let provider = pointer.memory.provider
        guard provider.ready else { return 0 }
        var bufSize:UInt32 = 0
        provider.readFrames(numFrames, bufferList: bufferList, bufferSize: &bufSize)
        
        return 0
    }
    
    init() {
        self.graph = AUGraph()
        self.ioUnit = AudioUnit()
        self.ioNode = AUNode()
        self.mixerUnit = AudioUnit()
        self.mixerNode = AUNode()
        
        var status:OSStatus = 0
        status = NewAUGraph(&graph)
        
        // node creation
        //io node
        var ioUnitDescription:AudioComponentDescription = AudioComponentDescription(componentType: OSType(kAudioUnitType_Output),componentSubType: OSType(kAudioUnitSubType_RemoteIO),componentManufacturer: OSType(kAudioUnitManufacturer_Apple),componentFlags: 0,componentFlagsMask: 0)
        let defaultOutput = AudioComponentFindNext(nil, &ioUnitDescription)
        AudioComponentInstanceNew(defaultOutput, &ioUnit)
        status = AUGraphAddNode(self.graph, &ioUnitDescription, &ioNode)
        checkError(status, "add ioNode")
        
        //mixer node
        var mixerUnitDescription:AudioComponentDescription = AudioComponentDescription(componentType: OSType(kAudioUnitType_Mixer),componentSubType: OSType(kAudioUnitSubType_MultiChannelMixer),componentManufacturer: OSType(kAudioUnitManufacturer_Apple),componentFlags: 0,componentFlagsMask: 0)
        status = AUGraphAddNode(self.graph, &mixerUnitDescription, &mixerNode)
        checkError(status, "add mixer node")
        
        //open the graph
        status = AUGraphOpen(self.graph)
        checkError(status, "open graph")
        
        //grab the audio units
        status = AUGraphNodeInfo(self.graph, self.ioNode, nil, &ioUnit)
        checkError(status, "get ioUnit")
        status = AUGraphNodeInfo(self.graph, self.mixerNode, nil, &mixerUnit)
        checkError(status, "get mixerUnit")

        // connect mixer to IO
        status = AUGraphConnectNodeInput(self.graph, self.mixerNode, 0, self.ioNode, 0)
        checkError(status, "connect mixer out to node in")

        // set max frames / slice
        let val:UInt32 = 4096
        var maxFramesSlice:UInt32 = val
        AudioUnitSetProperty (
            self.ioUnit,
            kAudioUnitProperty_MaximumFramesPerSlice,
            kAudioUnitScope_Global,
            0,
            &maxFramesSlice,
            UInt32(sizeof (UInt32))
        )
        AudioUnitSetProperty (
            self.mixerUnit,
            kAudioUnitProperty_MaximumFramesPerSlice,
            kAudioUnitScope_Global,
            0,
            &maxFramesSlice,
            UInt32(sizeof (UInt32))
        )
        
        // set mixer output to io input
        var mixerOutput = AudioStreamBasicDescription()
        var valSize:UInt32 = UInt32(sizeof(AudioStreamBasicDescription))
//        checkError(AudioUnitSetProperty(self.mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &clientFormat, valSize), "set mixer input format")

        checkError(AudioUnitGetProperty(self.mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mixerOutput, &valSize), "get mixer output format")
        status = AudioUnitSetProperty(self.ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &mixerOutput, valSize)
        checkError(status, "set ioUnit input format")
        
        
        var x:UInt32 = 0
        for provider in self.providers {
            let provider = provider
            provider.delegate = self
            provider.outputFormat = mixerOutput
            let providerPointer = ProviderPointer(provider: provider)
            let pointer = UnsafeMutablePointer<ProviderPointer>.alloc(0)
            pointer.initialize(providerPointer)
            var callbackStruct:AURenderCallbackStruct = AURenderCallbackStruct(inputProc: callback, inputProcRefCon:pointer)
            status = AudioUnitSetProperty(self.mixerUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, AudioUnitElement(x), &callbackStruct, UInt32(sizeof(AURenderCallbackStruct)))
            checkError(status, "add node input callback: \(provider.identifier)")
            x += 1
        }
        
        checkError(AUGraphInitialize(self.graph), "initialize graph")
        status = AudioUnitInitialize(self.ioUnit)
        checkError(status, "init ioUnit")
        status = AudioUnitInitialize(self.mixerUnit)
        checkError(status, "init mixerUnit")

        status = AudioOutputUnitStart(self.ioUnit)
        checkError(status, "start ioUnit")

    }
    
    func provider(provider:AudioProvider?, var format:AudioStreamBasicDescription) {
        if let provider = provider {
            if let index = self.providers.index(provider) {
//                checkError(AudioUnitSetProperty(self.mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, AudioUnitElement(index), &format, UInt32(sizeof(AudioStreamBasicDescription))), "set mixer input format")
            }
        }
    }
    
}

