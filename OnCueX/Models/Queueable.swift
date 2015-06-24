//
//  Queable.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/21/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import ReactiveCocoa

protocol Queueable: DisplayContext, Identifiable {
    func getTracks(complete:(tracks:[TrackItem])->Void)
}

protocol QueueObserver : Identifiable {
    func queueUpdated(queue:Queue)
}

extension Queueable {
    func equals(other:Queueable) -> Bool {
        return self.identifier == other.identifier
    }
}

protocol QueuedItemObserver: class {
    func queueIndexUpdated(forItem:QueuedItem, queueIndex:QueueIndex?)
}

class QueuedItem:Equatable, Identifiable {
    
    class func newQueuedItem(fromQueueable:Queueable, complete:(item:QueuedItem)->Void) {
        fromQueueable.getTracks { (tracks) -> Void in
            complete(item: QueuedItem(queueable: fromQueueable, tracks: tracks))
        }
    }
    
    var queueIndex:QueueIndex?
    var tracks:[TrackItem]
    
    weak var observer:QueuedItemObserver?
    
    var numberOfItems:Int {
        return self.tracks.count
    }
    
    var identifier:String {
        return self.queueable.identifier
    }
    
    private var queueable:Queueable
    
    init(queueable:Queueable, tracks:[TrackItem]) {
        self.queueable = queueable;
        self.tracks = tracks
    }
}

func == (lh:QueuedItem, rh:QueuedItem) -> Bool {
    return lh.identifier == rh.identifier
}

extension QueuedItem:DisplayContext, ImageSource {
    var title:String? {
        return self.queueable.title
    }
    var subtitle:String? {
        return self.queueable.subtitle
    }
    func getImage(forSize: CGSize, complete: (image: UIImage?) -> Void) {
        self.queueable.getImage(forSize, complete: complete)
    }
}