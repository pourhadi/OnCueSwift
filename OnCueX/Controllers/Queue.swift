//
//  Queue.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/21/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

//let _queue = Queue()

struct QueueIndex: Equatable {
    let index:Int
    let playhead:Int
    
    var displayIndex:String {
        return ""
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
    }
    
    unowned var item:Queueable
    let type:OperationType
    var queueIndex:QueueIndex?
    
    init(item:Queueable, type:OperationType, queueIndex:QueueIndex?) {
        self.item = item
        self.type = type
        self.queueIndex = queueIndex
    }
}

class Queue {

    var observers:[String:QueueObserver] = [:]
    func addObserver(observer:QueueObserver) { self.observers[observer.identifier] = observer }
    func removeObserver(observer:QueueObserver) { self.observers.removeValueForKey(observer.identifier) }
    
    var playhead = 0
    
    var items:[Queueable] = []
    
    func remove(itemAtIndex:Int) {
        self.operationStarted()
        let item = self.items[itemAtIndex]
        self.items.removeAtIndex(itemAtIndex)
        self.operations.append(QueueOperation(item: item, type: .Removed, queueIndex: nil))
        self.needsQueueUpdate = true
        self.operationEnded()
    }
    
    func removeIfInQueue(item:Queueable) -> Int? {
        return self.operation {
            if let index = self.items.index(item) {
                self.remove(index)
                if index < self.playhead {
                    self.playhead -= 1
                }
                return index
            }
            return nil
        }
    }
    
    func insert(item:Queueable) -> Int {
        return self.insert(item, atIndex: self.items.count)
    }
    
    func insert(item:Queueable, var atIndex:Int) -> Int {
        return self.operation {
            if let foundIndex = self.removeIfInQueue(item) {
                if foundIndex < atIndex {
                    atIndex -= 1
                }
            }
            
            if atIndex < self.playhead {
                self.playhead += 1
            }
            
            self.needsQueueUpdate = true
            self.items.insert(item, atIndex: atIndex)
            self.operations.append(QueueOperation(item: item, type: .Added, queueIndex: QueueIndex(index: atIndex, playhead: self.playhead)))
            return atIndex
        }!
    }
    
    
    var needsQueueUpdate = false
    var operationCount = 0
    var operations:[QueueOperation] = []
    func operation<T>(operation:()->T?) -> T? {
        self.operationStarted()
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
        
        for operation in self.operations {
            operation.item.queueIndex = operation.queueIndex
        }
        
        var x = 0
        for item in self.items {
            let index = QueueIndex(index: x, playhead: self.playhead)
            if item.queueIndex != index {
                item.queueIndex = index
            }
            x += 1
        }
        
        for (_, observer) in self.observers {
            observer.queueUpdated(self)
        }
        
        self.operations.removeAll()
    }
}

extension Array {
    
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