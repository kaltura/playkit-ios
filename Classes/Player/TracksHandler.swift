//
//  TracksHandler.swift
//  Pods
//
//  Created by Eliza Sapir on 05/12/2016.
//
//

import Foundation
import AVFoundation

public class TracksHandler {
    let textTypeKey: String = "sbtl"
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
        
        if block != nil {
            if self.audioTracks != nil || self.textTracks != nil {
                PKLog.debug("audio tracks:: \(self.audioTracks), text tracks:: \(self.textTracks)")
                block(PKTracks(audioTracks: self.audioTracks, textTracks: self.textTracks))
            } else {
                PKLog.debug("no audio/ text tracks")
            }
        }
    }
    
    public func selectTrack(item: AVPlayerItem, trackId: String) {
        PKLog.trace("selectTrack")
        
        let idArr : [String] = trackId.components(separatedBy: ":")
        let type: String = idArr[0]
        let index: Int = Int(idArr[1])!
        
        if type == textTypeKey {
            self.selectTextTrack(item: item, trackId: index)
        } else {
            self.selectAudioTrack(item: item, trackId: index)
        }
    }
    
    private func handleAudioTracks(item: AVPlayerItem) {
        PKLog.trace("handleAudioTracks")
        
        item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicAudible)?.options.forEach { (option) in
            
            PKLog.trace("option:: \(option)")
            
            var index = 0
            
            if var tracks = self.audioTracks {
                index = tracks.count
            } else {
                self.audioTracks = [Track]()
            }
            
            var trackId = "\(option.mediaType):\(String(index))"
            let track = Track(id: trackId, title: option.displayName, language: option.extendedLanguageTag)
            
            self.audioTracks?.append(track)
        }
    }
    
    private func selectAudioTrack(item: AVPlayerItem, trackId: Int) {
        PKLog.trace("selectAudioTrack")
        
        let audioSelectionGroup = item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicAudible)
        audioSelectionGroup?.options.forEach { (option) in
            var index = 0
            
            if index == trackId {
                PKLog.trace("option:: \(option)")
                item.select(option, in: audioSelectionGroup!)
            }

            index = index + 1
        }
    }
    
    private func handleTextTracks(item: AVPlayerItem) {
        PKLog.trace("handleTextTracks")
        
        var captions = [Track]()
        var subtitles = [Track]()
        item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicLegible)?.options.forEach { (option) in
            
            PKLog.trace("option:: \(option)")

            var index = 0
            
            if var tracks = self.textTracks {
                index = tracks.count
            } else {
                self.textTracks = [Track]()
            }
            
            var trackId = "\(option.mediaType):\(String(index))"
            let track = Track(id: trackId, title: option.displayName, language: option.extendedLanguageTag)
            
            if option.hasMediaCharacteristic(AVMediaCharacteristicContainsOnlyForcedSubtitles) {
                //subtitles
                subtitles.append(track)
            } else  {
                //closed captions
                captions.append(track)
            }
        }
        
        // Only one text track will be chosen
        if subtitles.count > 0 {
            self.textTracks = subtitles
        } else if captions.count > 0 {
            self.textTracks = captions
        } else {
            self.textTracks = nil
        }
    }
    
    private func selectTextTrack(item: AVPlayerItem, trackId: Int) {
        PKLog.trace("selectTextTrack")
        
        let textSelectionGroup = item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicLegible)
        textSelectionGroup?.options.forEach { (option) in
            var index = 0
            
            if index == trackId {
                PKLog.trace("option:: \(option)")
                // Prefer Subtitles
                if option.hasMediaCharacteristic(AVMediaCharacteristicContainsOnlyForcedSubtitles) {
                    //subtitles
                    item.select(option, in: textSelectionGroup!)
                } else  {
                    //closed captions
                    item.select(option, in: textSelectionGroup!)
                }
            }
            
            index = index + 1
        }
    }
    
    init() {}
}
