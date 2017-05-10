//
//  KalturaLiveStreamEntry.swift
//  Pods
//
//  Created by Gal Orlanczyk on 07/05/2017.
//
//

import Foundation
import SwiftyJSON

class OVPLiveStreamEntry: OVPEntry {
    
    var dvrStatus: Bool?
    
    let dvrStatusKey = "dvrStatus"
    
    required init?(json: Any) {
        super.init(json: json)
        
        let jsonObject = JSON(json)
        self.dvrStatus = jsonObject[dvrStatusKey].bool
    }
}
