//
//  AVPlayerEngine+PKAssetSettings.swift
//  Pods
//
//  Created by Gal Orlanczyk on 19/06/2017.
//
//

import Foundation

extension AVPlayerEngine: PKDataUsageSettingsDelegate {
    
    func preferredPeakBitRateDidChange(newValue: TimeInterval) {
        self.currentItem?.preferredPeakBitRate = newValue
    }

    func forwardBufferModeDidChange(newMode: PKForwardBufferMode) {
        switch newMode {
        case .userEngagement, .duration, .durationCustom:
            switch newMode {
            case .userEngagement, .duration: self.forwardBufferLogic = ForwardBufferLogic()
            case .durationCustom:
                self.forwardBufferLogic = ForwardBufferLogic(customDurationDecisionRanges: self.assetSettings?.dataUsageSettings.durationModeCustomRanges)
            default: break
            }
        case .custom:
            self.forwardBufferLogic = nil
            if #available(iOS 10.0, *) {
                self.currentItem?.preferredForwardBufferDuration = self.assetSettings?.dataUsageSettings.preferredForwardBufferDuration ?? 0
            }
        case .none:
            self.forwardBufferLogic = nil
            if #available(iOS 10.0, *) {
                self.currentItem?.preferredForwardBufferDuration = 0
            }
        }
    }

    func canUseNetworkResourcesForLiveStreamingWhilePausedDidChange(newValue: Bool) {
        if #available(iOS 9.0, *) {
            self.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = newValue
        } else {
            PKLog.warning("can't set `canUseNetworkResourcesForLiveStreamingWhilePaused`, available for iOS 9 and above")
        }
    }
}
