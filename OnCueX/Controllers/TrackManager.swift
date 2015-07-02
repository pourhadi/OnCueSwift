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

    func trackSelected(track:TrackItem) {
        func queueTrack() {
            _queue.insert(track as! Queueable, complete: nil)
        }
        
        _queue.queuedItemForQueueable(track as! Queueable, create: false) { (item) -> Void in
            if let index = item?.queueIndex {
                if index.playhead == index.index {
                    _player.play(track.assetURL)
                } else { queueTrack() }
            } else { queueTrack() }
        }
    }
    
}
