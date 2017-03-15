//
//  KalturaAnalyticsProtocol.swift
//  Pods
//
//  Created by Gal Orlanczyk on 08/02/2017.
//
//

import Foundation

protocol AnalyticsPluginProtocol: PKPlugin {
    
    var config: AnalyticsConfig? { get set }
    var isFirstPlay: Bool { get set }
    var playerEventsToRegister: [PlayerEvent.Type] { get }
    
    func registerEvents()
}
