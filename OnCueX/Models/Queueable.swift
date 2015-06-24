//
//  Queable.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/21/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

protocol Queueable: class, DisplayContext, QueueObserver, Identifiable {
    var queueIndex:QueueIndex? { get set }
    var childItems:[Queueable]? { get }
    
    var observer:QueueableItemObserver? { get set }
}

protocol QueueObserver : Identifiable {
    func queueUpdated(queue:Queue)
}

extension Queueable {
    func equals(other:Queueable) -> Bool {
        return self.identifier == other.identifier
    }
    
    var numberOfItems:Int {
        return self.childItems == nil ? 1 : self.childItems!.count
    }
}

protocol QueueableItemObserver: class {
    func queueIndexUpdated(forItem:Queueable, queueIndex:QueueIndex?)
}