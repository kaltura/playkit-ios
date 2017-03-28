//
//  OTTResponse.swift
//  Pods
//
//  Created by Admin on 15/11/2016.
//
//

import UIKit
import SwiftyJSON

internal class OTTGetAssetResponse: OTTBaseObject {

    internal var asset: OTTAsset?

    private let resultKey = "result"

    internal required init(json:Any) {

        let responseJson = JSON(json)
        let assetJson = responseJson[resultKey]
        self.asset = OTTAsset(json: assetJson.object)
    }
}
