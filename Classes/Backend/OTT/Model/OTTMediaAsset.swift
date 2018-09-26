//
//  OTTMediaAsset.swift
//  PlayKit
//
//  Created by Nilit Danan on 8/19/18.
//

import Foundation
import SwiftyJSON


fileprivate let idKey = "id"
fileprivate let typeKey = "type"
fileprivate let nameKey = "name"
fileprivate let mediaFilesKey = "mediaFiles"
fileprivate let metasKey = "metas"

public class OTTMediaAsset: OTTBaseObject {
    // This class is for both KalturaMediaAsset and KalturaProgramAsset, because
    // the fields we use are common between them.
    
    var id: Int?
    var type: Int?
    var name: String?
    var mediaFiles: [OTTMediaFile] = []
    var metas: Dictionary<String, OTTBaseObject> = Dictionary()
    
    public required init?(json: Any) {
        let jsonObj: JSON = JSON(json)
        
        self.id = jsonObj[idKey].int
        self.type = jsonObj[typeKey].int
        self.name = jsonObj[nameKey].string
        
        var mediaFiles = [OTTMediaFile]()
        jsonObj[mediaFilesKey].array?.forEach { (json) in
            if let mediaFile = OTTMediaFile(json: json.object) {
                mediaFiles.append(mediaFile)
            }
        }
        
        if !mediaFiles.isEmpty {
            self.mediaFiles = mediaFiles
        }
        
        if let metas = jsonObj[metasKey].dictionary {
            let metaKeys = metas.keys
            for key: String in metaKeys {
                if let jsonObject = metas[key] {
                    let objectType: OTTBaseObject.Type? = OTTObjectMapper.classByJsonObject(json: jsonObject.dictionaryObject)
                    if let type = objectType {
                        if let object = type.init(json: jsonObject.object) {
                            self.metas[key] = object
                        }
                    }
                }
            }
        }
    }
    
    func arrayOfMetas() -> [String: String] {
        var metas: [String: String] = [:]
        for meta in self.metas {
            if let stringValue = meta.value as? OTTMultilingualStringValue {
                metas[meta.key] = stringValue.value?.description
            }
        }
        
        return metas
    }
}
