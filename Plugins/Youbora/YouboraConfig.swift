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
            config["accountCode"] = "kalturatest"
            config["service"] = "nqs.nice264.com"
            config["username"] = "kalturatestadmin"
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
                             "content_id": NSNull(),
                             "transaction_type": NSNull(),
                             "language": NSNull(),
                             "type": "video",
                             "genre": NSNull(),
                             
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
                             "quality": NSNull()
            ]

            config["extraParams"] = [
                "param1" : "value1"
            ]
            
            return config
        }
    }
    
    
}
