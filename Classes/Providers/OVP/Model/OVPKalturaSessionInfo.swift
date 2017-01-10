//
//  OVPKalturaSessionInfo.swift
//  Pods
//
//  Created by Rivka Peleg on 01/01/2017.
//
//

import UIKit
import SwiftyJSON


//"sessionType": "2",
//"partnerId": "1851571",
//"userId": "kaltura.fe@icloud.com",
//"expiry": "1483311163",
//"privileges": "*",
//"objectType": "KalturaSessionInfo"

class OVPKalturaSessionInfo: OVPBaseObject {
    
    let expiry: Date
    
    private let expiryKey = "expiry"
    required init?(json: Any) {
        
        let jsonObject = JSON(json)
        if let expiry = jsonObject[self.expiryKey].string,
            let doubleExpiry = Double(expiry)
        {
            self.expiry = Date(timeIntervalSince1970: TimeInterval(doubleExpiry))
        }else{
            return nil
        }
    }
    
    
}
