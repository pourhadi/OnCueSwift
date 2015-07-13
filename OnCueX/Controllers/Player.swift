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
import ReactiveCocoa
let _player = Player()

func checkError(error:OSStatus, _ operation:String?) {
//    print("status:\(error) for: \(operation)")
    guard error != noErr else { return }
    
    print("error: \(error) \(operation)")
}

struct NowPlayingObserverWrapper:Identifiable {
    weak var observer:NowPlayingObserver?
    
    var identifier:String {
        if let observer = self.observer {
            return observer.identifier
        }
        return ""
    }
}

class Player:CoreAudioPlayerDelegate {
    
    func playerTrackFinished(player:CoreAudioPlayer) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            TrackManager.next(true)
        }
    }
    
    var observers:[NowPlayingObserverWrapper] = []
    func addObserver(observer:NowPlayingObserver) {
        self.observers.append(NowPlayingObserverWrapper(observer: observer))
        
        if self.observers.count == 1 {
            self.startObserverTimer()
        }
    }
    
    func removeObserver(observer:NowPlayingObserver) {
        if let index = self.observers.index(observer) {
            self.observers.removeAtIndex(index)
        }
        
        if self.observers.count == 0 {
            self.stopObserverTimer()
        }
    }
    
    var timer:NSTimer?
    func startObserverTimer() {
        self.stopObserverTimer()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: "observerTimerFired", userInfo: nil, repeats: true)
        self.timer!.tolerance = 0.1 * 0.25
    }
    
    func stopObserverTimer() {
        if let timer = self.timer {
            timer.invalidate()
        }
    }
    
    func observerTimerFired() {
        let newArray = self.observers
        for (index, observer) in newArray.enumerate() {
            if observer.observer == nil {
                self.observers.removeAtIndex(index)
            }
        }
        
        if self.observers.count == 0 {
            self.stopObserverTimer()
            return
        }
        
        if let track = self.audioPlayer.currentTrack {
            let info = NowPlayingInfo(track:track, currentTime:self.audioPlayer.currentTrackTime)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                for observerWrapper in self.observers {
                    if let observer = observerWrapper.observer {
                        observer.nowPlayingUpdated(info)
                    }
                }
            })
        }
    }

    init() {
        self.configure()
        self.startSession()
    }

    func configure() {
       
    }
    
    lazy var audioPlayer:CoreAudioPlayer = {
        let player = CoreAudioPlayer()
        player.delegate = self
        return player
        }()
//    let enginePlayer = EnginePlayer()

    func play(track:TrackItem) {
        audioPlayer.currentTrack = track
        audioPlayer.playing = true
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
}

protocol AudioProviderDelegate:class {
    func provider(provider:AudioProvider, format:AudioStreamBasicDescription)
    func providerTrackFinished(provider:AudioProvider)
}

protocol AudioProviderEngineDelegate:class {
    func provider(provider:AudioProvider, hasNewBuffer:AVAudioPCMBuffer)
}

protocol AudioProvider: class, Identifiable {
    var delegate:AudioProviderDelegate? { get set }
    
    var engineDelegate:AudioProviderEngineDelegate? { get set }
//    func startProvidingAudio(track:Playable) -> SignalProducer<AVAudioFormat, NoError>
    func startProvidingAudio(track:Playable)
    func seekToTime(time:NSTimeInterval)
    
    var buffering:Bool { get }
    var error:NSError? { get }
    
    func reset()
    
    func renderFrames(frameCount:UInt32, intoBuffer:UnsafeMutablePointer<AudioBufferList>) -> UInt32
    var outputFormat:AudioStreamBasicDescription? { get set }
    var ready:Bool { get }
    
    var optionalConverters:(AudioUnit, AUNode)? { get set }
    var requiresConverter:Bool { get set }
    var callbackStruct:AURenderCallbackStruct? { get set }
    var busElement:Int32 { get set }
}

class LibraryAudioProvider: AudioProvider {
    var totalFramesForCurrentTrack = 0
    var busElement:Int32 = 0
    var callbackStruct:AURenderCallbackStruct?
    var requiresConverter:Bool = false
    var optionalConverters:(AudioUnit, AUNode)?

    var ready = false
    
    var outputFormat:AudioStreamBasicDescription?
    
    func renderFrames(frameCount:UInt32, intoBuffer:UnsafeMutablePointer<AudioBufferList>) -> UInt32 {
        if self.ready {
            checkError(ExtAudioFileSeek(extFile, self.currentFrame), "seek audio file")
            var frames = frameCount
            checkError(ExtAudioFileRead(extFile, &frames, intoBuffer), "reading audio file")
            self.currentFrame += Int64(frames)
            return frames
        }
        return 0
    }
    
