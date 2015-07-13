//
//  Helpers.swift
//  
//
//  Created by Daniel Pourhadi on 6/20/15.
//
//

import UIKit

func uniq<S : SequenceType, T : Hashable where S.Generator.Element == T>(source: S) -> [T] {
    var buffer = [T]()
    var added = Set<T>()
    for elem in source {
        if !added.contains(elem) {
            buffer.append(elem)
            added.insert(elem)
        }
    }
    return buffer
}


extension NSTimeInterval {
    
    func toString() -> String {

        let seconds = self % 60
        let minutes = (self / 60) % 60
        
        return String(format: "%02f:%02f", arguments: [minutes, seconds])
    }

}