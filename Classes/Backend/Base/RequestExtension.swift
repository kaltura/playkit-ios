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
import SwiftyJSON
import KalturaNetKit


extension KalturaRequestBuilder {
    
    @discardableResult
    public func setClientTag(clientTag: String) -> Self {
        self.setBody(key: "clientTag", value: JSON(clientTag))
        return self
    }
    
    @discardableResult
    public func setApiVersion(apiVersion: String) -> Self {
        self.setBody(key: "apiVersion", value: JSON(apiVersion))
        return self
    }
    
    @discardableResult
    public func setFormat(format: Int) -> Self {
        self.setBody(key: "format", value: JSON(format))
        return self
    }
    

    @discardableResult
    internal func setOVPBasicParams() -> Self{
        self.setClientTag(clientTag: "playkit")
        self.setApiVersion(apiVersion: "3.3.0")
        self.setFormat(format: 1)
        return self

    }
}
