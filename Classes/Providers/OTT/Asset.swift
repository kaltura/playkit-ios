//
//  Asset.swift
//  Pods
//
//  Created by Admin on 15/11/2016.
//
//

import UIKit
import SwiftyJSON

class Asset {

    var id: String? = nil
    var files: [File]?
    
    private let idKey = "id"
    private let idfiles = "mediaFiles"
    
    init(json:Any) {
        let assetJson = JSON(json)
        self.id = assetJson[idKey].string
        if let jsonFiles = assetJson[idfiles].array {
            
            self.files = [File]()
            for jsonFile in jsonFiles {
                let file = File(json: jsonFile.object)
                self.files?.append(file)
            }
        }
    }
}

