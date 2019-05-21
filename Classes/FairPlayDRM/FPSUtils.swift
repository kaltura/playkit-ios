// ===================================================================================================
// Copyright (C) 2018 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

//
//  FPSUtils.swift
//  PlayKit
//
//  Created by Noam Tamim on 30/05/2018.
//

import Foundation
import SwiftyJSON

enum FPSError: Error {
    case emptyServerResponse
    case failedToConvertServerResponse
    case malformedServerResponse
    case noCKCInResponse
    case malformedCKCInResponse
    case missingDRMParams
    case invalidKeyRequest
    case invalidMediaFormat
    case persistenceNotSupported
}

enum FPSInternalError: Error {
    case unknownAssetKeyId
    case unknownAssetMode
    case invalidAssetKeyId
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
    
    init(jsonResponse: Data?) throws {
        guard let data = jsonResponse else {
            throw FPSError.emptyServerResponse
        }
        
        guard let json = try? JSON(data: data, options: []) else {
            throw FPSError.failedToConvertServerResponse
        }
        
        guard let b64CKC = json["ckc"].string else {
            throw FPSError.noCKCInResponse
        }
        
        guard let ckc = Data(base64Encoded: b64CKC) else {
            throw FPSError.malformedCKCInResponse
        }
        
        let offlineExpiry = json["persistence_duration"].double ?? FPSLicense.defaultExpiry
        
        if ckc.count == 0 {
            throw FPSError.malformedCKCInResponse
        }
        
        self.data = ckc
        self.expiryDate = Date(timeIntervalSinceNow: offlineExpiry)
    }
    
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
    
    public let expirationDate: Date
    
    init(date: Date) {
        self.expirationDate = date
    }
    
    public func isValid() -> Bool {
        return self.expirationDate > Date()
    }
}

class FPSUtils {
    
    static let skdUrlPattern = try! NSRegularExpression(pattern: "URI=\"skd://([\\w-]+)\"", options: [])
    
    static func extractAssetId(at location: URL) -> String? {
        // Master should have the following line:
        // #EXT-X-SESSION-KEY:METHOD=SAMPLE-AES,URI="skd://entry-1_x14v3p06",KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1"
        // The following code looks for the first line with "EXT-X-SESSION-KEY" tag.
        guard let master = try? String(contentsOf: location) else { 
            PKLog.error("Can't read master playlist \(location)"); 
            return nil 
        }
        
        let lines = master.components(separatedBy: .newlines)
        var assetId: String? = nil
        
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("#EXT-X-SESSION-KEY") {
                guard let match = skdUrlPattern.firstMatch(in: line, options: [], range: NSMakeRange(0, line.count)) else { continue }
                if match.numberOfRanges < 2 { continue }
                let assetIdRange = match.range(at: 1)
                let start = line.index(line.startIndex, offsetBy: assetIdRange.location)
                let end = line.index(line.startIndex, offsetBy: assetIdRange.location + assetIdRange.length - 1)
                assetId = String(line[start...end])
                
                return assetId
            }
        }
        
        return nil
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
