//
//  TrackManager.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 7/1/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

let _trackManager = TrackManager()
class TrackManager {

    class func trackSelected(track:TrackItem) {
        _trackManager.trackSelected(track)
    }
    
    func trackSelected(track:TrackItem) {
        func queueTrack() {
            _queue.insert(track as! Queueable, complete: nil)
        }
        
        _queue.queuedItemForQueueable(track as! Queueable, create: false) { (item) -> Void in
            if let index = item?.queueIndex {
                if index.playhead == index.index || index.playhead == index.index - 1 {
                    _player.play(track)
                } else { queueTrack() }
            } else { queueTrack() }
        }
    }
    
    class func next(play:Bool) {
        _queue.next()
        if let track = _queue.currentTrack {
            if play {
                _player.play(track.track)
            }
        }
    }
    
}
