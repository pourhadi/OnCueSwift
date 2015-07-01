//
//  Audio.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/30/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import AVFoundation

struct AudioBuffer {
    var ready:Bool = false
    let buffer:AVAudioPCMBuffer
    
    init(format:AVAudioFormat, frameCapacity:AVAudioFrameCount) {
        self.buffer = AVAudioPCMBuffer(PCMFormat: format, frameCapacity: frameCapacity)
    }
    
    mutating func appendData(data:UnsafeMutablePointer<Float>, length:Int) {
        
    }
}