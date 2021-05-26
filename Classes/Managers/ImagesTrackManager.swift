//
//  ImagesTrackManager.swift
//  PlayKit
//
//  Created by Sergey Chausov on 18.03.2021.
//

import Foundation
import AVFoundation

class ImagesTrackManager: NSObject {
    
    func loadImages(asset: AVAsset, completionHandler: @escaping AVAssetImageGeneratorCompletionHandler) {

        let duration = Int(asset.duration.seconds)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        // imageGenerator.maximumSize = CGSize(width: 320, height: 180)
        
        var frames: [NSValue] = []
        
        for index in 1...duration {
            if index % 10 == 0 {
                let time = CMTime.init(seconds: Double(index), preferredTimescale: 1)
                frames.append(NSValue.init(time: time))
            }
        }
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: frames, completionHandler: completionHandler)
    }
}