    var delegate:AudioProviderDelegate?
    func reset() {
        self.ready = false
        self.error = nil
        self.buffering = false
        self.file = nil
        self.currentFrame = 0
        ExtAudioFileDispose(self.extFile)
        self.extFile = ExtAudioFileRef()
    }
    
    var error:NSError?
    var buffering = false

    var buffer = CircularBuffer()
    
    var engineDelegate:AudioProviderEngineDelegate?
    
    var identifier:String {
        return "Library"
    }
    
    func seekToTime(time:NSTimeInterval) {
        if let file = self.file {
            self.buffering = true
            let totalFrames = file.length
            let sampleRate = file.processingFormat.sampleRate
            let dur:NSTimeInterval = NSTimeInterval(totalFrames) / NSTimeInterval(sampleRate)
            let percent = time / dur
            let framePosition = AVAudioFramePosition(NSTimeInterval(totalFrames) * percent)
            let framesDuration = totalFrames - framePosition
            let buffer = AVAudioPCMBuffer(PCMFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(framesDuration))
            file.framePosition = framePosition
            do { try file.readIntoBuffer(buffer, frameCount: AVAudioFrameCount(framesDuration)) } catch { "error seeking" }
            if let delegate = self.engineDelegate {
                delegate.provider(self, hasNewBuffer:buffer)
                self.buffering = false
            }
        }
    }
    
    func startProvidingAudio(track:Playable) {
        checkError(ExtAudioFileOpenURL(track.assetURL, &extFile), "open file URL")
        var totalFrames:Int64 = 0
        var dataSize:UInt32 = UInt32(sizeofValue(totalFrames))
        checkError(ExtAudioFileGetProperty(extFile, kExtAudioFileProperty_FileLengthFrames, &dataSize, &totalFrames), "get total frames")
        checkError(ExtAudioFileSetProperty(extFile, kExtAudioFileProperty_ClientDataFormat, UInt32(sizeofValue(outputFormat)), &outputFormat), "ExtAudioFileSetProperty ClientDataFormat failed")
        self.currentFrame = 0
        self.ready = true
        self.buffering = true
    }
    
    var extFile:ExtAudioFileRef = ExtAudioFileRef()
    var currentFrame:Int64 = 0
    
    var file:AVAudioFile?
    func startProvidingAudio(track: Playable) -> SignalProducer<AVAudioFormat, NoError> {
        self.reset()
        return SignalProducer { [unowned self] sink, disposable in
            do {
                self.file = try AVAudioFile(forReading: track.assetURL)
                if let file = self.file {
                    sendNext(sink, file.processingFormat)
                    sendCompleted(sink)
                    self.buffering = true
                    let buffer = AVAudioPCMBuffer(PCMFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
                    try file.readIntoBuffer(buffer)
                    if let delegate = self.engineDelegate {
                        delegate.provider(self, hasNewBuffer:buffer)
                        self.buffering = false
                    }
                }
                
            } catch {
                print("error")
            }
        }
    }
}

@objc
class SpotifyAudioProvider: NSObject, AudioProvider, SPTAudioStreamingPlaybackDelegate {
    var totalFramesForCurrentTrack = 0

    var busElement:Int32 = 0
    var callbackStruct:AURenderCallbackStruct?
    var requiresConverter = false
    var optionalConverters:(AudioUnit, AUNode)?

    var ready = false
    
    var outputFormat:AudioStreamBasicDescription? {
        get {
            return self.audioController.outputFormat
        }
        set {
            self.audioController.outputFormat = newValue
        }
    }
    
    func renderFrames(frameCount:UInt32, intoBuffer:UnsafeMutablePointer<AudioBufferList>) -> UInt32 {
        if self.ready {
            return self.buffer.getFrames(frameCount, format: self.outputFormat!, buffer: intoBuffer)
        }
        return 0
    }
    
    var delegate:AudioProviderDelegate? {
        get {
            return self.audioController.providerDelegate
        }
        set {
            self.audioController.providerDelegate = newValue
        }
    }
    func reset() {
        self.streamController.stop(nil)
        self.ready = false
        self.error = nil
        self.buffering = false
        self.buffer.reset()
        if let converter = self.audioController.audioConverter {
            AudioConverterReset(converter)
        }
    }
    
    var error:NSError?
    var buffering = false
    
    override init() {
        super.init()
        self.audioController.provider = self
    }
    
    var buffer:CircularBuffer {
        return self.audioController.buffer
    }

    var identifier:String {
        return "Spotify"
    }
    
