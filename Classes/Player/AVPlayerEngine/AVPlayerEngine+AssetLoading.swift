// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import AVFoundation

extension AVPlayerEngine {
    
    override public func replaceCurrentItem(with item: AVPlayerItem?) {
        // when changing asset reset last timebase
        self.lastTimebaseRate = 0
        // When changing media (loading new asset) we want to reset isFirstReady in order to receive `CanPlay` & `LoadedMetadata` accuratly.
        self.isFirstReady = true
        self.lastIndicatedBitrate = 0
        super.replaceCurrentItem(with: item)
    }
    
    func asynchronouslyLoadURLAsset(_ newAsset: PKAsset) {
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        newAsset.avAsset.loadValuesAsynchronously(forKeys: self.assetKeysRequiredToPlay) {
            /*
             The asset invokes its completion handler on an arbitrary queue.
             To avoid multiple threads using our internal state at the same time
             we'll elect to use the main thread at all times, let's dispatch
             our handler to the main queue.
             */
            DispatchQueue.main.async {
                /*
                 `self.asset` has already changed! No point continuing because
                 another `newAsset` will come along in a moment.
                 */
                guard newAsset.avAsset == self.asset?.avAsset else { return }
                
                /*
                 Test whether the values of each of the keys we need have been
                 successfully loaded.
                 */
                for key in self.assetKeysRequiredToPlay {
                    var error: NSError?
                    
                    if newAsset.avAsset.statusOfValue(forKey: key, error: &error) == .failed {
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
                        
                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        PKLog.error(message)
                        self.post(event: PlayerEvent.Error(error: PlayerError.failedToLoadAssetFromKeys(rootError: error)))
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.avAsset.isPlayable {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable")
                    
                    PKLog.error(message)
                    self.post(event: PlayerEvent.Error(error: PlayerError.assetNotPlayable))
                    
                    return
                }
                
                /*
                 We can play this asset. Create a new `AVPlayerItem` and make
                 it our player's current item.
                 */
                let playerItem = AVPlayerItem(asset: newAsset.avAsset)
                playerItem.preferredPeakBitRate = newAsset.playerSettings.network.preferredPeakBitRate
                // set start position, position is valid and player is ready to play (will only work on change media).
                if self.startPosition > 0 && self.status == .readyToPlay {
                    self.currentPosition = self.startPosition
                    self.startPosition = 0
                }
                // add observers
                self.removeObservers()
                self.addObservers()
                // update the player with the new player item
                self.replaceCurrentItem(with: playerItem)
            }
        }
    }
}
