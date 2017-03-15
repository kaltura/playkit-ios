//
//  ArrayExtension.swift
//  Pods
//
//  Created by Gal Orlanczyk on 07/03/2017.
//
//

import Foundation

extension Array where Element: Equatable {
    
    /**
     Remove an element from the array and invalidates all indexes.
     
     - parameter element: The element to remove.
     */
    mutating func remove(element: Element) {
        if let index = self.index(of: element) {
            self.remove(at: index)
        }
    }
    
    /**
     Removes elements from the array and invalidates all indexes.
     
     - parameter elements: The array with the elements to delete.
     */
    mutating func remove(elements: [Element]) {
        for element in elements {
            remove(element: element)
        }
    }
}
