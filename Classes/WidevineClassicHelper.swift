//
//  WidevineClassicHandler.swift
//  Pods
//
//  Created by Eliza Sapir on 19/02/2017.
//
//

import Foundation

#if WIDEVINE_ENABLED
    import PlayKitWV
    
    typealias LocalAssetRegistrationBlock = (Error?) -> Void
    typealias LocalAssetStatusBlock = (Error?, _ expiryTime: TimeInterval, _ availableTime: TimeInterval) -> Void
    
    internal class WidevineClassicHelper {
        static func registerLocalAsset(_ assetUri: String!, licenseUri licenseUri: String!, refresh: Bool, callback: @escaping LocalAssetRegistrationBlock) {
            PKLog.info("registerLocalAsset")
            
            WidevineClassicCDM.setEventBlock({ (event: KCDMEventType, data: [AnyHashable : Any]?) in
                switch event {
                case KCDMEvent_LicenseAcquired:
                    callback(nil)
                    break
                case KCDMEvent_FileNotFound:
                    // TODO:: Fix error
                    callback(NSError(domain: "widevine", code: -1, userInfo: nil))
                    PKLog.error("Widevine file not found")
                    break
                default:
                    PKLog.debug("event::", event)
                    break
                }
            }, forAsset: assetUri)
            
            if refresh {
                WidevineClassicCDM.renewAsset(assetUri, withLicenseUri: licenseUri)
            } else {
                WidevineClassicCDM.registerLocalAsset(assetUri, withLicenseUri: licenseUri)
            }
        }
        
        static func unregisterAsset(_ assetUri: String!, callback: @escaping LocalAssetRegistrationBlock) {
            PKLog.info("unregisterAsset")
            
            WidevineClassicCDM.setEventBlock({ (event: KCDMEventType, data: [AnyHashable : Any]?) in
                switch event {
                case KCDMEvent_Unregistered:
                    callback(nil)
                    break
                default:
                    PKLog.debug("event::", event)
                    break
                }
            }, forAsset: assetUri)
            
            WidevineClassicCDM.unregisterAsset(assetUri)
        }
        
        static func checkAssetStatus(_ assetUri: String!, callback: @escaping LocalAssetStatusBlock) {
            PKLog.info("checkAssetStatus")
            
            WidevineClassicCDM.setEventBlock({ (event: KCDMEventType, data: [AnyHashable : Any]?) in
                switch event {
                case KCDMEvent_AssetStatus:
                    callback(nil, WidevineClassicCDM.wvLicenseTimeRemaning(data), WidevineClassicCDM.wvPurchaseTimeRemaning(data))
                    break
                default:
                    PKLog.debug("event::", event)
                    break
                }
            }, forAsset: assetUri)
            
            WidevineClassicCDM.checkAssetStatus(assetUri)
        }
        
        static func playAsset(_ assetUri: String!, withLicenseUri licenseUri: String!, readyToPlay block: PlayKitWV.KCDMReadyToPlayBlock!) {
            PKLog.info("playAsset")
            WidevineClassicCDM.playAsset(assetUri, withLicenseUri: licenseUri, readyToPlay: block)
        }
        
        static func playLocalAsset(_ assetUri: String!, readyToPlay block: PlayKitWV.KCDMReadyToPlayBlock!) {
            PKLog.info("playLocalAsset")
            WidevineClassicCDM.playLocalAsset(assetUri, readyToPlay: block)
        }
    }
#else
    internal class WidevineClassicHelper {
        static let fatalMsg = "PlayKitWV is not contained on Podfile"
        
        static func registerLocalAsset(_ assetUri: String!, licenseUri licenseUri: String!, refresh: Bool, callback: Any) {
            fatalError(self.fatalMsg)
        }
        
        static func unregisterAsset(_ assetUri: String!, callback: Any) {
            fatalError(fatalMsg)
        }
        
        static func checkAssetStatus(_ assetUri: String!, callback: Any) {
            fatalError(fatalMsg)
        }
        
        static func playAsset(_ assetUri: String!, withLicenseUri licenseUri: String!, readyToPlay block: Any) {
            fatalError(fatalMsg)
        }
        
        static func playLocalAsset(_ assetUri: String!, readyToPlay block: Any) {
            fatalError(fatalMsg)
        }
    }
#endif
