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
    var isContainer:Bool { get }
    func getTracks(complete:(tracks:[TrackItem])->Void)
}

extension Queueable {
    func equals(other:Queueable) -> Bool {
        return self.identifier == other.identifier
    }
}

protocol QueuedItemObserver: class {
    func queueIndexUpdated(forItem:Queued, queueIndex:QueueIndex?)
}

protocol Queued: class, Identifiable {
    var queueIndex:QueueIndex? { get set }
    var displayInfo:DisplayContext { get }
    var numberOfItems:Int { get }
    weak var observer:QueuedItemObserver? { get set }
    var tracks:[QueuedTrack] { get }
    
}

class QueuedTrack:Queued {
    let track:TrackItem
    var tracks:[QueuedTrack] {
        return [self]
    }
    
    var queueIndex:QueueIndex? {
        didSet {
            if let observer = self.observer {
                observer.queueIndexUpdated(self, queueIndex: self.queueIndex)
            }
        }
    }
    
    var displayInfo:DisplayContext {
        return self.track
    }
    weak var observer:QueuedItemObserver?
    var identifier:String { return self.track.identifier }
    init(track:TrackItem) {
        self.track = track
    }
    
    var numberOfItems:Int { return 1 }
}

class QueuedItem:Equatable, Queued  {
    
    class func newQueuedItem(fromQueueable:Queueable, complete:(item:QueuedItem)->Void) {
        fromQueueable.getTracks { (tracks) -> Void in
            complete(item: QueuedItem(queueable: fromQueueable, tracks: tracks))
        }
    }
    
    weak var observer:QueuedItemObserver?
    var queueIndex:QueueIndex? {
        didSet {
            if let observer = self.observer {
                observer.queueIndexUpdated(self, queueIndex: self.queueIndex)
            }
        }
    }
    var tracks:[QueuedTrack]
    
    
    var numberOfItems:Int {
        return self.tracks.count
    }
    
    var identifier:String {
        return self.queueable.identifier
    }
    
    private let queueable:Queueable
    
    var displayInfo:DisplayContext { return self.queueable }
    var isContainer:Bool { return self.queueable.isContainer }
    
    init(queueable:Queueable, tracks:[TrackItem]) {
        self.queueable = queueable;
        self.tracks = tracks.map({ (track) -> QueuedTrack in
            return QueuedTrack(track: track)
        })
    }
}

func == (lh:QueuedItem, rh:QueuedItem) -> Bool {
    return lh.identifier == rh.identifier
}

extension QueuedItem:DisplayContext, Identifiable, ImageSource {
    var title:String? {
        return self.queueable.title
    }
    var subtitle:String? {
        return self.queueable.subtitle
    }
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {
        self.queueable.getImage(forSize, complete: complete)
    }
}