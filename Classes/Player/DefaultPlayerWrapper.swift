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

class DefaultPlayerWrapper: NSObject, PlayerEngine {
    /// Fired when some event is triggred.
    var onEventBlock: ((PKEvent) -> Void)? {
        get {
            printInvocationWarning("\(#function)")
            return nil
        }
        set { printInvocationWarning("\(#function)") }
    }

    public var duration: Double {
        printInvocationWarning("\(#function)")
        return 0.0
    }
    
    public var currentState: PlayerState {
        printInvocationWarning("\(#function)")
        return .idle
    }
    
    public var isPlaying: Bool {
        printInvocationWarning("\(#function)")
        return false
    }
    
    public var currentTime: TimeInterval {
        get {
            printInvocationWarning("\(#function)")
            return 0.0
        }
        set { printInvocationWarning("\(#function)") }
    }

    public var currentPosition: TimeInterval {
        get {
            printInvocationWarning("\(#function)")
            return 0.0
        }
        set { printInvocationWarning("\(#function)") }
    }
    
    public var startPosition: TimeInterval {
        get {
            printInvocationWarning("\(#function)")
            return 0.0
        }
        set { printInvocationWarning("\(#function)") }
    }
    
    public var currentAudioTrack: String? {
        get {
            printInvocationWarning("\(#function)")
            return nil
        }
        set { printInvocationWarning("\(#function)") }
    }
        
    public var currentTextTrack: String? {
        get {
            printInvocationWarning("\(#function)")
            return nil
        }
        set { printInvocationWarning("\(#function)") }
    }
    
    public weak var view: PlayerView? {
        get {
            printInvocationWarning("\(#function)")
            return nil
        }
        set { printInvocationWarning("\(#function)") }
    }
    
    public var rate: Float {
        printInvocationWarning("\(#function)")
        return 0.0
    }
    
    func play() {
        printInvocationWarning("\(#function)")
    }
    
    func pause() {
        printInvocationWarning("\(#function)")
    }
    
    func resume() {
        printInvocationWarning("\(#function)")
    }
    
    func stop() {
        printInvocationWarning("\(#function)")
    }
    
    func seek(to time: TimeInterval) {
        printInvocationWarning("\(#function)")
    }
    
    func selectTrack(trackId: String) {
        printInvocationWarning("\(#function)")
    }
    
    func destroy() {
        printInvocationWarning("\(#function)")
    }
    
    func loadMedia(from mediaSource: PKMediaSource?, handlerType: AssetHandler.Type) {
        printInvocationWarning("\(#function)")
    }
    
    func prepare(_ MediaConfig: MediaConfig) {
        printInvocationWarning("\(#function)")
    }
    
    private func printInvocationWarning(_ action: String) {
        PKLog.warning("Attempt to invoke \(action) on null instance of the player")
    }
}
