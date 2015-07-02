//
//  Audio.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/30/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import AVFoundation

protocol Playable:Identifiable {
    var assetURL:NSURL { get }
}

protocol AudioReceiver {
    func newBufferReady(provider:AudioProvider, buffer:AVAudioPCMBuffer)
}

protocol AudioProvider {
    
}