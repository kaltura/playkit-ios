//
//  OTTMultilingualStringValue.swift
//  PlayKit
//
//  Created by Nilit Danan on 8/20/18.
//

import Foundation
import SwiftyJSON

class OTTMultilingualStringValue: OTTBaseObject {
    
    var value: String?
    
    let valueKey = "value"
    
    required init?(json: Any) {
        if let jsonDictionary = JSON(json).dictionary {
            self.value = jsonDictionary[valueKey]?.string
        }
    }
}
