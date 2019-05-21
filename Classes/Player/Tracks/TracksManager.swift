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

public class TracksManager: NSObject {
    
    static let textOffDisplay: String = "Off"
    
    private var cea608CaptionsEnabled = false
    private var audioTracks: [Track]?
    private var textTracks: [Track]?
    
    public func handleTracks(item: AVPlayerItem?, cea608CaptionsEnabled: Bool, block: @escaping(_ tracks: PKTracks)->Void) {
        guard let playerItem = item else {
            PKLog.error("AVPlayerItem is nil")
            return
        }
        
        PKLog.verbose("item:: \(playerItem)")
        
        self.cea608CaptionsEnabled = cea608CaptionsEnabled
        self.audioTracks = nil
        self.textTracks = nil
        self.handleAudioTracks(item: playerItem)
        self.handleTextTracks(item: playerItem)
        
        
        if self.audioTracks != nil || self.textTracks != nil {
            PKLog.debug("audio tracks:: \(String(describing: self.audioTracks)), text tracks:: \(String(describing: self.textTracks))")
            block(PKTracks(audioTracks: self.audioTracks, textTracks: self.textTracks))
        } else {
            PKLog.debug("no audio/ text tracks")
        }
        
    }
    
    private func parseTrackId(_ string: String) -> (String, Int)? {
        guard let theRange = string.range(of: ":", options: .backwards), let i = Int(string[theRange.upperBound...]) else { return nil }
        return (String(string[..<theRange.lowerBound]), i)
    }
    
    @objc public func selectTrack(item: AVPlayerItem, trackId: String) -> Track? {
        PKLog.verbose("selectTrack")
        guard let tupleTrackId = parseTrackId(trackId) else { return nil }
        
        let type: String = tupleTrackId.0
        let index: Int = tupleTrackId.1
        
        if let audioTrack = self.audioTracks?.first(where: { $0.id == trackId }) {
            self.selectAudioTrack(item: item, index: index)
            return audioTrack
        } else if let textTrack = self.textTracks?.first(where: { $0.id == trackId }){
            self.selectTextTrack(item: item, type: type, index: index)
            return textTrack
        }
        return nil
    }
    
    @objc public func currentAudioTrack(item: AVPlayerItem) -> String? {
        if let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.audible), let option = item.selectedMediaOption(in: group) {
            return self.audioTracks?.filter{($0.title == option.displayName)}.first?.id
        }
        return nil
    }
    
    @objc public func currentTextTrack(item: AVPlayerItem) -> String? {
        if let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {
            var displayName: String
            if let option = item.selectedMediaOption(in: group) {
                displayName = option.displayName
            } else {
                displayName = TracksManager.textOffDisplay
            }
            return self.textTracks?.filter{($0.title == displayName)}.first?.id
        }
        return nil
    }
    
    private func handleAudioTracks(item: AVPlayerItem) {
        PKLog.verbose("handleAudioTracks")
        
        item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.audible)?.options.forEach { (option) in
            
            PKLog.verbose("option:: \(option)")
            
            var index = 0
            
            if let tracks = self.audioTracks {
                index = tracks.count
            } else {
                self.audioTracks = [Track]()
            }
            
            let trackId = "\(option.mediaType):\(String(index))"
            let track = Track(id: trackId, title: option.displayName, type: .audio, language: option.extendedLanguageTag)
            
            self.audioTracks?.append(track)
        }
    }
    
    private func selectAudioTrack(item: AVPlayerItem, index: Int) {
        PKLog.verbose("selectAudioTrack")
        
        let audioSelectionGroup = item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.audible)
        var trackIndex = 0
        audioSelectionGroup?.options.forEach { (option) in
            
            if trackIndex == index {
                PKLog.verbose("option:: \(option)")
                item.select(option, in: audioSelectionGroup!)
            }
            
            trackIndex += 1
        }
    }
    
    private func handleTextTracks(item: AVPlayerItem) {
        PKLog.verbose("handleTextTracks")
        
        var optionMediaType = ""
        item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible)?.options.forEach { (option) in
            
            PKLog.verbose("option:: \(option)")
            
            if !cea608CaptionsEnabled && option.mediaType.rawValue == AVMediaType.closedCaption.rawValue {
                return
            }
            
            var index = 0
            
            if let tracks = self.textTracks {
                index = tracks.count
            } else {
                self.textTracks = [Track]()
            }
            
            optionMediaType = option.mediaType.rawValue
            let trackId = "\(optionMediaType):\(String(index))"
            
            var title: String = option.displayName
            for metadata in option.commonMetadata {
                if metadata.commonKey == .commonKeyTitle {
                    if let metadataTitle = metadata.stringValue {
                        title = metadataTitle
                    }
                }
            }
            
            let track = Track(id: trackId, title: title, type: .text, language: option.extendedLanguageTag)
            
            self.textTracks?.append(track)
        }
        if optionMediaType != "" {
            self.textTracks?.insert(Track(id: "\(optionMediaType):-1", title: TracksManager.textOffDisplay, type: .text, language: nil), at: 0)
        }
    }
    
    private func selectTextTrack(item: AVPlayerItem, type: String, index: Int) {
        PKLog.verbose("selectTextTrack")
        
        let textSelectionGroup = item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible)
        
        if index == -1 {
            item.select(nil, in: textSelectionGroup!)
        } else {
            var trackIndex = 0
            textSelectionGroup?.options.forEach { (option) in
                
                if trackIndex == index {
                    PKLog.verbose("option:: \(option)")
                    
                    if option.mediaType.rawValue == type {
                        item.select(option, in: textSelectionGroup!)
                    }
                }
                
                trackIndex += 1
            }
        }
    }
}
