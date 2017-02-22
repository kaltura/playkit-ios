//
//  PhoenixPluginTest.swift
//  PlayKit
//
//  Created by Gal Orlanczyk on 08/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import PlayKit

class PhoenixPluginTest: QuickSpec {
    
    /************************************************************/
    // MARK: - Mocks
    /************************************************************/
    
    class PhoenixAnalyticsPluginMock: PhoenixAnalyticsPlugin {
        
        public override class var pluginName: String { return PluginTestConfiguration.Phoenix.pluginName }
    }
    
    /************************************************************/
    // MARK: - Tests
    /************************************************************/
    
    override func spec() {
        describe("phoenix request builder test") {
            PlayKitManager.shared.registerPlugin(PhoenixPluginTest.PhoenixAnalyticsPluginMock.self)
            var player: PlayerLoader!
            var phoenixPluginMock: PhoenixPluginTest.PhoenixAnalyticsPluginMock!
            
            beforeEach {
                player = self.createPlayer()
                phoenixPluginMock = player.loadedPlugins[PhoenixPluginTest.PhoenixAnalyticsPluginMock.pluginName]!.plugin as! PhoenixPluginTest.PhoenixAnalyticsPluginMock
            }
            
            afterEach {
                player.destroy()
            }
            
            it("can build play event request") {
                let request = phoenixPluginMock.buildRequest(ofType: .play)
            }
        }
    }
}
