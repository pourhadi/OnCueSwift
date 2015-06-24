//
//  Queue.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/21/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

let _queue:Queue = Queue()

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
        case PlayheadChanged
    }
    
    var item:Queueable?
    let type:OperationType
    var queueIndex:QueueIndex?
    
    init(item:Queueable?, type:OperationType, queueIndex:QueueIndex?) {
        self.item = item
        self.type = type
        self.queueIndex = queueIndex
    }
}

final class Queue {

    var observers:[String:QueueObserver] = [:]
    func addObserver(observer:QueueObserver) { self.observers[observer.identifier] = observer }
    func removeObserver(observer:QueueObserver) { self.observers.removeValueForKey(observer.identifier) }
    
    var playhead = 0 {
        didSet {
            self.operation {
                self.operations.append(QueueOperation(item: nil, type: .PlayheadChanged, queueIndex: nil))
            }
        }
    }
    
    var items:[Queueable] = []
    
    func remove(itemAtIndex:Int) {
        self.operation {
            let item = self.items[itemAtIndex]
            let numOfItems = item.childItems != nil ? item.childItems!.count : 1
            self.items.removeAtIndex(itemAtIndex)
            self.operations.append(QueueOperation(item: item, type: .Removed, queueIndex: QueueIndex(index: itemAtIndex, playhead: self.playhead)))
            
            if numOfItems > 1 {
                for x in itemAtIndex..<(itemAtIndex+numOfItems) {
                    if x < self.playhead {
                        self.playhead -= 1
                    }
                }
            }
            if itemAtIndex < self.playhead {
                self.playhead -= 1
            }
        }
    }
    
    func removeIfInQueue(item:Queueable) -> Int? {
        return self.operation {
            if let index = self.items.index(item) {
                self.remove(index)
                return index
            }
            return nil
        }
    }
    
    func insert(item:Queueable) -> Int {
        return self.insert(item, atIndex: item.queueIndex != nil ? 0 : self.items.count)
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