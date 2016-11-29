//
//  AssetBuilder.swift
//  Pods
//
//  Created by Eliza Sapir on 29/11/2016.
//
//

import AVFoundation

class AssetBuilder {
    public var contentUrl: AVURLAsset?
//    public var drmData: DRMData
    
    init(config: PlayerConfig, readyBlock: @escaping (_ asset: Any)->Void) {
        if let sources = config.mediaEntry?.sources {
            if sources.count > 0 {
                if let contentUrl = sources[0].contentUrl {
                    self.contentUrl = AVURLAsset(url: contentUrl)
                }
            }
        }
    }
    
    func buildAsset() {
        preconditionFailure("This method must be overridden")
    }
}
