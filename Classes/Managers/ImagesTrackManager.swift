//
//  ImagesTrackManager.swift
//  PlayKit
//
//  Created by Sergey Chausov on 18.03.2021.
//

import Foundation
import AVFoundation

class ImagesTrackManager: NSObject {
    
    var imageGenerator: AVAssetImageGenerator?
    
    func prepareFor(asset: AVAsset) {
        self.imageGenerator = AVAssetImageGenerator(asset: asset)
        // self.imageGenerator.maximumSize = CGSize(width: 320, height: 180)
    }
    
    func loadImages(time: [CMTime], completionHandler: @escaping AVAssetImageGeneratorCompletionHandler) {
        //let duration = Int(asset.duration.seconds)
        
        var frames: [NSValue] = []
        for time in time {
            frames.append(NSValue.init(time: time))
        }
        
        /*
        for index in 1...duration {
            if index % 10 == 0 {
                let time = CMTime.init(seconds: Double(index), preferredTimescale: 1)
                frames.append(NSValue.init(time: time))
            }
        }
        */
        self.imageGenerator?.generateCGImagesAsynchronously(forTimes: frames, completionHandler: completionHandler)
    }
    
    func stopAll() {
        self.imageGenerator?.cancelAllCGImageGeneration()
    }
}
