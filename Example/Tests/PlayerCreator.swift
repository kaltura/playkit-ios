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
import SwiftyJSON
@testable import PlayKit

enum PlayerCreationError: Error {
    case PluginNamesCountMismatch
}

protocol PlayerCreator: class { }

// make sure all xctest case classes have player creator.
extension XCTestCase: PlayerCreator { }

/************************************************************/
// MARK: - Basic Player
/************************************************************/

extension PlayerCreator {
    
    func createPlayer(pluginConfigDict: [String : Any]? = nil, shouldStartPreparing: Bool = true) -> PlayerLoader {
        let player: PlayerLoader
        
        // for hls stream use: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
        let url = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "big_buck_bunny_short", ofType: "mp4")!)
        let entry = PKMediaEntry("test", sources: [PKMediaSource("test", contentUrl: url)])
        let mediaConfig = MediaConfig(mediaEntry: entry)
        do {
            let pluginConfig: PluginConfig?
            if let pluginConfigDict = pluginConfigDict {
                let pluginConfig = PluginConfig(config: pluginConfigDict)
                player = try PlayKitManager.shared.loadPlayer(pluginConfig: pluginConfig) as! PlayerLoader
            } else {
                pluginConfig = nil
                player = try PlayKitManager.shared.loadPlayer(pluginConfig: pluginConfig) as! PlayerLoader
            }
            
            if shouldStartPreparing {
                player.prepare(mediaConfig)
            }
            return player
        } catch {
            print("could not create player instance")
        }
        
        return PlayerLoader()
    }
    
    func destroyPlayer(_ player: Player!) {
        var player = player
        player?.stop()
        player?.destroy()
        player = nil
    }
}

/************************************************************/
// MARK: - OTT Analytics Player
/************************************************************/

extension PlayerCreator {
    
    func createPlayerForTVPAPI(shouldStartPreparing: Bool = true) -> PlayerLoader {
        let pluginConfigDict: [String : Any] = [
            PluginTestConfiguration.TVPAPI.pluginName: AnalyticsConfig(params: PluginTestConfiguration.TVPAPI.paramsDict)
        ]
        return self.createPlayer(pluginConfigDict: pluginConfigDict, shouldStartPreparing: shouldStartPreparing)
    }
    
    func createPlayerForPhoenix(shouldStartPreparing: Bool = true) -> PlayerLoader {
        let pluginConfigDict: [String : Any] = [
            PluginTestConfiguration.Phoenix.pluginName: AnalyticsConfig(params: PluginTestConfiguration.Phoenix.paramsDict)
        ]
        return self.createPlayer(pluginConfigDict: pluginConfigDict, shouldStartPreparing: shouldStartPreparing)
    }
    
    func createPlayerForPhoenixAndTVPAPI(shouldStartPreparing: Bool = true) -> PlayerLoader {
        let pluginConfigDict: [String : Any] = [
            PluginTestConfiguration.Phoenix.pluginName: AnalyticsConfig(params: PluginTestConfiguration.Phoenix.paramsDict),
            PluginTestConfiguration.TVPAPI.pluginName: AnalyticsConfig(params: PluginTestConfiguration.TVPAPI.paramsDict)
        ]
        return self.createPlayer(pluginConfigDict: pluginConfigDict, shouldStartPreparing: shouldStartPreparing)
    }
}
