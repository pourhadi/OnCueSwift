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
        if let index = _queue.indexOfItem(track) {
            if index.playhead == index.index || index.playhead == index.index - 1 {
                TrackManager.play(track)
            } else { TrackManager.queueTrack(track) }
        } else { TrackManager.queueTrack(track) }
    }
    
    class func queueTrack(track:TrackItem) {
        _queue.insert(track, complete: nil)
    }
    
    class func next(play:Bool) {
        _queue.next()
        if let track = _queue.currentTrack {
            if play {
                self.play(track.track)
            }
        }
    }
    
    class func play(track:TrackItem) {
        if let queueIndex = _queue.indexOfItem(track) {
            if queueIndex.playhead != queueIndex.index {
                _queue.playhead = queueIndex.index
            }
            _player.play(track)
        } else {
            _queue.insert(track, atIndex: _queue.playhead, complete: { (insertedIndex) -> Void in
                _player.play(track)
            })
        }
        
    }
}
