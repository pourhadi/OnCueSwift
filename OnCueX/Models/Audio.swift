//
//  Audio.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/30/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import AVFoundation

protocol UpdateObserver:class, Identifiable {
}

protocol Playable:Identifiable {
    var assetURL:NSURL { get }
    var duration:NSTimeInterval { get }
}

struct NowPlayingInfo {
    let track:TrackItem
    let currentTime:NSTimeInterval
}


struct ObserverWrapper {
    weak var observer:UpdateObserver?
    
    var identifier:String {
        if let observer = self.observer {
            return observer.identifier
        }
        return ""
    }
}

protocol NowPlayingObserver:UpdateObserver {
    func nowPlayingUpdated(nowPlayingInfo:NowPlayingInfo)
}

protocol NowPlayingStateObserver:UpdateObserver {
    func playStateChanged(playing:Bool)
}