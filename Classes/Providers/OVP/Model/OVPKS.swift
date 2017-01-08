//
//  OVPKS.swift
//  Pods
//
//  Created by Rivka Peleg on 01/01/2017.
//
//

import UIKit

class OVPKS: OVPBaseObject {

    var ks: String
    
    required init?(json: Any) {
        if let ks = json as? String {
            self.ks = ks
        }else{
            return nil
        }
    }
}
