//
//  YouboraConfig.swift
//  Pods
//
//  Created by Oded Klein on 24/11/2016.
//
//

import UIKit

class YouboraConfig: NSObject {

    static var defaultYouboraConfig : [String: Any] {
        get {
            var config = [String: Any]()
            
            config["enableAnalytics"] = true
            config["parseHLS"] = false
            config["parseCDNNodeHost"] = false
            config["hashTitle"] = true
            config["httpSecure"] = false
            config["enableNiceBuffer"] = true
            config["enableNiceSeek"] = true
            config["accountCode"] = "kaltura"
            config["service"] = "nqs.nice264.com"
            config["username"] = ""
            config["transactionCode"] = ""
            config["isBalanced"] = "0"
            config["isResumed"] = "0"
            config["haltOnError"] = true

            config["network"] = ["ip": "", "isp": ""]
            
            config["device"] = ["id": NSNull()] //Or Any?
            
            config["media"] = ["isLive": false,
                               "resource": NSNull(),
                               "title": "Title",
                               "duration": NSNull(),
                               "cdn": NSNull()]

            config["ads"] = ["adsExpected": false,
                             "resource": NSNull(),
                             "title": NSNull(),
                             "campaign": "",
                             "position": NSNull(),
                             "duration": NSNull()]
            
            config["properties"] = [
                             "contentId": NSNull(),
                             "transaction_type": NSNull(),
                             "language": NSNull(),
                             "type": "video",
                             "genre": "Action",
                             
                             "year": "",
                             "cast": NSNull(),
                             "director": NSNull(),
                             "owner": NSNull(),
                             "parental": NSNull(),
                             "price": NSNull(),
                             "rating": NSNull(),
                             "audioType": NSNull(),
                             "audioChannels": NSNull(),
                             "device": NSNull(),
                             "quality": NSNull()]

            config["extraParams"] = [
                "param1" : "Param 1 value",
                "param2" : "Param 2 value",
                "param3" : "Param 3 value",
                "param4" : "Param 4 value",
                "param5" : "Param 5 value",
                "param6" : "Param 6 value",
                "param7" : "Param 7 value",
                "param8" : "Param 8 value",
                "param9" : "Param 9 value",
                "param10" : "Param 10 value"]
            
            return config
        }
    }
    
    
}
