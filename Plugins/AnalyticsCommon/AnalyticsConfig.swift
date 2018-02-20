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

@objc public class AnalyticsConfig: NSObject {
    
    @objc public var params: [String: Any]
    
    @objc public init(params: [String: Any]) {
        self.params = params
    }
    
    public static func parse(json: JSON) -> AnalyticsConfig? {
        var _dict: [String: Any]?
        do {
            _dict = try JSONSerialization.jsonObject(with: json.rawData(), options: [JSONSerialization.ReadingOptions.mutableContainers, JSONSerialization.ReadingOptions.mutableLeaves]) as? [String: Any]
        } catch {
            return nil
        }
        guard let params = _dict?["options"] as? [String : Any] else {
            return nil
        }
        return AnalyticsConfig(params: params)
    }
    
    public func merge(config: AnalyticsConfig) -> AnalyticsConfig {
        params = merge(left: params, right: config.params)
        return self
    }
    
    func merge(left: [String : Any], right: [String : Any]) -> [String : Any] {
        var result = left
        for (key, value) in right {
            if let rightDict = value as? [String : Any], let leftDict = left[key] as? [String : Any] {
                result[key] = merge(left: leftDict, right: rightDict)
            } else {
                result[key] = value
            }
        }
        return result
    }
}
