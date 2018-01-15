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
import SwiftyJSON

@objc public class PKMediaSource: NSObject {
    
    @objc public enum MediaFormat: Int {
        case hls
        case wvm
        case mp4
        case mp3
        case unknown
        
        var fileExtension: String {
            get {
                switch self {
                case .hls: return "m3u8"
                case .wvm: return "wvm"
                case .mp4: return "mp4"
                case .mp3: return "mp3"
                case .unknown: return ""
                }
            }
        }
        
        static func mediaFormat(byfileExtension ext: String) -> MediaFormat {
            switch ext.lowercased() {
            case "m3u8": return .hls
            case "wvm": return .wvm
            case "mp4": return .mp4
            case "mp3": return .mp3
            case "mov": return .mp4
            case "m4a": return .mp3
            default: return .unknown
            }
        }
    }
    
    @objc public var id: String
    @objc public var contentUrl: URL? {
        didSet {
            let estimatedFormat = MediaFormat.mediaFormat(byfileExtension: self.fileExt)
            self.mediaFormat = self.mediaFormat != .unknown ? self.mediaFormat : estimatedFormat
        }
    }
    @objc public var mimeType: String?
    @objc public var drmData: [DRMParams]?
    @objc public var mediaFormat: MediaFormat = .unknown
    private var fileExt: String {
        return contentUrl?.pathExtension ?? ""
    }
    
    /// request params adapter, used to adapt the url.
    var contentRequestAdapter: PKRequestParamsAdapter?
    /// the playback url, if adapter exists uses it adapt otherwise uses the contentUrl.
    var playbackUrl: URL? {
        guard let contentUrl = self.contentUrl else { return nil }
        if let contentRequestAdapter = self.contentRequestAdapter {
            return contentRequestAdapter.adapt(requestParams: PKRequestParams(url: contentUrl, headers: nil)).url
        }
        return contentUrl
    }
    
    private let idKey: String = "id"
    private let contentUrlKey: String = "url"
    private let drmDataKey: String = "drmData"
    private let formatTypeKey: String = "sourceType"
    
    @objc public convenience init (id: String) {
        self.init(id, contentUrl: nil)
    }
    
    @objc public init(_ id: String, contentUrl: URL?, mimeType: String? = nil, drmData: [DRMParams]? = nil, mediaFormat: MediaFormat = .unknown) {
        self.id = id
        self.contentUrl = contentUrl
        self.drmData = drmData
        self.mediaFormat = mediaFormat == .unknown ? MediaFormat.mediaFormat(byfileExtension: contentUrl?.pathExtension ?? "") : mediaFormat
    }
    
    @objc public init(json: Any) {
        
        let sj = json as? JSON ?? JSON(json)
        
        self.id = sj[idKey].string ?? UUID().uuidString
        
        super.init()
        
        self.setContentUrl(sj[contentUrlKey].url)
        
        if let drmData = sj[drmDataKey].array {
            self.drmData = drmData.flatMap { DRMParams.fromJSON($0) }
        }
        
        if let st = sj[formatTypeKey].int, let mediaFormat = MediaFormat(rawValue: st) {
            self.mediaFormat = mediaFormat
        }
    }
    
    func setContentUrl(_ url: URL?) {
        self.contentUrl = url
    }
    
    @objc override public var description: String {
        get {
            return "id : \(self.id), url: \(String(describing: self.contentUrl))"
        }
    }
}
