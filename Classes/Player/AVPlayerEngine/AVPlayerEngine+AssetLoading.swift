//
//  AVPlayerEngine+AssetLoading.swift
//  Pods
//
//  Created by Gal Orlanczyk on 07/03/2017.
//
//

import Foundation
import AVFoundation

extension AVPlayerEngine {
    
    override func replaceCurrentItem(with item: AVPlayerItem?) {
        // When changing media (loading new asset) we want to reset isFirstReady in order to receive `CanPlay` & `LoadedMetadata` accuratly.
        self.isFirstReady = true
        super.replaceCurrentItem(with: item)
    }
    
    func asynchronouslyLoadURLAsset(_ newAsset: AVAsset) {
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        newAsset.loadValuesAsynchronously(forKeys: self.assetKeysRequiredToPlay) {
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
                guard newAsset == self.asset else { return }
                
                /*
                 Test whether the values of each of the keys we need have been
                 successfully loaded.
                 */
                for key in self.assetKeysRequiredToPlay {
                    var error: NSError?
                    
                    if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
                        
                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        PKLog.error(message)
                        self.post(event: PlayerEvent.Error(error: PlayerError.failedToLoadAssetFromKeys(rootError: error)))
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.isPlayable {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable")
                    
                    PKLog.error(message)
                    self.post(event: PlayerEvent.Error(error: PlayerError.assetNotPlayable))
                    
                    return
                }
                    
                /*
                 We can play this asset. Create a new `AVPlayerItem` and make
                 it our player's current item.
                 */
                self.replaceCurrentItem(with: AVPlayerItem(asset: newAsset))
                self.removeObservers()
                self.addObservers()
            }
        }
    }
}
