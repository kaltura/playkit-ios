//
//  OVPMetadata.swift
//  Pods
//
//  Created by Itay Kinnrot on 09/01/2017.
//
//

import UIKit
import SwiftyJSON

class OVPMetadata: OVPBaseObject {
    var xml:String?
    
    required init?(json: Any) {
        
        let jsonObject = JSON(json)
        self.xml = jsonObject["xml"].string
        
    }
    
}
