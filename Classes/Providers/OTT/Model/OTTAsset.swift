//
//  Asset.swift
//  Pods
//
//  Created by Admin on 15/11/2016.
//
//

import UIKit
import SwiftyJSON

internal class OTTAsset {

    internal var id: String 
    internal var files: [OTTFile]?
    
    private let idKey = "id"
    private let idfiles = "mediaFiles"
    
    internal init?(json:Any) {
        
        let assetJson = JSON(json)
        guard let id = assetJson[idKey].number else {
            return nil
        }
        
        self.id = id.stringValue
        if let jsonFiles = assetJson[idfiles].array {
            
            self.files = [OTTFile]()
            for jsonFile in jsonFiles {
                if let file = OTTFile(json: jsonFile.object){
                    self.files?.append(file)
                }
            }
        }
    }
}

