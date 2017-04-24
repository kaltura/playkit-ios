//
//  OVPEntryContextData.swift
//  Pods
//
//  Created by Rivka Peleg on 28/11/2016.
//
//

import UIKit
import SwiftyJSON

class OVPPlaybackContext: OVPBaseObject {
    
    var flavorAssets: [OVPFlavorAsset]? = nil
    var sources: [OVPSource]?
    let flavorAssetsKey = "flavorAssets"
    let sourcesKey = "sources"
    
    
    required internal init?(json: Any)
    {
        let jsonObject = JSON(json)
        let flavorAssetsJson = jsonObject[flavorAssetsKey].array
        
        
        self.flavorAssets = [OVPFlavorAsset]()
        flavorAssetsJson?.forEach({ (flavorAssetJson:JSON) in
            if let flavorAsset = OVPFlavorAsset(json:flavorAssetJson.object){
                self.flavorAssets?.append(flavorAsset)
            }
        })
        
        let sources = jsonObject[sourcesKey].array
        self.sources = [OVPSource]()
        sources?.forEach({ (sourceJson:JSON) in
            if let source = OVPSource(json: sourceJson.object){
                self.sources?.append(source)
            }
        })
        
        
        
        
    }
    
}
