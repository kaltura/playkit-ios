//
//  PKCaptionsAssetResourceLoaderDelegate.swift
//  PlayKit
//
//  Created by Nilit Danan on 8/28/19.
//

import Foundation
import AVFoundation

class PKCaptionsAssetResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    /// The URL scheme for the m3u8 content.
    static let mainScheme = "mainm3u8"
    /// The URL scheme for the subtitle content.
    static let subtitlesScheme = "subtitlesm3u8"
    
    private let extM3UPrefix = "#EXTM3U"
    private let extXStreamInfPrefix = "#EXT-X-STREAM-INF"
    private let groupID = "subs"
    
    private var m3u8URL: URL
    private var externalSubtitles: [PKExternalSubtitle]
    private var m3u8String: String? = nil
    
    init(m3u8URL: URL, externalSubtitles: [PKExternalSubtitle]) {
        self.m3u8URL = m3u8URL
        self.externalSubtitles = externalSubtitles
        super.init()
    }
    
    func handleMainRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        let task = URLSession.shared.dataTask(with: m3u8URL) { [weak self] (data, response, error) in
            guard let self = self else { return }
            guard error == nil,
                let data = data else {
                    request.finishLoading(with: error)
                    return
            }
            self.processPlaylistWithData(data)
            self.finishRequestWithMainPlaylist(request)
        }
        task.resume()
        return true
    }
    
    func processPlaylistWithData(_ data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return }
        print(string)
        let lines = string.components(separatedBy: "\n")
        var newLines = [String]()
        var iterator = lines.makeIterator()
        while var line = iterator.next() {
            if line.hasPrefix(extXStreamInfPrefix) {
                line.append(",SUBTITLES=\"\(groupID)\"")
            }
            
            newLines.append(line)
            if line.hasPrefix(extM3UPrefix) {
                // Add external subtitle
                newLines.append(getSubtitlesEXT())
            }
        }
        m3u8String = newLines.joined(separator: "\n")
        print(m3u8String ?? "m3u8String is empty")
    }
    
    func finishRequestWithMainPlaylist(_ loadingRequest: AVAssetResourceLoadingRequest) {
        guard let mainm3u8 = m3u8String else {
            loadingRequest.finishLoading()
            return
        }
        let data = mainm3u8.data(using: .utf8)!
        loadingRequest.dataRequest?.respond(with: data)
        loadingRequest.finishLoading()
    }
    
    func handleSubtitles(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let subtitleId = loadingRequest.request.url?.path else { return false }
        
        let subtitleOfId = externalSubtitles.first { $0.id == subtitleId }
        guard let subtitle = subtitleOfId else { return false }
        
        let subtitlem3u8 = getSubtitlem3u8(forSubtitle: subtitle)
        print(subtitlem3u8)
        let data = subtitlem3u8.data(using: .utf8)!
        loadingRequest.dataRequest?.respond(with: data)
        loadingRequest.finishLoading()
        return true
    }
    
    func getSubtitlesEXT() -> String {
        var allSubtitles = ""
        for subtitle in externalSubtitles {
            allSubtitles.append("""
                #EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="\(groupID)",NAME="\(subtitle.name)",DEFAULT=\(subtitle.isDefault),FORCED=\(subtitle.forced),URI="subtitlesm3u8://\(subtitle.id)",LANGUAGE="\(subtitle.language)"
                """)
        }
        return allSubtitles
    }
    
    func getSubtitlem3u8(forSubtitle subtitle: PKExternalSubtitle) -> String {
        let durationString = String(format: "%.3f", subtitle.duration)
        let intDuration = Int(subtitle.duration)
        let subtitlem3u8 = """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-MEDIA-SEQUENCE:1
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXT-X-ALLOW-CACHE:NO
        #EXT-X-TARGETDURATION:\(intDuration)
        #EXTINF:\(durationString), no desc
        \(subtitle.vttURLString)
        #EXT-X-ENDLIST
        """
        return subtitlem3u8
    }
    
    // MARK: - AVAssetResourceLoaderDelegate
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let scheme = loadingRequest.request.url?.scheme else {
            return false
        }
        
        switch (scheme) {
        case PKCaptionsAssetResourceLoaderDelegate.mainScheme:
            return handleMainRequest(loadingRequest)
        case PKCaptionsAssetResourceLoaderDelegate.subtitlesScheme:
            return handleSubtitles(loadingRequest)
        default:
            return false
        }
    }
}

