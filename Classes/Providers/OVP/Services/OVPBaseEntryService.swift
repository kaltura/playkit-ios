//
//  OVPBaseEntry.swift
//  Pods
//
//  Created by Rivka Peleg on 27/11/2016.
//
//

import UIKit
import SwiftyJSON

class OVPBaseEntryService {

    internal static func list(baseURL: String, ks: String,entryID: String) -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "baseEntry", action: "list") {
            let responseProfile = ["fields":"mediaType,dataUrl,id,name,duration,msDuration,flavorParamsIds","type":1] as [String : Any]
            let filter = ["redirectFromEntryId":entryID]
            request.setBody(key: "ks", value: JSON(ks))
            .setBody(key: "responseProfile", value: JSON(responseProfile))
            .setBody(key: "filter", value: JSON(filter))
            return request
        }else{
            return nil
        }
    }

    internal static func getContextData(baseURL: String, ks: String,entryID: String) -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "baseEntry", action: "getContextData") {
            let contextData:[String:Any] = [String:Any]()
            request.setBody(key: "ks", value: JSON(ks))
                .setBody(key: "entryId", value: JSON(entryID))
                .setBody(key: "contextDataParams", value: JSON(contextData))
            return request
        }else{
            return nil
        }
        
    }

}

