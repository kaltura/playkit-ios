//
//  TracksHandler.swift
//  Pods
//
//  Created by Eliza Sapir on 05/12/2016.
//
//

import Foundation
import AVFoundation

class TracksManager {
    let audioTypeKey: String = "soun"
    private var audioTracks: [Track]?
    private var textTracks: [Track]?
    
    public func handleTracks(item: AVPlayerItem?, block: @escaping(_ tracks: PKTracks)->Void) {
        guard let playerItem = item else {
            PKLog.error("AVPlayerItem is nil")
            return
        }
        
        PKLog.trace("item:: \(playerItem)")
        self.handleAudioTracks(item: playerItem)
        self.handleTextTracks(item: playerItem)
        
        
        if self.audioTracks != nil || self.textTracks != nil {
            PKLog.debug("audio tracks:: \(self.audioTracks), text tracks:: \(self.textTracks)")
            block(PKTracks(audioTracks: self.audioTracks, textTracks: self.textTracks))
        } else {
            PKLog.debug("no audio/ text tracks")
        }
        
    }
    
    public func selectTrack(item: AVPlayerItem, trackId: String) {
        PKLog.trace("selectTrack")
        
        let idArr : [String] = trackId.components(separatedBy: ":")
        let type: String = idArr[0]
        let index: Int = Int(idArr[1])!
        
        if type == audioTypeKey {
            self.selectAudioTrack(item: item, index: index)
        } else {
            self.selectTextTrack(item: item, type: type, index: index)
        }
    }
    
    private func handleAudioTracks(item: AVPlayerItem) {
        PKLog.trace("handleAudioTracks")
        
        item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicAudible)?.options.forEach { (option) in
            
            PKLog.trace("option:: \(option)")
            
            var index = 0
            
            if let tracks = self.audioTracks {
                index = tracks.count
            } else {
                self.audioTracks = [Track]()
            }
            
            let trackId = "\(option.mediaType):\(String(index))"
            let track = Track(id: trackId, title: option.displayName, language: option.extendedLanguageTag)
            
            self.audioTracks?.append(track)
        }
    }
    
    private func selectAudioTrack(item: AVPlayerItem, index: Int) {
        PKLog.trace("selectAudioTrack")
        
        let audioSelectionGroup = item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicAudible)
        audioSelectionGroup?.options.forEach { (option) in
            var trackIndex = 0
            
            if trackIndex == index {
                PKLog.trace("option:: \(option)")
                item.select(option, in: audioSelectionGroup!)
            }
            
            trackIndex += 1
        }
    }
    
    private func handleTextTracks(item: AVPlayerItem) {
        PKLog.trace("handleTextTracks")
        
        item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicLegible)?.options.forEach { (option) in
            
            PKLog.trace("option:: \(option)")
            
            var index = 0
            
            if let tracks = self.textTracks {
                index = tracks.count
            } else {
                self.textTracks = [Track]()
            }
            
            let trackId = "\(option.mediaType):\(String(index))"
            let track = Track(id: trackId, title: option.displayName, language: option.extendedLanguageTag)
            
            self.textTracks?.append(track)
        }
    }
    
    private func selectTextTrack(item: AVPlayerItem, type: String, index: Int) {
        PKLog.trace("selectTextTrack")
        
        let textSelectionGroup = item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicLegible)
        textSelectionGroup?.options.forEach { (option) in
            var trackIndex = 0
            
            if trackIndex == index {
                PKLog.trace("option:: \(option)")
                
                if option.mediaType == type {
                    item.select(option, in: textSelectionGroup!)
                }
            }
            
            trackIndex += 1
        }
    }
    
    init() {}
}
