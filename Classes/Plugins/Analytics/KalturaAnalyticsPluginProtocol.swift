//
//  KalturaAnalyticsProtocol.swift
//  Pods
//
//  Created by Gal Orlanczyk on 08/02/2017.
//
//

import Foundation

protocol KalturaAnalyticsPluginProtocol: PKPlugin {
    
    unowned var player: Player { get set }
    unowned var messageBus: MessageBus { get set }
    var config: AnalyticsConfig? { get set }
    var playerEventsToRegister: [PlayerEvent.Type] { get }
    
    func registerEvents()
}
