//
//  CAHelper.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 7/8/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import CoreAudio
extension AudioStreamBasicDescription {
    func isPCM() -> Bool {
        return self.mFormatID == kAudioFormatLinearPCM
    }
    
    func isInterleaved() -> Bool {
        return !self.isPCM() || ((self.mFormatFlags & kAudioFormatFlagIsNonInterleaved) != 1)
    }
    
    func numberOfInterleavedChannels() -> UInt32 {
        return self.isInterleaved() ? self.mChannelsPerFrame : 1
    }
    
    func numberOfChannelStreams() -> UInt32 {
        return self.isInterleaved() ? 1 : self.mChannelsPerFrame
    }
}