//
//  AdsCustomData.swift
//  Pods
//
//  Created by Rivka Peleg on 26/12/2016.
//
//

import UIKit
import GoogleCast

/**
 CastAdInfoParser
 
 This class can be used to handle advertisement UI while casting while using google components.
 There is 2 options to use this class :
 1. set 
 
 */
public class CastAdInfoParser: NSObject, GCKRemoteMediaClientAdInfoParserDelegate {
    
    
    public static let shared = CastAdInfoParser()
    
    /**
     return A boolean flag indicating whether your receiver is currently playing an ad ot not
     */
    public func remoteMediaClient(_ client: GCKRemoteMediaClient, shouldSetPlayingAdIn mediaStatus: GCKMediaStatus) -> Bool {
        
         guard let customData = mediaStatus.customData as? [String:Any],
            let adsInfo = customData["adsInfo"] as? [String:Any],
            let metaData : AdsMetadata = AdsMetadata(dict: adsInfo) else {
                PKLog.warning("No Ads info from receiver")
                return false
        }
        
        return metaData.isPlayingAd
        
    }
    
    /**
     A list of playback positions at which the ads occur.
     */
    public func remoteMediaClient(_ client: GCKRemoteMediaClient, shouldSetAdBreaksIn mediaStatus: GCKMediaStatus) -> [GCKAdBreakInfo]? {
        
        guard let customData = mediaStatus.customData as? [String:Any],
            let adsInfo = customData["adsInfo"] as? [String:Any],
            let adsData : AdsMetadata = AdsMetadata(dict: adsInfo),
            let adsBreakInfo = adsData.adsBreakInfo else {
                PKLog.warning("No Ads info from receiver")
                return nil
        }
        
        let adsBreakInfoArray = adsBreakInfo.map({ GCKAdBreakInfo(playbackPosition: TimeInterval($0)) })
        return adsBreakInfoArray
    }
}



/**
  An object which represent the Ads info 
  The receiver is sending this data by the mediaStatus's customData
 */
private class AdsMetadata: NSObject {
    
    public let adsBreakInfo: [Int]?
    public let isPlayingAd: Bool
    
    public init(dict:[String:Any]) {
        
        if let isPlaying = dict["isPlayingAd"] as? Bool {
            self.isPlayingAd = isPlaying
        }else{
            self.isPlayingAd = false
        }
        
        if let adBreaksInfo = dict["adsBreakInfo"] as? [NSNumber] {
            self.adsBreakInfo = adBreaksInfo.map({ (number:NSNumber) -> Int in
                return number.intValue
            })
        }else{
            self.adsBreakInfo  = nil
        }
        
        
    }
}
