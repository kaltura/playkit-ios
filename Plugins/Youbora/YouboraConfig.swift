//
//  YouboraConfig.swift
//  Pods
//
//  Created by Nilit Danan on 5/8/18.
//

import YouboraLib

struct YouboraConfig: Decodable {
    let accountCode: String
    let username: String?
    let userType: String?
    let houseHoldId: String?
    let obfuscateIP: Bool?
    let httpSecure: Bool = true
    let media: Media?
    let ads: Ads?
    let properties: Properties?
    let extraParams: ExtraParams?
    
    func options() -> YBOptions {
        let options = YBOptions()
        
        options.accountCode = accountCode
        options.username = username
        options.userType = userType
        options.networkObfuscateIp = obfuscateIP != nil ? NSNumber(booleanLiteral: obfuscateIP!) : nil
        options.parseHls = false
        options.parseCdnNode = false
        options.httpSecure = httpSecure
        
        options.deviceCode = nil // List of device codes http://mapi.youbora.com:8081/devices
        options.contentCdn = nil
        
        if let media = media {
            options.contentIsLive = media.isLive != nil ? NSNumber(booleanLiteral: media.isLive!) :  nil
            options.contentIsLiveNoSeek = media.isDVR != nil ? NSNumber(booleanLiteral: !(media.isDVR!)) : nil
            options.contentDuration = media.duration != nil ? NSNumber(value: media.duration!) : nil
            options.contentTitle = media.title
            options.contentTitle2 = media.title2
            options.contentTransactionCode = media.transactionCode
        }
        
        options.adResource = nil
        options.adCampaign = ads?.campaign
        options.adTitle = ""
        
        if let ads = ads, let adsExtraParams = ads.extraParams {
            options.adExtraparam1 = adsExtraParams.param1
            options.adExtraparam2 = adsExtraParams.param2
            options.adExtraparam3 = adsExtraParams.param3
            options.adExtraparam4 = adsExtraParams.param4
            options.adExtraparam5 = adsExtraParams.param5
            options.adExtraparam6 = adsExtraParams.param6
            options.adExtraparam7 = adsExtraParams.param7
            options.adExtraparam8 = adsExtraParams.param8
            options.adExtraparam9 = adsExtraParams.param9
            options.adExtraparam10 = adsExtraParams.param10
        }
        
        if let properties = properties {
            options.contentMetadata = ["genre": properties.genre ?? "",
                                       "type": properties.type ?? "",
                                       "transaction_type": properties.transactionType ?? "",
                                       "year": properties.year ?? "",
                                       "cast": properties.cast ?? "",
                                       "director": properties.director ?? "",
                                       "owner": properties.owner ?? "",
                                       "parental": properties.parental ?? "",
                                       "price": properties.price ?? "",
                                       "rating": properties.rating ?? "",
                                       "audioType": properties.audioType ?? "",
                                       "audioChannels": properties.audioChannels ?? "",
                                       "device": properties.device ?? "",
                                       "quality": properties.quality ?? ""]
        }
        
        if let extraParams = extraParams {
            options.extraparam1 = extraParams.param1
            options.extraparam2 = extraParams.param2
            options.extraparam3 = extraParams.param3
            options.extraparam4 = extraParams.param4
            options.extraparam5 = extraParams.param5
            options.extraparam6 = extraParams.param6
            options.extraparam7 = extraParams.param7
            options.extraparam8 = extraParams.param8
            options.extraparam9 = extraParams.param9
            options.extraparam10 = extraParams.param10
        }
        
        return options
    }
}

struct Media: Decodable {
    let resource: String?
    let isLive: Bool?
    let isDVR: Bool?
    let title: String?
    let title2: String?
    let duration: Double?
    let transactionCode: String?
}

struct Ads: Decodable {
    let campaign: String?
    let extraParams: ExtraParams?
}

struct Properties: Decodable {
    let genre: String?
    let type: String?
    let transactionType: String?
    let year: String?
    let cast: String?
    let director: String?
    let owner: String?
    let parental: String?
    let price: String?
    let rating: String?
    let audioType: String?
    let audioChannels: String?
    let device: String?
    let quality: String?
}

struct ExtraParams: Decodable {
    let param1: String?
    let param2: String?
    let param3: String?
    let param4: String?
    let param5: String?
    let param6: String?
    let param7: String?
    let param8: String?
    let param9: String?
    let param10: String?
}
