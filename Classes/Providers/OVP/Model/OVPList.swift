//
//  OVPList.swift
//  Pods
//
//  Created by Rivka Peleg on 28/11/2016.
//
//

import UIKit

class OVPList: OVPBaseObject {

    
    var objects: [OVPBaseObject]?
    
    init(objects:[OVPBaseObject]?) {
        self.objects = objects
    }
    required init?(json: Any) {
        
    }
}
