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
    private var audioTracks: [Track]?
    private var textTracks: [Track]?
    
    public func handleTracks(item: AVPlayerItem?) {
        guard let playerItem = item else {
            PKLog.error("AVPlayerItem is nil")
            return
        }
        
        PKLog.trace("item:: \(playerItem)")
        self.handleAudioTracks(item: playerItem)
        self.handleTextTracks(item: playerItem)
        
    }
    
    public func selectTrack(item: AVPlayerItem, index: Int, type: String) {
        if type == "sbtl" {
            self.selectTextTrack(item: item, trackId: index)
        } else {
            self.selectAudioTrack(item: item, trackId: index)
        }
    }
    
    private func handleAudioTracks(item: AVPlayerItem) {
        item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicAudible)?.options.forEach { (option) in
            
            PKLog.trace("option:: \(option)")
            
            var index = 0
            
            if var tracks = self.audioTracks {
                index = tracks.count
            } else {
                self.audioTracks = [Track]()
            }
            
            let track = Track(index: index, type: option.mediaType, title: option.displayName, language: option.extendedLanguageTag)
            
            self.audioTracks?.append(track)
        }
    }
    
    private func selectAudioTrack(item: AVPlayerItem, trackId: Int) {
        let audioSelectionGroup = item.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicAudible)
        audioSelectionGroup?.options.forEach { (option) in
            var index = 0
            
            if index == trackId {
                PKLog.trace("option:: \(option)")
                item.select(option, in: audioSelectionGroup!)
            }
            //TODO:: change syntax
            index = index + 1
        }
    }
    
    private func handleTextTracks(item: AVPlayerItem) {
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
            
            let track = Track(index: index, type: option.mediaType, title: option.displayName, language: option.extendedLanguageTag)
            
            if option.hasMediaCharacteristic(AVMediaCharacteristicContainsOnlyForcedSubtitles) {
                //subtitles
                subtitles.append(track)
            } else  {
                //closed captions
                captions.append(track)
            }
            
            if subtitles.count > 0 {
                self.textTracks = subtitles
            } else if captions.count > 0 {
                self.textTracks = captions
            }
            
            self.textTracks = nil
        }
    }
    
    private func selectTextTrack(item: AVPlayerItem, trackId: Int) {
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
            //TODO:: change syntax
            index = index + 1
        }
    }
    
    init() {}
}
