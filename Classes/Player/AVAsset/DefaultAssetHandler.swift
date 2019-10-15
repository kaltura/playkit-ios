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
import PlayKitUtils

class DefaultAssetHandler: AssetHandler {
    
    /// The DispatchQueue to use for AVAssetResourceLoaderDelegate callbacks.
    fileprivate let resourceLoadingRequestQueue = DispatchQueue(label: "com.kaltura.playkit.resourcerequests")
    
    var assetLoaderDelegate = PKAssetResourceLoaderDelegate()
    var avAsset: AVURLAsset? {
        didSet {
            guard let asset = avAsset else { return }
            asset.resourceLoader.setDelegate(assetLoaderDelegate, queue: resourceLoadingRequestQueue)
        }
    }

    required init() {
        
    }
    
    private func replaceURL(_ url: URL, withScheme scheme: String) -> URL {
        var components = URLComponents.init(url: url, resolvingAgainstBaseURL: true)
        components?.scheme = scheme
        let newURL = components?.url
        
        return newURL ?? url
    }
    
    func build(from mediaSource: PKMediaSource, readyCallback: @escaping (Error?, AVURLAsset?) -> Void) {

        guard let contentUrl = mediaSource.contentUrl, var playbackUrl = mediaSource.playbackUrl else {
            PKLog.error("Invalid media: no url")
            readyCallback(AssetError.invalidContentUrl(nil), nil)
            return
        }
        
        let headers = ["User-Agent": PlayKitManager.userAgent]
        let cookies = HTTPCookieStorage.shared.cookies
        let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": headers, "AVURLAssetHTTPCookiesKey": cookies as Any] as [String : Any]
        
        if let localSource = mediaSource as? LocalMediaSource {
            PKLog.debug("Creating local asset")
            let asset = AVURLAsset(url: contentUrl, options: assetOptions)
            
            if #available(iOS 10.0, *) {
                let fpsAssetLoaderDelegate = FPSAssetLoaderDelegate.configureLocalPlay(asset: asset, storage: localSource.storage)
                self.assetLoaderDelegate.setDelegate(fpsAssetLoaderDelegate, forScheme: FPSAssetLoaderDelegate.customScheme)
            } else {
                // On earlier versions, this will only work for non-FairPlay content.
                PKLog.warning("Preparing local asset in iOS<10: \(contentUrl)")
            }
            
            self.avAsset = asset  
            readyCallback(nil, self.avAsset)
            return
        }

        // Set the custom scheme for the external subtitles, if exists.
        if let externalSubtitles = mediaSource.externalSubtitle, !externalSubtitles.isEmpty {
            let captionsAssetResourceLoaderDelegate = PKCaptionsAssetResourceLoaderDelegate(m3u8URL: playbackUrl,
                                                                                            externalSubtitles: externalSubtitles)
            self.assetLoaderDelegate.setDelegate(captionsAssetResourceLoaderDelegate,
                                                 forScheme: PKCaptionsAssetResourceLoaderDelegate.mainScheme)
            self.assetLoaderDelegate.setDelegate(captionsAssetResourceLoaderDelegate,
                                                 forScheme: PKCaptionsAssetResourceLoaderDelegate.subtitlesScheme)
            let customURL = replaceURL(playbackUrl, withScheme: PKCaptionsAssetResourceLoaderDelegate.mainScheme)
            playbackUrl = customURL
        }
        
        guard let drmData = mediaSource.drmData?.first else {
            PKLog.debug("Creating clear AVURLAsset")
            self.avAsset = AVURLAsset(url: playbackUrl, options: assetOptions)
            readyCallback(nil, self.avAsset)
            return
        }

        // FairPlay: only looking at the first DRMParams element.
        guard let fpsData = drmData as? FairPlayDRMParams else {
            PKLog.error("Unsupported DRM Data: \(drmData)")
            readyCallback(AssetError.invalidDrmScheme, nil)
            return
        }

        guard fpsData.fpsCertificate != nil else {
            PKLog.error("Missing FPS Certificate")
            readyCallback(AssetError.noFpsCertificate, nil)
            return
        }

        let asset = AVURLAsset(url: playbackUrl, options: assetOptions)
        
        let fpsAssetLoaderDelegate = FPSAssetLoaderDelegate.configureRemotePlay(asset: asset, drmData: fpsData)
        self.assetLoaderDelegate.setDelegate(fpsAssetLoaderDelegate, forScheme: FPSAssetLoaderDelegate.customScheme)
        
        self.avAsset = asset  
        readyCallback(nil, self.avAsset)
    }
}

