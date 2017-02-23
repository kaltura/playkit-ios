//
//  BasePlayerQuickSpec.swift
//  PlayKit
//
//  Created by Gal Orlanczyk on 08/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import SwiftyJSON
@testable import PlayKit

enum PlayerCreationError: Error {
    case PluginNamesCountMismatch
}

protocol PlayerCreator { }

// make sure all quick spec classes have player creator.
extension QuickSpec: PlayerCreator { }

/************************************************************/
// MARK: - Basic Player
/************************************************************/

extension PlayerCreator where Self: QuickSpec {
    
    func createPlayer(pluginConfigDict: [String : Any]? = nil, shouldStartPreparing: Bool = true) -> PlayerLoader {
        let player: PlayerLoader
        
        var source = [String : Any]()
        source["id"] = "test"
        source["url"] = "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
        // FIXME: change to offline video when available, Bundle(for: type(of: self)).path(forResource: "big_buck_bunny_short", ofType: "mp4")!
        
        var sources = [JSON]()
        sources.append(JSON(source))
        
        var entry = [String : Any]()
        entry["id"] = "test"
        entry["sources"] = sources
        let mediaConfig = MediaConfig(mediaEntry: MediaEntry(json: entry))
        
        let pluginConfig: PluginConfig?
        if let pluginConfigDict = pluginConfigDict {
            let pluginConfig = PluginConfig(config: pluginConfigDict)
            player = PlayKitManager.shared.loadPlayer(pluginConfig: pluginConfig) as! PlayerLoader
        } else {
            pluginConfig = nil
            player = PlayKitManager.shared.loadPlayer(pluginConfig: pluginConfig) as! PlayerLoader
        }
        
        if shouldStartPreparing {
            player.prepare(mediaConfig)
        }
        return player
    }
}

/************************************************************/
// MARK: - OTT Analytics Player
/************************************************************/

extension PlayerCreator where Self: QuickSpec {
    
    func createPlayerForPhoenixAndTVPAPI(shouldStartPreparing: Bool = true) -> PlayerLoader {
        let pluginConfigDict: [String : Any] = [
            PluginTestConfiguration.Phoenix.pluginName : PluginTestConfiguration.Phoenix.paramsDict,
            PluginTestConfiguration.TVPAPI.pluginName : PluginTestConfiguration.TVPAPI.paramsDict
        ]
        return self.createPlayer(pluginConfigDict: pluginConfigDict, shouldStartPreparing: shouldStartPreparing)
    }
}
