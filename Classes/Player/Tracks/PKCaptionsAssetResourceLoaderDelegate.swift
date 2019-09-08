//
//  PKCaptionsAssetResourceLoaderDelegate.swift
//  PlayKit
//
//  Created by Nilit Danan on 8/28/19.
//

import Foundation
import AVFoundation

private struct PlaylistTags {
    static let extXStreamInf = "#EXT-X-STREAM-INF"
    static let extXMedia = "#EXT-X-MEDIA"
    static let extXIFrameStreamInf = "#EXT-X-I-FRAME-STREAM-INF"
}

class PKCaptionsAssetResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    /// The URL scheme for the m3u8 content.
    static let mainScheme = "mainm3u8"
    /// The URL scheme for the subtitle content.
    static let subtitlesScheme = "subtitlesm3u8"
    
    private let uriPrefix = "URI="
    
    private var extXStreamInfPrefixIndexes: [Int] = []
    private var hasInternalSubtitles: Bool = false
    
    private var m3u8URL: URL
    private var externalSubtitles: [PKExternalSubtitle]
    private var m3u8String: String? = nil
    
    init(m3u8URL: URL, externalSubtitles: [PKExternalSubtitle]) {
        self.m3u8URL = m3u8URL
        self.externalSubtitles = externalSubtitles
        super.init()
    }
    
    private func handleMainRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
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
    
    private func absoluteURI(for uri: String) -> String {
        let urlComponents = URLComponents(string: uri)
        
        guard (urlComponents?.scheme) == nil else {
            // If we have a scheme return as is. It's not a relative one.
            return uri
        }
        
        let newURL = urlComponents?.url(relativeTo: m3u8URL)
        return newURL?.absoluteString ?? uri
    }
    
    private func processPlaylistWithData(_ data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return }
        PKLog.debug("Received m3u8:\n\(string)")
        let lines = string.components(separatedBy: "\n")
        var newLines = [String]()
        var iterator = lines.makeIterator()
        while var line = iterator.next() {
            
            // Check and save the #EXT-X-STREAM-INF indexes
            if line.hasPrefix(PlaylistTags.extXStreamInf) {
                extXStreamInfPrefixIndexes.append(newLines.count)
            }
            
            // Check if we have internal subtitles
            if line.hasPrefix(PlaylistTags.extXMedia) {
                if line.contains("TYPE=SUBTITLES") {
                    hasInternalSubtitles = true
                }
            }
            
            // Check all URIs, if they are relative, change them to absolute.
            var urlString: String = ""
            if line.hasPrefix(PlaylistTags.extXMedia) || line.hasPrefix(PlaylistTags.extXIFrameStreamInf) {
                let components = line.split(separator: Character(","))
                if let uriIndex = components.firstIndex(where: { $0.hasPrefix(uriPrefix) }) {
                    let component = components[uriIndex]
                    urlString = component.replacingOccurrences(of: uriPrefix, with: "")
                }
            } else if !line.isEmpty, !line.hasPrefix("#") {
                // If the line doesn't start with '#', and not an empty line, it's a URI
                urlString = line
            }
            
            // If we found a url, replace it with an absolute url if it's a relative one.
            if !urlString.isEmpty {
                let absoluteURLSring = absoluteURI(for: urlString)
                
                // Replace URI
                line = line.replacingOccurrences(of: urlString, with: absoluteURLSring)
            }
            
            newLines.append(line)
        }
        
        // If there are no internal subtitles:
        // Add the subtitles a row above the #EXT-X-STREAM-INF tag.
        // Add the SUBTITLES=<groupID> to all the #EXT-X-STREAM-INF tags.
        if !hasInternalSubtitles {
            for index in extXStreamInfPrefixIndexes {
                newLines[index].append(",SUBTITLES=\"\(PKExternalSubtitle.groupID)\"")
            }
            
            // Add external subtitle before the first X-Stream-Inf
            if let firstIndex = extXStreamInfPrefixIndexes.first {
                newLines.insert(getSubtitlesEXT(), at: firstIndex)
            }
        }
        
        m3u8String = newLines.joined(separator: "\n")
        PKLog.debug("Updated m3u8:\n\(m3u8String ?? "m3u8 is empty")")
    }
    
    private func finishRequestWithMainPlaylist(_ loadingRequest: AVAssetResourceLoadingRequest) {
        guard let mainm3u8 = m3u8String else {
            loadingRequest.finishLoading()
            return
        }
        let data = mainm3u8.data(using: .utf8)!
        loadingRequest.dataRequest?.respond(with: data)
        loadingRequest.finishLoading()
    }
    
    private func handleSubtitles(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
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
    
    private func getSubtitlesEXT() -> String {
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

