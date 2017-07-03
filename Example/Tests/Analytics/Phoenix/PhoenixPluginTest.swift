// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

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
        describe("PhoenixPluginTest") {
            var player: PlayerLoader!
            var phoenixPluginMock: PhoenixPluginTest.PhoenixAnalyticsPluginMock!
            
            beforeEach {
                PlayKitManager.shared.registerPlugin(PhoenixPluginTest.PhoenixAnalyticsPluginMock.self)
                player = self.createPlayerForPhoenix()
                phoenixPluginMock = player.loadedPlugins[PhoenixPluginTest.PhoenixAnalyticsPluginMock.pluginName]!.plugin as! PhoenixPluginTest.PhoenixAnalyticsPluginMock
            }
            
            afterEach {
                self.destroyPlayer(player)
            }
            
            it("can build play event request") {
                let expectedDataBody = "{\"clientTag\":\"java:16-09-10\",\"apiVersion\":\"3.6.1078.11798\",\"bookmark\":{\"position\":0,\"objectType\":\"KalturaBookmark\",\"type\":\"media\",\"id\":\"test\",\"playerData\":{\"fileId\":\"464302\",\"action\":\"PLAY\",\"objectType\":\"KalturaBookmarkPlayerData\"}},\"ks\":\"\"}".data(using: .utf8)
                let expectedUrl = "http://api-preprod.ott.kaltura.com/v4_1/api_v3//service/bookmark/action/add"
                
                let request = phoenixPluginMock.buildRequest(ofType: .play)
                
                expect(expectedUrl).to(equal(request?.url.absoluteString))
                expect(expectedDataBody).to(equal(request?.dataBody))
            }
        }
    }
}
