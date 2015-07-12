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
    var duration:NSTimeInterval { get }
}

struct NowPlayingInfo {
    let track:TrackItem
    let currentTime:NSTimeInterval
}

protocol NowPlayingObserver:class, Identifiable {
    func nowPlayingUpdated(nowPlayingInfo:NowPlayingInfo)
}