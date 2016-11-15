//
//  Asset.swift
//  Pods
//
//  Created by Admin on 15/11/2016.
//
//

import UIKit
import SwiftyJSON

internal class Asset {

    internal var id: String 
    internal var files: [File]?
    
    private let idKey = "id"
    private let idfiles = "mediaFiles"
    
    internal init?(json:Any) {
        
        let assetJson = JSON(json)
        guard let id = assetJson[idKey].number else {
            return nil
        }
        
        self.id = id.stringValue
        if let jsonFiles = assetJson[idfiles].array {
            
            self.files = [File]()
            for jsonFile in jsonFiles {
                if let file = File(json: jsonFile.object){
                    self.files?.append(file)
                }
            }
        }
    }
}

