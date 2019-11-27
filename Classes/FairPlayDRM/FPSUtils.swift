// ===================================================================================================
// Copyright (C) 2018 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation

public enum FPSError: Error {
    
    // License response errors
    case malformedServerResponse
    case noCKCInResponse
    case malformedCKCInResponse
    case serverError(_ error: Error, _ url: URL)
    case invalidLicenseDuration

    // License requests errors (can't generate request)
    case missingDRMParams
    case invalidKeyRequest
    case invalidMediaFormat
    case persistenceNotSupported
    case missingAssetId(_ url: URL)
}

protocol FPSLicenseRequest {
    func getSPC(cert: Data, id: String, shouldPersist: Bool, callback: @escaping (Data?, Error?) -> Void)
    func processContentKeyResponse(_ keyResponse: Data)
    func processContentKeyResponseError(_ error: Error?)
    func persistableContentKey(fromKeyVendorResponse keyVendorResponse: Data, options: [String : Any]?) throws -> Data
}

struct FPSParams {
    let cert: Data
    let url: URL
    
    init?(_ pkParams: FairPlayDRMParams?) {
        guard let params = pkParams else { return nil }
        guard let cert = params.fpsCertificate else { PKLog.error("Missing FPS certificate"); return nil }
        guard let url = params.licenseUri else { PKLog.error("Missing FPS license URL"); return nil }
        
        self.cert = cert
        self.url = url
    }
}

class FPSLicense: Codable {
    static let defaultExpiry: TimeInterval = 7*24*60*60
    let expiryDate: Date?
    var data: Data
    
    init(ckc: Data, duration: TimeInterval) {
        self.data = ckc
        self.expiryDate = Date(timeIntervalSinceNow: duration)
    }
    
    init(legacyData: Data) {
        self.data = legacyData
        self.expiryDate = nil
    }
    
    func isExpired() -> Bool {
        if let expiryDate = self.expiryDate {
            return Date() > expiryDate
        }
        return false
    }
}

extension LocalDataStore {
    
    func fpsKey(_ assetId: String) -> String {
        return assetId + ".fpskey"
    }
    
    func fpsKeyExists(_ assetId: String) -> Bool {
        return exists(key: fpsKey(assetId))
    }
    
    func loadFPSKey(_ assetId: String) throws -> FPSLicense {
        let obj = try load(key: fpsKey(assetId))
        
        if let license = try? JSONDecoder().decode(FPSLicense.self, from: obj) {
            return license
        } else {
            return FPSLicense(legacyData: obj)
        }
    }
    
    func saveFPSKey(_ assetId: String, _ value: FPSLicense) throws {
        let json = try JSONEncoder().encode(value)
        try save(key: fpsKey(assetId), value: json)
    }
    
    func removeFPSKey(_ assetId: String) throws {
        try remove(key: fpsKey(assetId))
    }
}


@objc public class FPSExpirationInfo: NSObject {
    
    @objc public let expirationDate: Date
    
    init(date: Date) {
        self.expirationDate = date
    }
    
    @objc public func isValid() -> Bool {
        return self.expirationDate > Date()
    }
}

class FPSUtils {
    
    static let skdUrlPattern = try! NSRegularExpression(pattern: "URI=\"skd://([\\w-]+)\"", options: [])
    
    static func findKeys(url: URL, isMaster: Bool, stopOnKey: Bool = true) -> [String]? {
        
        let playlist: String
        do {
            playlist = try String(contentsOf: url)
        } catch {
            PKLog.error("Can't read playlist at \(url)"); 
            return nil
        }
        
        var keys = [String]()
        var lists = [URL]()

        for line in playlist.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#EXT-X-SESSION-KEY") || trimmed.hasPrefix("#EXT-X-KEY") {
                // #EXT-X-SESSION-KEY:METHOD=SAMPLE-AES,URI="skd://entry-1_x14v3p06",KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1"
                // - OR -
                // #EXT-X-KEY:METHOD=SAMPLE-AES,URI="skd://entry-1_mq299xmb",KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1"
                guard let match = skdUrlPattern.firstMatch(in: line, options: [], range: NSMakeRange(0, line.count)) else { continue }
                if match.numberOfRanges < 2 { continue }
                
                // Extract the actual assetId from the match (see pattern).
                let assetIdRange = match.range(at: 1)
                let start = line.index(line.startIndex, offsetBy: assetIdRange.location)
                let end = line.index(line.startIndex, offsetBy: assetIdRange.location + assetIdRange.length - 1)
                let assetId = String(line[start...end])
                
                keys.append(assetId)
                if stopOnKey {
                    break
                }
            
            } else if isMaster && !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                // Look for chunk lists too
                guard let list = URL(string: trimmed, relativeTo: url) else {
                    PKLog.warning("Failed to create URL from \(url) and \(trimmed)")
                    continue
                }
                lists.append(list)
            }
        }
        
        if keys.count > 0 {
            return keys
        }
        
        if isMaster {
            // If we're in a master playlist and there are chunklists, call this function
            // recursively to find the keys in chunklists.
            for list in lists {
                if let keys = findKeys(url: list, isMaster: false) {
                    return keys
                }
            }
        }
        
        return nil
    }
        
    // Find the FairPlay assetId (also called keyId) for a downloaded asset.
    static func extractAssetId(at location: URL) -> String? {
        
        // Require a downloaded asset.
        if !"file".equals(location.scheme) && !"localhost".equals(location.host) {
            PKLog.error("Can only extract assetId from local resources")
            return nil
        }
        
        guard let keys = findKeys(url: location, isMaster: true) else {
            PKLog.error("No keys")
            return nil
        }
        
        return keys[0]  // if keys is not nil, there's at least one key.
    }
    
    static func removeOfflineLicense(for location: URL, dataStore: LocalDataStore) -> Bool {
        guard let id = extractAssetId(at: location) else {return false}
        
        do {
            try dataStore.removeFPSKey(id)
            return true
        } catch {
            return false
        }
    }
    
    static func getLicenseExpirationInfo(for location: URL, dataStore: LocalDataStore) -> FPSExpirationInfo? {
        guard let id = extractAssetId(at: location) else {return nil}
        guard let lic = try? dataStore.loadFPSKey(id), let date = lic.expiryDate else {
            return nil
        }
        
        return FPSExpirationInfo(date: date)
    }
}


// MARK: Utility
extension PKMediaSource {
    func isFairPlay() -> Bool {
        return mediaFormat == .hls && drmData?.first?.scheme == .fairplay
    }
    
    func fairPlayParams() throws -> FairPlayDRMParams {
        guard mediaFormat == .hls else { throw FPSError.invalidMediaFormat }
        guard let fpsParams = drmData?.first as? FairPlayDRMParams else { throw FPSError.missingDRMParams }
        guard fpsParams.fpsCertificate != nil && fpsParams.licenseUri != nil else { throw FPSError.missingDRMParams }
        return fpsParams
    }
    
    func isWidevineClassic() -> Bool {
        return mediaFormat == .wvm
    }
}

extension String {
    func equals(_ other: String?) -> Bool {
        
        guard let other = other else {
            return false // other is nil
        }
        
        return self == other
    }
}