    func seekToTime(time: NSTimeInterval) {
        self.buffering = true
        self.buffer.reset()
        self.streamController.seekToOffset(time) { (error) -> Void in
            print("error seeking spotify")
        }
    }
    
    func startProvidingAudio(track:Playable) {
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
    
    func startProvidingAudio(track: Playable) -> SignalProducer<AVAudioFormat, NoError> {
        self.buffering = true
        return SignalProducer { sink, disposable in
            if !self.streamController.loggedIn {
                self.streamController.loginWithSession(_spotifyController.session!, callback: { (error) -> Void in
                    self.streamController.playURIs([track.assetURL], withOptions: nil, callback: { (error) -> Void in
                    })
                })
            } else {
                self.streamController.playURIs([track.assetURL], withOptions: nil, callback: { (error) -> Void in
                })
            }
            
            self.audioController.spotifyFormat.producer
            |> start(next: { (val) -> () in
                if let format = val {
                    sendNext(sink, format)
                    sendCompleted(sink)
                }
            })
        }
    }
    var engineDelegate:AudioProviderEngineDelegate? {
        get {
            return self.audioController.engineDelegate
        }
        set {
            self.audioController.engineDelegate = newValue
        }
    }
    

    class SpotifyCoreAudioController : SPTCoreAudioController {
        var outputFormat:AudioStreamBasicDescription?
        var providerDelegate:AudioProviderDelegate?
        var engineDelegate:AudioProviderEngineDelegate?
        var buffer = CircularBuffer()
        var spotifyFormat:MutableProperty<AVAudioFormat?> = MutableProperty(nil)
        weak var provider:SpotifyAudioProvider?
        var aeConverter:AEFloatConverter?

        var audioConverter:AudioConverterRef?
        override func attemptToDeliverAudioFrames(audioFrames: UnsafePointer<Void>, ofCount frameCount: Int, streamDescription audioDescription: AudioStreamBasicDescription) -> Int {
            let audioDescription = audioDescription
            
//            if self.audioConverter == nil {
//                var exportFormat = self.outputFormat!
//                var ref:AudioConverterRef = AudioConverterRef()
//                var inFormat = audioDescription
//                checkError(AudioConverterNew(&inFormat, &exportFormat, &ref), "Create audio converter")
//                self.audioConverter = ref
//            }
//            
//            if self.aeConverter == nil {
//                self.aeConverter = AEFloatConverter(sourceFormat: audioDescription)
//            }
            
            if self.spotifyFormat.value == nil {
                let outFormat = AVAudioFormat(streamDescription: &outputFormat!)
                self.spotifyFormat.put(outFormat)
                
                if let delegate = self.providerDelegate {
                    delegate.provider(self.provider!, format: audioDescription)
                }
            }
            
            var abl = AudioBufferList(mNumberBuffers: 1, mBuffers: AudioBuffer(mNumberChannels: 2, mDataByteSize: UInt32(frameCount)*2*UInt32(sizeof(Int16)), mData: UnsafeMutablePointer<Void>(audioFrames)))
            if (!self.buffer.add(&abl, frames: UInt32(frameCount), description: audioDescription)) {
                return 0
            }
            self.provider!.ready = true

            return frameCount
/*
            let floatBuffer = AVAudioPCMBuffer(PCMFormat: self.spotifyFormat.value!, frameCapacity: AVAudioFrameCount(frameCount))
            checkError(AudioConverterConvertComplexBuffer(self.audioConverter!, UInt32(frameCount), &abl, floatBuffer.mutableAudioBufferList), "error converting")
            floatBuffer.frameLength = AVAudioFrameCount(frameCount)
            if (!self.buffer.add(floatBuffer.mutableAudioBufferList, frames: UInt32(frameCount), description: floatBuffer.format.streamDescription.memory)) {
                return 0
            }

            return frameCount*/
        }
    }
    
    let audioController = SpotifyCoreAudioController()
    lazy var streamController:SPTAudioStreamingController = {
        let x:SPTAudioStreamingController = SPTAudioStreamingController(clientId: _spotifyController.clientID, audioController: self.audioController)
        x.setTargetBitrate(.High, callback: nil)
        return x
    }()
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if !isPlaying {
            self.buffering = false
        }
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didFailToPlayTrack trackUri: NSURL!) {
        self.buffering = false
        self.error = NSError(domain: "com.OnCue.Spotify.PlaybackError", code: 0, userInfo: nil)
    }
    
    
}


/*
class EnginePlayer:AudioProviderEngineDelegate {
    
    var currentProvider:AudioProvider? {
        return self.providerForCurrentTrack()
    }
    
    func play() {
        if !self.engine.running {
            do { try self.engine.start() } catch { "error starting engine" }
        }
        self.playerNode.play()
    }
    
    func pause() {
        self.playerNode.pause()
    }
    
    func stop() {
        self.playerNode.stop()
        self.bufferQueue = 0
    }

    var bufferQueue:Int = 0 {
        didSet {
            if bufferQueue == 0 && self.playerNode.playing {
                if let provider = self.currentProvider {
                    if !provider.buffering {
                        // end of song
                    }
                }
            }
        }
    }
    func provider(provider:AudioProvider, hasNewBuffer:AVAudioPCMBuffer) {
        self.bufferQueue += 1
        self.playerNode.scheduleBuffer(hasNewBuffer, completionHandler:{
            self.bufferQueue -= 1
        })
    }

    let engine = AVAudioEngine()
    var mixerNode:AVAudioMixerNode {
        return self.engine.mainMixerNode
    }
    
    let playerNode = AVAudioPlayerNode()
    var currentTrack:TrackItem? {
        didSet {
            if let track = self.currentTrack {
                if let providerIndex = self.providers.index(track.source) {
                    let provider = self.providers[providerIndex]
                    provider.startProvidingAudio(track)
                    |> start(next: { (format) -> () in
                        self.engine.connect(self.playerNode, to: self.mixerNode, format: format)
                        self.engine.connect(self.mixerNode, to: self.engine.outputNode, format: format)
                    })
                }
            }

        }
    }
    
    func providerForCurrentTrack() -> AudioProvider? {
        if let track = self.currentTrack {
            if let providerIndex = self.providers.index(track.source) {
                let provider = self.providers[providerIndex]
                return provider
            }
        }
        return nil
    }
    
    var providers:[AudioProvider] = [LibraryAudioProvider(), SpotifyAudioProvider()]

    init() {
        self.engine.attachNode(self.playerNode)
        for provider in self.providers {
            provider.engineDelegate = self
        }
    }
}
*/

struct ProviderPointer {
    weak var provider:AudioProvider?
    weak var player:CoreAudioPlayer?
}

protocol CoreAudioPlayerDelegate:class {
    func playerTrackFinished(player:CoreAudioPlayer)
}

class CoreAudioPlayer:AudioProviderDelegate {
    weak var delegate:CoreAudioPlayerDelegate?
    
