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
    
    private func printInvocationWarning(_ action: String) {
        PKLog.warning("Attempt to invoke \(action) on null instance of the player")
    }
    
    // ***************************** //
    // MARK: - PlayerEngine
    // ***************************** //
    
    var onEventBlock: ((PKEvent) -> Void)?
    
    public var startPosition: TimeInterval {
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

    var mediaConfig: MediaConfig?
    
    public var playbackType: String? {
        printInvocationWarning("\(#function)")
        return nil
    }
    
    func loadMedia(from mediaSource: PKMediaSource?, handler: AssetHandler) {
        printInvocationWarning("\(#function)")
    }
    
    func playFromLiveEdge() {
        printInvocationWarning("\(#function)")
    }
    
    public func updateTextTrackStyling(_ textTrackStyling: PKTextTrackStyling) {
        printInvocationWarning("\(#function)")
    }
    
    // ***************************** //
    // MARK: - BasicPlayer
    // ***************************** //
    
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
    
    /// Save view reference till prepare
    public weak var view: PlayerView?
    
    public var currentTime: TimeInterval {
        get {
            printInvocationWarning("\(#function)")
            return 0.0
        }
        set { printInvocationWarning("\(#function)") }
    }

    public var currentProgramTime: Date? {
        printInvocationWarning("\(#function)")
        return nil
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
    
    public var rate: Float {
        get {
            printInvocationWarning("\(#function)")
            return 0.0
        }
        set { printInvocationWarning("\(#function)") }
    }
    
    public var volume: Float {
        get {
            printInvocationWarning("\(#function)")
            return 0.0
        }
        set { printInvocationWarning("\(#function)") }
    }
    
    public var loadedTimeRanges: [PKTimeRange]? {
        printInvocationWarning("\(#function)")
        return nil
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
    
    func replay() {
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
    
    func prepare(_ mediaConfig: MediaConfig) {
        printInvocationWarning("\(#function)")
    }
    
    func startBuffering() {
        printInvocationWarning("\(#function)")
    }
    
    // ***************************** //
    // MARK: - Time Observation
    // ***************************** //
    
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
}
