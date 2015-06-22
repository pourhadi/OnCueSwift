//
//  Queable.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/21/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

protocol Queueable: class, DisplayContext, QueueObserver {
    var identifier:String { get }
    var queueIndex:QueueIndex? { get set }
    var childItems:[Queueable]? { get }
}

protocol QueueObserver {
    var identifier:String { get }
    func queueUpdated(queue:Queue)
}

extension Queueable {
    func equals(other:Queueable) -> Bool {
        return self.identifier == other.identifier
    }
}