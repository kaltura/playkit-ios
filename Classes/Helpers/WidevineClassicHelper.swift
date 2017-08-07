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

typealias LocalAssetRegistrationBlock = (Error?) -> Void
typealias LocalAssetStatusBlock = (Error?, TimeInterval, TimeInterval) -> Void

#if WIDEVINE_ENABLED
    import PlayKitWV
    
    /************************************************************/
    // MARK: - WidevineClassicError
    /************************************************************/
    
    enum WidevineClassicError: PKError {
        
        case invalidDRMData
        case missingWidevineFile
        
        static let domain = "com.kaltura.playkit.error.drm.widevine"
        
        var code: Int {
            switch self {
            case .invalidDRMData: return PKErrorCode.invalidDRMData
            case .missingWidevineFile: return PKErrorCode.missingWidevineFile
            }
        }
        
        var errorDescription: String {
            switch self {
            case.invalidDRMData: return "Couldn't extract license uri, invalid DRM data"
            case .missingWidevineFile: return "Couldn't register asset, Widevine file not found"
            }
        }
        
        var userInfo: [String : Any] {
            switch self {
            case .invalidDRMData: return [:]
            case .missingWidevineFile: return [:]
            }
        }
    }
    
    extension PKErrorDomain {
        @objc public static let Widevine = WidevineClassicError.domain
    }
    
    extension PKErrorCode {
        @objc(InvalidDRMData) public static let invalidDRMData = 6200
        @objc(MissingWidevineFile) public static let missingWidevineFile = 6201
    }
    
    /************************************************************/
    // MARK: - Widevine Classic
    /************************************************************/
    
    class WidevineClassicHelper {
        static func registerLocalAsset(_ assetUri: String!, mediaSource: PKMediaSource!, refresh: Bool, callback: @escaping LocalAssetRegistrationBlock) {
            PKLog.info("registerLocalAsset")
            
            WidevineClassicCDM.setEventBlock({ (event: KCDMEventType, data: [AnyHashable : Any]?) in
                switch event {
                case KCDMEvent_LicenseAcquired:
                    callback(nil)
                    break
                case KCDMEvent_FileNotFound:
                    callback(WidevineClassicError.missingWidevineFile.asNSError)
                    PKLog.error("Widevine file not found")
                    break
                case KCDMEvent_AssetCanPlay:
                    PKLog.info("KCDMEvent_AssetCanPlay")
                    break
                case KCDMEvent_AssetStopped:
                PKLog.info("KCDMEvent_AssetStopped")
                    break
                case KCDMEvent_AssetStatus:
                PKLog.info("KCDMEvent_AssetStatus")
                    break
                case KCDMEvent_LicenseFailed:
                    PKLog.info("KCDMEvent_LicenseFailed")
                    break
                case KCDMEvent_Unregistered:
                    PKLog.info("KCDMEvent_Unregistered")
                    break
                case KCDMEvent_Null:
                    PKLog.info("KCDMEvent_Null")
                    break
                default:
                    PKLog.debug("event::", event)
                }
            }, forAsset: assetUri)
            
            let (lu, e) = WidevineClassicHelper.extractLicenseUri(mediaSource: mediaSource)
            guard let licenseUri = lu else {
                PKLog.error("no licenseUri")
                if let error = e?.asNSError {
                    callback(error)
                }
                return
            }
            
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
        
        static func shouldRefreshAsset(_ assetUri: String, callback: @escaping (Bool) -> Void) {
            PKLog.info("shouldRefreshAsset")
            
            WidevineClassicCDM.setEventBlock({ (event: KCDMEventType, data: [AnyHashable : Any]?) in
                switch event {
                case KCDMEvent_AssetStopped:
                    PKLog.debug("KCDMEvent_AssetStopped")
                    callback(true)
                    break
                default:
                    PKLog.debug("event::", event)
                    break
                }
            }, forAsset: assetUri)
        }
        
        static func playLocalAsset(_ assetUri: String!, readyToPlay block: PlayKitWV.KCDMReadyToPlayBlock!) {
            PKLog.info("playLocalAsset")
            WidevineClassicCDM.playLocalAsset(assetUri, readyToPlay: block)
        }
        
        static func extractLicenseUri(mediaSource: PKMediaSource) -> (String?, PKError?) {
            guard let drmData = mediaSource.drmData?.first, let licenseUri = drmData.licenseUri  else {
                PKLog.error("Invalid DRM Data")
                return (nil, WidevineClassicError.invalidDRMData)
            }
            
            return (licenseUri.absoluteString, nil)
        }
    }
#else
    internal class WidevineClassicHelper {
        static let fatalMsg = "PlayKitWV is not contained on Podfile"
        
        static func registerLocalAsset(_ assetUri: String!, mediaSource: PKMediaSource!, refresh: Bool, callback: @escaping LocalAssetRegistrationBlock) {
            fatalError(fatalMsg)
        }
        
        static func unregisterAsset(_ assetUri: String!, callback: @escaping LocalAssetRegistrationBlock) {
            fatalError(fatalMsg)
        }
        
        static func checkAssetStatus(_ assetUri: String!, callback: @escaping LocalAssetStatusBlock) {
            fatalError(fatalMsg)
        }
        
        static func playAsset(_ assetUri: String!, withLicenseUri licenseUri: String!, readyToPlay block: (String?) -> Void) {
            fatalError(fatalMsg)
        }
        
        static func playLocalAsset(_ assetUri: String!, readyToPlay block: (String?) -> Void) {
            fatalError(fatalMsg)
        }
        
        static func shouldRefreshAsset(_ assetUri: String, callback: (Bool) -> Void) {
            fatalError(fatalMsg)
        }
        
        static func extractLicenseUri(mediaSource: PKMediaSource) -> (String?, PKError?) {
            fatalError(fatalMsg)
        }
    }
#endif
