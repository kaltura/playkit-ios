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
        PKLog.debug("Received m3u8:\n\(string)")
        let lines = string.components(separatedBy: "\n")
        var newLines = [String]()
        var iterator = lines.makeIterator()
        while var line = iterator.next() {
            if line.hasPrefix(extXStreamInfPrefix) {
                line.append(",SUBTITLES=\"\(PKExternalSubtitle.groupID)\"")
            }
            
            newLines.append(line)
            if line.hasPrefix(extM3UPrefix) {
                // Add external subtitle
                newLines.append(getSubtitlesEXT())
            }
        }
        m3u8String = newLines.joined(separator: "\n")
        PKLog.debug("Updated m3u8:\n\(m3u8String ?? "m3u8 is empty")")
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
        let stringURL = loadingRequest.request.url?.absoluteString
        let stringToRemove = PKCaptionsAssetResourceLoaderDelegate.subtitlesScheme + "://"
        guard let subtitleId = stringURL?.replacingOccurrences(of: stringToRemove, with: "") else { return false }
        
        let subtitleOfId = externalSubtitles.first { $0.id == subtitleId }
        guard let subtitle = subtitleOfId else { return false }
        
        let m3u8Playlist = subtitle.buildM3u8Playlist()
        
        PKLog.debug("Subtitle (\(subtitleId)) m3u8:\n\(m3u8Playlist)")
        let data = m3u8Playlist.data(using: .utf8)!
        loadingRequest.dataRequest?.respond(with: data)
        loadingRequest.finishLoading()
        return true
    }
    
    func getSubtitlesEXT() -> String {
        var allSubtitles = ""
        for subtitle in externalSubtitles {
            let masterLine = subtitle.buildMasterLine()
            allSubtitles.append(masterLine)
        }
        return allSubtitles
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

