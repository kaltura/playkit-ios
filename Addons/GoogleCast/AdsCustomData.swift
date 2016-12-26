//
//  AdsCustomData.swift
//  Pods
//
//  Created by Rivka Peleg on 26/12/2016.
//
//

import UIKit


public class AdsCustomData: NSObject {
    
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
