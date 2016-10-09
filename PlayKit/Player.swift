//
//  Player.swift
//  PlayKit
//
//  Created by Noam Tamim on 28/08/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit


public protocol Player {
    func load(_ config: PlayerConfig) -> Bool    
    func apply(_ config: PlayerConfig) -> Bool
    func play()
    func pause()
    
    var view: UIView { get }
    
    var position: Int64 { get set }
    
    func release()
}


public class PlayerFactory {
    public static func createPlayer() -> Player {
        return PlayerImp();
    }

    public static func createPlayer(config: PlayerConfig) -> Player? {
        let player = PlayerImp()
        
        return player.load(config) ? player : nil
    }
}


