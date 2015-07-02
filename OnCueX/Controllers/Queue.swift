//
//  Queue.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/21/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

let _queue:Queue = Queue()

protocol QueueObserver : class, Identifiable {
    func queueUpdated(queue:Queue)
}

struct QueueObserverWrapper:Identifiable {
    var identifier:String {
        if let observer = self.observer {
            return observer.identifier
        }
        return ""
    }
    weak var observer:QueueObserver?
    init(observer:QueueObserver) {
        self.observer = observer;
    }
}

struct QueueIndex: Equatable {
    let index:Int
    let playhead:Int
    
    var displayIndex:String {
        let diff:UInt = UInt(index) - UInt(playhead)
        if diff == 0 {
            return ""
        } else if diff == 1 {
            return "NEXT"
        }
        return "\(diff)"
    }

    init(index:Int, playhead:Int) {
        self.index = index
        self.playhead = playhead
    }
}
func ==(lhs: QueueIndex, rhs: QueueIndex) -> Bool {
    return (lhs.index == rhs.index && lhs.playhead == rhs.playhead)
}

struct QueueOperation {
    enum OperationType {
        case Added
        case Removed
        case PlayheadChanged
    }
    
    var item:QueuedItem?
    let type:OperationType
    var queueIndex:QueueIndex?
    
    init(item:QueuedItem?, type:OperationType, queueIndex:QueueIndex?) {
        self.item = item
        self.type = type
        self.queueIndex = queueIndex
    }
}

extension Queue {
    func next() {
        self.operation {
            self.playhead += 1
        }
    }
    
    func back() {
        self.operation {
            self.playhead -= 1
        }
    }
}

final class Queue {

    var observers:[QueueObserverWrapper] = []
    func addObserver(observer:QueueObserver) {
        self.observers.append(QueueObserverWrapper(observer: observer))
    }
    
    func removeObserver(observer:QueueObserver) {
        if let index = self.observers.index(observer) {
            self.observers.removeAtIndex(index)
        }
    }
    
    var playhead = 0 {
        didSet {
            self.operation {
                self.operations.append(QueueOperation(item: nil, type: .PlayheadChanged, queueIndex: nil))
            }
        }
    }
    
    var items:[QueuedItem] = []
    
    func remove(itemAtIndex:Int) {
        self.operation {
            let item = self.items[itemAtIndex]
            let numOfItems = item.numberOfItems
            self.items.removeAtIndex(itemAtIndex)
            self.operations.append(QueueOperation(item: item, type: .Removed, queueIndex: QueueIndex(index: itemAtIndex, playhead: self.playhead)))
            
            if numOfItems > 1 {
                for x in itemAtIndex..<(itemAtIndex+numOfItems) {
                    if x < self.playhead {
                        self.playhead -= 1
                    }
                }
            } else {
                if itemAtIndex < self.playhead {
                    self.playhead -= 1
                }
            }
        }
    }
    
    func queuedItemForQueueable(queueable:Queueable, create:Bool, complete:(item:QueuedItem?)->Void) {
        var found:QueuedItem? = nil
        for item in self.items {
            if item.isEqual(queueable) {
                found = item
                break
            }
        }
        
        if found == nil && create {
            QueuedItem.newQueuedItem(queueable, complete: { (item) -> Void in
                complete(item:item)
            })
        } else {
            complete(item:found)
        }
    }
    
    func removeIfInQueue(item:Identifiable) -> Int? {
        return self.operation {
            if let index = self.items.index(item) {
                self.remove(index)
                return index
            }
            return nil
        }
    }
    
    func insert(item:QueuedItem) -> QueueIndex {
        return self.insert(item, atIndex: item.queueIndex != nil ? item.queueIndex!.index != self.playhead ? 1 : item.queueIndex!.index : self.items.count)
    }
    
    func insert(item:Queueable, complete:((index:QueueIndex)->Void)?) {
        self.queuedItemForQueueable(item, create: true) { (item) -> Void in
            let qIndex = self.insert(item!)
            if let complete = complete {
                complete(index: qIndex)
            }
        }
    }
    
    func insert(item:Queueable, atIndex:Int, complete:((insertedIndex:QueueIndex)->Void)?) {
        self.queuedItemForQueueable(item, create: true) { (item) -> Void in
            let qIndex = self.insert(item!, atIndex: atIndex)
            if let complete = complete {
                complete(insertedIndex: qIndex)
            }
        }
    }
    
    func insert(item:QueuedItem, var atIndex:Int) -> QueueIndex {
        return self.operation {
            if let foundIndex = self.removeIfInQueue(item) {
                for x in foundIndex..<(foundIndex+item.numberOfItems) {
                    if x < atIndex {
                        atIndex -= 1
                    }
                }
            }
            
            for x in atIndex..<(atIndex+item.numberOfItems)
            {
                if x < self.playhead {
                    self.playhead += 1
                }
            }
            
            self.needsQueueUpdate = true
            self.items.insert(item, atIndex: atIndex)
            let index = QueueIndex(index: atIndex, playhead: self.playhead)
            self.operations.append(QueueOperation(item: item, type: .Added, queueIndex: index))
            return index
            }!
    }
    
    var needsQueueUpdate = false
    var operationCount = 0
    var operations:[QueueOperation] = []
    
    func operation(operation:()->Void) {
        self.operationStarted()
        self.needsQueueUpdate = true
        operation()
        self.operationEnded()
    }
    
    func operation<T>(operation:()->T?) -> T? {
        self.operationStarted()
        self.needsQueueUpdate = true
        let ret = operation()
        self.operationEnded()
        return ret
    }
    
    func operationStarted() {
        self.operationCount += 1
    }
    
    func operationEnded() {
        self.operationCount -= 1
        
        if self.operationCount == 0 {
            if self.needsQueueUpdate {
                self.needsQueueUpdate = false
                self.processChanges()
            }
        }
    }
    
    func processChanges() {
        
        for x in 0..<self.operations.count {
            let operation = self.operations[x]
            if let item = operation.item {
                item.queueIndex = operation.queueIndex
            }
        }
        
        var x = 0
        for item in self.items {
            let index = QueueIndex(index: x, playhead: self.playhead)
            if item.queueIndex != index {
                item.queueIndex = index
            }
            for track in item.tracks {
                let index = QueueIndex(index: x, playhead: self.playhead)
                if track.queueIndex != index {
                    track.queueIndex = index
                }
                x += 1
            }
        }
        
        for x in 0..<self.observers.count {
            let observer = self.observers[x]
            if let observerItem = observer.observer {
                observerItem.queueUpdated(self)
            }
        }
        
        self.operations.removeAll()
    }
}

extension Queue {
    func indexOfItem(item:Item) -> QueueIndex? {
        for queueItem in self.items {
            if queueItem.isEqual(item) {
                return queueItem.queueIndex
            } else {
                for track in queueItem.tracks {
                    if track.isEqual(item) {
                        return track.queueIndex
                    }
                }
            }
        }
        return nil
    }
}

extension Array {
    
    func index(ofIdentifiable:Identifiable) -> Int? {
        var x = 0
        for item in self {
            if let item = item as? Identifiable {
                if item.isEqual(ofIdentifiable) {
                    return x
                }
            }
            x += 1
        }
        return nil
    }
    
    func index(ofQueueable:Queueable) -> Int? {
        var x = 0
        for item in self {
            if let item = item as? Queueable {
                if item.equals(ofQueueable) {
                    return x
                }
            }
            x += 1
        }
        return nil
    }
    
}