    func currentTrackFinished() {
        if let delegate = self.delegate {
            delegate.playerTrackFinished(self)
        }
    }
    
    func providerTrackFinished(provider:AudioProvider) {
        self.currentTrackFinished()
    }
    
    func provider(provider:AudioProvider, format:AudioStreamBasicDescription) {
        var format = format
        let avFormat = AVAudioFormat(streamDescription: &format)
        let outputFormat = AVAudioFormat(streamDescription: &self.outputFormat)
        
        if !avFormat.isEqual(outputFormat) {
            provider.requiresConverter = true
            var desc = AudioComponentDescription(componentType: OSType(kAudioUnitType_FormatConverter),componentSubType: OSType(kAudioUnitSubType_AUConverter),componentManufacturer: OSType(kAudioUnitManufacturer_Apple),componentFlags: 0,componentFlagsMask: 0)
            var node = AUNode()
            checkError(AUGraphAddNode(self.graph, &desc, &node), "add converter node")
            var unit = AudioUnit()
            checkError(AUGraphNodeInfo(self.graph, node, &desc, &unit), "get converter unit")
            
            AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, UInt32(sizeofValue(format)))
            AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &self.outputFormat, UInt32(sizeofValue(format)))
            var fps:UInt32 = 4096
            AudioUnitSetProperty(unit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &fps, UInt32(sizeofValue(fps)))
            var callback = provider.callbackStruct!
            AudioUnitSetProperty(unit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callback, UInt32(sizeofValue(callback)))
            AUGraphConnectNodeInput(self.graph, node, 0, self.mixerNode, UInt32(provider.busElement))
            var updated:Boolean = 0
            AudioUnitInitialize(unit)
            AUGraphUpdate(self.graph, &updated)
            provider.optionalConverters = (unit, node)
        }
    }
    
    func providerForCurrentTrack() -> AudioProvider? {
        if let track = self.currentTrack {
            if let providerIndex = self.providers.index(track.source) {
                let provider = self.providers[providerIndex]
                return provider
            }
        }
        return nil
    }
    
    var playing:Bool = false {
        didSet {
            var isPlaying:Boolean = 0
            checkError(AUGraphIsRunning(self.graph, &isPlaying), "check if graph is running")
            if self.playing && isPlaying == 0 {
                print("starting graph")
                checkError(AUGraphStart(self.graph), "start graph")
            } else if !self.playing && isPlaying != 0 {
                AUGraphStop(self.graph)
            }
        }
    }
    
    var currentTrack:TrackItem? {
        willSet {
            if let provider = self.providerForCurrentTrack() {
                provider.reset()
            }
            currentFrameCount = 0
        }
        
        didSet {
            if let track = self.currentTrack {
                if let providerIndex = self.providers.index(track.source) {
                    let provider = self.providers[providerIndex]
                    provider.startProvidingAudio(track as Playable)
                }
            }
        }
    }
    
    var currentFrameCount:Int = 0 {
        didSet {
            if self.currentTrack != nil {
                if (totalFramesForCurrentTrack - currentFrameCount) < 100 {
                    self.currentTrackFinished()
                }
            }
        }
    }
    
    var currentTrackTime:NSTimeInterval {
        if let track = currentTrack {
            return NSTimeInterval(currentFrameCount / totalFramesForCurrentTrack) * track.duration
        }
        return 0
    }
    
    var totalFramesForCurrentTrack:Int {
        if let track = currentTrack {
            let sampleRate = AVAudioSession.sharedInstance().sampleRate
            return Int(sampleRate) * Int(track.duration)
        }
        return 0
    }
    
    var providers:[AudioProvider] = [LibraryAudioProvider(), SpotifyAudioProvider()]
    
    var graph:AUGraph
    var ioUnit:AudioUnit
    var ioNode:AUNode
    var mixerUnit:AudioUnit
    var mixerNode:AUNode

    var outputFormat:AudioStreamBasicDescription
    
    var callback:AURenderCallback = { (inRefCon, renderFlags, timeStamp, outputBus, numFrames, bufferList) -> OSStatus in

        var pointer = UnsafeMutablePointer<ProviderPointer>(inRefCon)
        guard let provider:AudioProvider = pointer.memory.provider else { return 0 }
        guard provider.ready else { return 0 }
        guard let player:CoreAudioPlayer = pointer.memory.player else { return 0 }
        var bufSize:UInt32 = 0
        if provider.ready {
            let renderedFrames = provider.renderFrames(numFrames, intoBuffer: bufferList)
            player.currentFrameCount += Int(renderedFrames)
        } else {
//            kAudioUnitRenderAction_OutputIsSilence
            let abl = UnsafeMutableAudioBufferListPointer(bufferList)
            for buffer in abl {
                renderFlags.memory = AudioUnitRenderActionFlags.UnitRenderAction_OutputIsSilence
                memset(buffer.mData, 0, Int(buffer.mDataByteSize))
                var buffer = buffer
                buffer.mDataByteSize = 0
            }
        }
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
        
        var sampleRate = AVAudioSession.sharedInstance().sampleRate
        checkError(AudioUnitSetProperty(self.mixerUnit, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &sampleRate, UInt32(sizeofValue(sampleRate))), "set mixer sample rate")
        
        // set mixer output to io input
        var mixerOutput = AudioStreamBasicDescription()
        var valSize:UInt32 = UInt32(sizeof(AudioStreamBasicDescription))

        checkError(AudioUnitGetProperty(self.mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mixerOutput, &valSize), "get mixer output format")
        status = AudioUnitSetProperty(self.ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &mixerOutput, valSize)
        checkError(status, "set ioUnit input format")
        self.outputFormat = mixerOutput
        
        var x:UInt32 = 0
        for provider in self.providers {
            let provider = provider
            provider.delegate = self
            provider.outputFormat = mixerOutput
            let providerPointer = ProviderPointer(provider: provider, player:self)
            let pointer = UnsafeMutablePointer<ProviderPointer>.alloc(0)
            pointer.initialize(providerPointer)
            var callbackStruct:AURenderCallbackStruct = AURenderCallbackStruct(inputProc: callback, inputProcRefCon:pointer)
            provider.callbackStruct = callbackStruct
            status = AudioUnitSetProperty(self.mixerUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, AudioUnitElement(x), &callbackStruct, UInt32(sizeof(AURenderCallbackStruct)))
            checkError(status, "add node input callback: \(provider.identifier)")
            provider.busElement = Int32(x)
            x += 1
        }
        
        checkError(AUGraphInitialize(self.graph), "initialize graph")
        status = AudioUnitInitialize(self.ioUnit)
        checkError(status, "init ioUnit")
        status = AudioUnitInitialize(self.mixerUnit)
        checkError(status, "init mixerUnit")

    }
}

