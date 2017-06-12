//
//  TVPAPIPluginTest.swift
//  PlayKit
//
//  Created by Gal Orlanczyk on 12/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
@testable import PlayKit
import Quick
import Nimble
import KalturaNetKit

class TVPAPIPluginTest: QuickSpec {
    
    /************************************************************/
    // MARK: - Mocks
    /************************************************************/
    
    class TVPAPIAnalyticsPluginMock: TVPAPIAnalyticsPlugin {
        
        public override class var pluginName: String { return PluginTestConfiguration.TVPAPI.pluginName }
    }
    
    /************************************************************/
    // MARK: - Tests
    /************************************************************/
    
    override func spec() {
        describe("TVPAPIPluginTest") {
            var player: PlayerLoader!
            var tvpapiPluginMock: TVPAPIPluginTest.TVPAPIAnalyticsPluginMock!
            
            beforeEach {
                PlayKitManager.shared.registerPlugin(TVPAPIPluginTest.TVPAPIAnalyticsPluginMock.self)
                player = self.createPlayerForTVPAPI()
                tvpapiPluginMock = player.loadedPlugins[TVPAPIPluginTest.TVPAPIAnalyticsPluginMock.pluginName]!.plugin as! TVPAPIPluginTest.TVPAPIAnalyticsPluginMock
            }
            
            afterEach {
                self.destroyPlayer(player)
            }
            
            it("can build play event request") {
                let expectedDataBody = "{\"iMediaID\":\"test\",\"mediaType\":0,\"Action\":\"play\",\"initObj\":{\"\":\"\"},\"iLocation\":0,\"iFileID\":\"464302\"}".data(using: .utf8)
                let expectedUrl = "http://tvpapi-preprod.ott.kaltura.com/v3_9/gateways/jsonpostgw.aspx?m=MediaMark"
                let expectedMethod: RequestMethod = .post
                
                let request = tvpapiPluginMock.buildRequest(ofType: .play)

                expect(expectedUrl).to(equal(request?.url.absoluteString))
                expect(expectedDataBody).to(equal(request?.dataBody))
                expect(expectedMethod).to(equal(request?.method))
            }
        }
    }
}
