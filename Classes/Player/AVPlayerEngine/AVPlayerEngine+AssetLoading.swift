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
    
    override func replaceCurrentItem(with item: AVPlayerItem?) {
        // when changing asset reset last timebase
        self.lastTimebaseRate = 0
        // When changing media (loading new asset) we want to reset isFirstReady in order to receive `CanPlay` & `LoadedMetadata` accuratly.
        self.isFirstReady = true
        
        self.timePlayed = 0
        self.lastObservedTime = 0
        
        super.replaceCurrentItem(with: item)
    }
    
    func asynchronouslyLoadURLAsset(_ pkAsset: PKAsset) {
        
        let avAsset = pkAsset.avAsset
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        avAsset.loadValuesAsynchronously(forKeys: self.assetKeysRequiredToPlay) {
            /*
             The asset invokes its completion handler on an arbitrary queue.
             To avoid multiple threads using our internal state at the same time
             we'll elect to use the main thread at all times, let's dispatch
             our handler to the main queue.
             */
            DispatchQueue.main.async {
                /*
                 `self.asset` has already changed! No point continuing because
                 another `avAsset` will come along in a moment.
                 */
                guard avAsset == self.asset?.avAsset else { return }
                
                /*
                 Test whether the values of each of the keys we need have been
                 successfully loaded.
                 */
                for key in self.assetKeysRequiredToPlay {
                    var error: NSError?
                    
                    if avAsset.statusOfValue(forKey: key, error: &error) == .failed {
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
                        
                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        PKLog.error(message)
                        self.post(event: PlayerEvent.Error(error: PlayerError.failedToLoadAssetFromKeys(rootError: error)))
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !avAsset.isPlayable {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable")
                    
                    PKLog.error(message)
                    self.post(event: PlayerEvent.Error(error: PlayerError.assetNotPlayable))
                    
                    return
                }
                
                // set asset settings property (will also set the delegate to receive updates on changes)
                self.assetSettings = pkAsset.settings
                
                // We can play this asset. Create a new `AVPlayerItem` and make
                // it our player's current item.
                self.replaceCurrentItem(with: AVPlayerItem(pkAsset: pkAsset))
                self.removeObservers()
                self.addObservers()
            }
        }
    }
}
