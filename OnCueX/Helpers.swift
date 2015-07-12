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
    
    var description: String {
/*int seconds = totalSeconds % 60;
int minutes = (totalSeconds / 60) % 60;
int hours = totalSeconds / 3600;

return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];*/
        
        let seconds = self % 60
        let minutes = (self / 60) % 60
        
        return String(format: "%02d:%02d", arguments: [minutes, seconds])
    }

}