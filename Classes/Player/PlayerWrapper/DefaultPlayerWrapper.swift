// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

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
    
    var onEventBlock: ((PKEvent) -> Void)?

    var mediaConfig: MediaConfig?
    
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
    
    public var loadedTimeRanges: [PKTimeRange]? {
        printInvocationWarning("\(#function)")
        return nil
    }
    
    /// Save view reference till prepare
    public weak var view: PlayerView?
    
    public var rate: Float {
        get {
            printInvocationWarning("\(#function)")
            return 0.0
        }
        set { printInvocationWarning("\(#function)") }
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
    
    func loadMedia(from mediaSource: PKMediaSource?, handler: AssetHandler) {
        printInvocationWarning("\(#function)")
    }
    
    func prepare(_ mediaConfig: MediaConfig) {
        printInvocationWarning("\(#function)")
    }
    
    func addPeriodicObserver(interval: TimeInterval, observeOn dispatchQueue: DispatchQueue?, using block: @escaping (TimeInterval) -> Void) -> UUID {
        printInvocationWarning("\(#function)")
        return UUID()
    }
    
    func addBoundaryObserver(boundaries: [PKBoundary], observeOn dispatchQueue: DispatchQueue?, using block: @escaping (TimeInterval, Double) -> Void) -> UUID {
        printInvocationWarning("\(#function)")
        return UUID()
    }
    
    func removePeriodicObserver(_ token: UUID) {
        printInvocationWarning("\(#function)")
    }
    
    func removeBoundaryObserver(_ token: UUID) {
        printInvocationWarning("\(#function)")
    }
    
    func removePeriodicObservers() {
        printInvocationWarning("\(#function)")
    }
    
    func removeBoundaryObservers() {
        printInvocationWarning("\(#function)")
    }
    
    private func printInvocationWarning(_ action: String) {
        PKLog.warning("Attempt to invoke \(action) on null instance of the player")
    }
}
