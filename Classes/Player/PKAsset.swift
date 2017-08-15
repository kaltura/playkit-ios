//
//  PKAsset.swift
//  Pods
//
//  Created by Gal Orlanczyk on 15/08/2017.
//
//

import Foundation
import AVFoundation

struct PKAsset {
    let avAsset: AVURLAsset
    let playerSettings: PKPlayerSettings
    
    init(avAsset: AVURLAsset, playerSettings: PKPlayerSettings) {
        self.avAsset = avAsset
        self.playerSettings = playerSettings.createCopy()
    }
}
