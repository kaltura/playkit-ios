// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation

extension Array where Element: Equatable {
    
    /**
     Remove an element from the array and invalidates all indexes.
     
     - parameter element: The element to remove.
     */
    mutating func remove(element: Element) {
        if let index = self.firstIndex(of: element) {
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
