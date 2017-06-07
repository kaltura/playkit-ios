//
//  File.swift
//  PlayKit
//
//  Created by Gal Orlanczyk on 07/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import SwiftyJSON
import CoreMedia
@testable import PlayKit

protocol MockableOTTAnalyticsPluginProtocol {
    var finishedHandling: Bool { get set }
    var invocationCount: OTTAnalyticsPluginTest.OTTAnalyticsPluginInvocationCount { get set }
}

/// Shared tests for phoenix and tvpapi
class OTTAnalyticsPluginTest: QuickSpec {
    
    struct OTTAnalyticsPluginInvocationCount {
        var firstPlayCount: Int = 0
        var playCount: Int = 0
        var pauseCount: Int = 0
        var loadCount: Int = 0
        var endedCount: Int = 0
    }
    
    /************************************************************/
    // MARK: - Mocks
    /************************************************************/
    
    class OTTAnalyticsPluginTestPhoenixMock: PhoenixAnalyticsPlugin, MockableOTTAnalyticsPluginProtocol {
        
        public override class var pluginName: String { return PluginTestConfiguration.Phoenix.pluginName }
        
        var onAnalyticsEvent: ((OTTAnalyticsEventType, MockableOTTAnalyticsPluginProtocol) -> Void)?
        var onTerminate: ((MockableOTTAnalyticsPluginProtocol) -> Void)?
        var finishedHandling: Bool = false
        var invocationCount = OTTAnalyticsPluginInvocationCount()
        
        override func sendAnalyticsEvent(ofType type: OTTAnalyticsEventType) {
            self.onAnalyticsEvent?(type, self)
        }
        
        override var observations: Set<NotificationObservation> {
            return [
                NotificationObservation(name: .UIApplicationWillTerminate) { [unowned self] in
                    PKLog.trace("plugin: \(self) will terminate event received, sending analytics stop event")
                    self.onTerminate?(self)
                    self.destroy()
                }
            ]
        }
    }
    
    class OTTAnalyticsPluginTestTVPAPIMock: TVPAPIAnalyticsPlugin, MockableOTTAnalyticsPluginProtocol {
        
        public override class var pluginName: String { return PluginTestConfiguration.TVPAPI.pluginName }
        
        var onAnalyticsEvent: ((OTTAnalyticsEventType, MockableOTTAnalyticsPluginProtocol) -> Void)?
        var onTerminate: ((MockableOTTAnalyticsPluginProtocol) -> Void)?
        var finishedHandling: Bool = false
        var invocationCount = OTTAnalyticsPluginInvocationCount()
        
        override func sendAnalyticsEvent(ofType type: OTTAnalyticsEventType) {
            self.onAnalyticsEvent?(type, self)
        }
        
        override var observations: Set<NotificationObservation> {
            return [
                NotificationObservation(name: .UIApplicationWillTerminate) { [unowned self] in
                    PKLog.trace("plugin: \(self) will terminate event received, sending analytics stop event")
                    self.onTerminate?(self)
                    self.destroy()
                }
            ]
        }
    }
    
    class AppStateSubjectMock: AppStateSubjectProtocol {
        static let shared = AppStateSubjectMock()
        
        private init() {
            self.appStateProvider = AppStateProvider()
        }
        
        let lock: AnyObject = UUID().uuidString as AnyObject
        
        var observers = [AppStateObserver]()
        var appStateProvider: AppStateProvider
        var isObserving = false
    }
    
    /************************************************************/
    // MARK: - Tests
    /************************************************************/
    
