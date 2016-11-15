//
//  OTTResponse.swift
//  Pods
//
//  Created by Admin on 15/11/2016.
//
//

import UIKit
import SwiftyJSON

internal class OTTGetAssetResponse: NSObject {

    internal var asset: Asset? = nil
    
    private let resultKey = "result"
    
    internal init(json:Any) {
        
        let responseJson = JSON(json)
        let assetJson = responseJson[resultKey]
        self.asset = Asset(json: assetJson.object)
    }
}

