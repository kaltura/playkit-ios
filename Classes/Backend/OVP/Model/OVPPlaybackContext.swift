// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

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