    override func spec() {
        describe("OTT analytics plugins test") {
            var player: PlayerLoader!
            var phoenixPluginMock: OTTAnalyticsPluginTestPhoenixMock!
            var tvpapiPluginMock: OTTAnalyticsPluginTestTVPAPIMock!
            
            beforeEach {
                PlayKitManager.shared.registerPlugin(OTTAnalyticsPluginTestPhoenixMock.self)
                PlayKitManager.shared.registerPlugin(OTTAnalyticsPluginTestTVPAPIMock.self)
                player = self.createPlayerForPhoenixAndTVPAPI()
                phoenixPluginMock = player.loadedPlugins[OTTAnalyticsPluginTestPhoenixMock.pluginName]!.plugin as! OTTAnalyticsPluginTestPhoenixMock
                tvpapiPluginMock = player.loadedPlugins[OTTAnalyticsPluginTestTVPAPIMock.pluginName]!.plugin as! OTTAnalyticsPluginTestTVPAPIMock
            }
            
            afterEach {
                self.destroyPlayer(player)
            }
            
            context("analytics events handling") {
                // events invocations count.
                let onAnalyticsEvent: (OTTAnalyticsEventType, MockableOTTAnalyticsPluginProtocol) -> Void = { eventType, analyticsPluginMock in
                    var analyticsPluginMock = analyticsPluginMock
                    print("received analytics event: \(eventType.rawValue)")
                    switch eventType {
                    case .first_play, .play:
                        if eventType == .first_play {
                            analyticsPluginMock.invocationCount.firstPlayCount += 1
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                player.pause()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                player.play()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                                player.pause()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                                player.play()
                                player.seek(to: CMTimeMake(Int64(player.duration - 1), 1))
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                                expect(analyticsPluginMock.invocationCount.playCount).to(equal(3)) // 3 from player.play()
                                expect(analyticsPluginMock.invocationCount.pauseCount).to(equal(2)) // 2 from player.pause()
                                expect(analyticsPluginMock.invocationCount.firstPlayCount).to(equal(1)) // 1 from player.play() first play should happen only once
                                expect(analyticsPluginMock.invocationCount.loadCount).to(equal(1)) // 1 from player.play()
                                expect(analyticsPluginMock.invocationCount.endedCount).to(equal(1)) // 1 from ended after seek to end (ended)
                                print(type(of: analyticsPluginMock))
                                analyticsPluginMock.finishedHandling = true
                            }
                        }
                        if eventType == .first_play || eventType == .play {
                            switch analyticsPluginMock.invocationCount.playCount {
                            case 0: expect(eventType).to(equal(OTTAnalyticsEventType.first_play))
                            default: expect(eventType).to(equal(OTTAnalyticsEventType.play))
                            }
                            analyticsPluginMock.invocationCount.playCount += 1
                        }
                    case .pause:
                        analyticsPluginMock.invocationCount.pauseCount += 1
                    case .load:
                        analyticsPluginMock.invocationCount.loadCount += 1
                    case .finish:
                        analyticsPluginMock.invocationCount.endedCount += 1
                    default: break
                    }
                }
                
                it("tests event handling") {
                    print("request: \(String(describing: phoenixPluginMock.buildRequest(ofType: .play)))")
                    phoenixPluginMock.onAnalyticsEvent = onAnalyticsEvent
                    tvpapiPluginMock.onAnalyticsEvent = onAnalyticsEvent
                    // to start the whole flow we need to make an initial play
                    player.play()
                    expect(phoenixPluginMock.finishedHandling).toEventually(beTrue(), timeout: 20, pollInterval: 2, description: "makes sure finished handling the event")
                    expect(tvpapiPluginMock.finishedHandling).toEventually(beTrue(), timeout: 20, pollInterval: 2, description: "makes sure finished handling the event")
                }
            }
            context("termination observation") {
                it("tests app state termination observation with finish event") {
                    AppStateSubjectMock.shared.add(observer: phoenixPluginMock)
                    AppStateSubjectMock.shared.add(observer: tvpapiPluginMock)
                    let onTerminate: (MockableOTTAnalyticsPluginProtocol) -> Void = { analyticsPluginMock in
                        var analyticsPluginMock = analyticsPluginMock
                        AppStateSubjectMock.shared.remove(observer: phoenixPluginMock)
                        AppStateSubjectMock.shared.remove(observer: tvpapiPluginMock)
                        analyticsPluginMock.finishedHandling = true
                    }
                    phoenixPluginMock.onTerminate = onTerminate
                    tvpapiPluginMock.onTerminate = onTerminate
                    // to start the whole flow we need to make an initial play
                    player.play()
                    // post stub termination
                    AppStateSubjectMock.shared.appStateEventPosted(name: .UIApplicationWillTerminate)
                    expect(phoenixPluginMock.finishedHandling).toEventually(beTrue(), timeout: 20, pollInterval: 2, description: "makes sure finished handling the event")
                    expect(tvpapiPluginMock.finishedHandling).toEventually(beTrue(), timeout: 20, pollInterval: 2, description: "makes sure finished handling the event")
                }
            }
        }
    }
}
