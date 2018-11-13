// ===================================================================================================
// Copyright (C) 2018 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

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
