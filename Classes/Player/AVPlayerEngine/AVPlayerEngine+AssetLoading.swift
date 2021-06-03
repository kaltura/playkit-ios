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
        // When changing asset, reset last timebase.
        self.lastTimebaseRate = 0
        // When changing media (loading new asset) we want to reset isFirstReady, in order to receive `CanPlay` & `LoadedMetadata` accurately.
        self.isFirstReady = true
        self.lastIndicatedBitrate = 0
        // Reset internalDuration in order to get an update of durationChanged.
        // If the previous media had the same duration as the new media, the durationChange was not fired.
        self.internalDuration = 0
        super.replaceCurrentItem(with: item)
    }
    
    func initializePlayerItem(_ newAsset: PKAsset) {
        /*
         We can play this asset. Create a new `AVPlayerItem` and make
         it our player's current item.
         */
        let playerItem = AVPlayerItem(asset: newAsset.avAsset)
        playerItem.preferredPeakBitRate = newAsset.playerSettings.network.preferredPeakBitRate

        if #available(iOS 10.0, tvOS 10.0, *) {
            playerItem.preferredForwardBufferDuration = newAsset.playerSettings.network.preferredForwardBufferDuration
        }

        // Add observers
        self.removeObservers()
        self.addObservers()
        // Update the player with the new player item
        self.replaceCurrentItem(with: playerItem)
    }
    
    
    func asynchronouslyLoadURLAsset(_ newAsset: PKAsset) {
        newAsset.status = .preparing
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
                        newAsset.status = .faild
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of its keys failed to load")
                        
                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        PKLog.error(message)
                        self.post(event: PlayerEvent.Error(error: PlayerError.failedToLoadAssetFromKeys(rootError: error)))
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.avAsset.isPlayable {
                    newAsset.status = .faild
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable")
                    
                    PKLog.error(message)
                    self.post(event: PlayerEvent.Error(error: PlayerError.assetNotPlayable))
                    
                    return
                }
                
                newAsset.status = .prepared
                
//                self.asynchronouslyLoadImagesTrack(newAsset)
                self.imageTrackLoader = ImagesTrackManager()
                self.imageTrackLoader?.prepareFor(asset: newAsset.avAsset)
                
                let initialLoad: [Double] = [0.1,
                                             0.12,
                                             0.15,
                                             0.17,
                                             0.2,
                                             0.22,
                                             0.23,
                                             0.25,
                                             0.27,
                                             0.3,
                                             0.32,
                                             0.33,
                                             0.36,
                                             0.38,
                                             0.4,
                                             0.41,
                                             0.43,
                                             0.45,
                                             0.47,
                                             0.5,
                                             0.522,
                                             0.53,
                                             0.56,
                                             0.59,
                                             0.6,
                                             0.62,
                                             0.65,
                                             0.67,
                                             0.7,
                                             0.73,
                                             0.75,
                                             0.77,
                                             0.8,
                                             0.82,
                                             0.84,
                                             0.845,
                                             0.85,
                                             0.88,
                                             0.9,
                                             0.95
                ]
                
                let timeArray: [CMTime] = initialLoad.map {
                    let time = (newAsset.avAsset.duration.seconds * $0).rounded(.down)
                    return CMTime.init(seconds: time, preferredTimescale: 1)
                }
                
                self.asynchronouslyLoadImagesTrack(time: timeArray)
                
                /*
                We can play this asset.
                If we are set to autoBuffer, create a new `AVPlayerItem` and make
                it our player's current item.
                */
                if newAsset.autoBuffer {
                    self.initializePlayerItem(newAsset)
                }
            }
        }
    }
}
