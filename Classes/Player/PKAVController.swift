//
//  PKAVController.swift
//  PlayKit
//
//  Created by Nilit Danan on 2/26/20.
//

import AVFoundation

@objc public class PKAVController: NSObject, PKController {
    /************************************************************/
    // MARK: - Properties
    /************************************************************/
    
    var currentPlayer: AVPlayerEngine?
    
    public var asset: AVAsset? {
        get {
            return currentPlayer?.asset?.avAsset ?? nil
        }
    }
    
    /************************************************************/
    // MARK: - Initialization
    /************************************************************/

    @objc required public init(player: PlayerEngine?) {
        self.currentPlayer = (player as? AVPlayerWrapper)?.currentPlayer
    }
}
