//
//  OVPStartWidgetSessionResponse.swift
//  Pods
//
//  Created by Rivka Peleg on 30/12/2016.
//
//

import UIKit
import SwiftyJSON

//{
//    "partnerId": 1851571,
//    "ks": "djJ8MTg1MTU3MXxpaGILkzBCPpdG6oGTMOBdCMcLCX8Cnl2BNlJVGZ6uqoz6fknXXha6b-j_ljU1151redfcbuR2Mt9fNoH7h52x6fyp9aztK4YrR0nsiHE9PQ==",
//    "userId": 0,
//    "objectType": "KalturaStartWidgetSessionResponse"
//}

class OVPStartWidgetSessionResponse: OVPBaseObject {

    let ks: String
    private let ksKey = "ks"
    
    required init?(json:Any){
        let json = JSON(json)
        if let ks = json[self.ksKey].string {
            self.ks = ks
        }else{
            return nil
        }
    }

}
