// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit

class SourceBuilder {  
    var baseURL: String?
    var partnerId: Int64?
    var ks: String?
    var entryId: String?
    var flavors:[String]?
    var uiconfId:Int64?
    var format:String? = "url"
    var sourceProtocol:String? = "https"
    var drmSchemes:[String]?
    var fileExtension: String?
    

    @discardableResult
    func set(baseURL:String?) -> SourceBuilder {
        self.baseURL = baseURL
        return self
    }
    
    @discardableResult
    func set(partnerId:Int64?) -> SourceBuilder {
        self.partnerId = partnerId
        return self
    }
    
    @discardableResult
    func set(ks:String?) -> SourceBuilder {
        self.ks = ks
        return self
    }

    @discardableResult
    func set(entryId:String?) -> SourceBuilder {
        self.entryId = entryId
        return self
    }

    @discardableResult
    func set(flavors:[String]?) -> SourceBuilder {
        self.flavors = flavors
        return self
    }

    @discardableResult
    func set(uiconfId:Int64?) -> SourceBuilder {
        self.uiconfId = uiconfId
        return self
    }

    @discardableResult
    func set(format:String?) -> SourceBuilder {
        self.format = format
        return self
    }
    
    @discardableResult
    func set(sourceProtocol:String?) -> SourceBuilder {
        self.sourceProtocol = sourceProtocol
        return self
    }
    
    @discardableResult
    func set(drmSchemes:[String]?) -> SourceBuilder {
        self.drmSchemes = drmSchemes
        return self
    }
    
    @discardableResult
    func set(fileExtension: String) -> SourceBuilder {
        self.fileExtension = fileExtension
        return self
    }
    
    func build() -> URL? {
        
        guard
            let baseURL = self.baseURL,
            baseURL.isEmpty == false,
            let partnerId = self.partnerId,
            let format = self.format,
            let entryId = self.entryId,
            let sourceProtocol = self.sourceProtocol,
            let fileExt = self.fileExtension
        else {
            return nil
        }
        
        var urlAsString: String = baseURL + "/p/" + String(partnerId) + "/sp/" + String(partnerId) + "00/playManifest" + "/entryId/" + entryId + "/protocol/" + sourceProtocol + "/format/" + format
        
        var flavorsExist = false
        if let flavors = self.flavors {
            flavorsExist = true
            urlAsString = urlAsString + "/flavorIds/"
            var first = true
            for flavor in flavors{
                if ( first == false )
                {
                    urlAsString.append(",")
                }
                urlAsString.append(flavor)
                first = false
            }
            
        }
        
        if let uiconfId = self.uiconfId, flavorsExist == false{
            urlAsString.append("/uiConfId/" + String(uiconfId))
        }
        
        
        if let ks = self.ks{
            urlAsString = urlAsString + "/ks/" + ks
        }
        

        urlAsString = urlAsString + "/a." + fileExt
        
        var params: [String] = [String]()
        
        if flavorsExist == true , let uiconfId = self.uiconfId {
            params.append("/uiConfId/" + String(uiconfId))
        }
        
        
        var isFirst = true
        for param in params {
           
            if ( isFirst) {
              urlAsString.append("?")
            } else {
              urlAsString.append("&")
            }
            urlAsString.append(param)
            isFirst = false
        }
        
        return URL(string: urlAsString)
    }
}
