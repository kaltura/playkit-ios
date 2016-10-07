//
//  Player.swift
//  PlayKit
//
//  Created by Noam Tamim on 28/08/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit

protocol Player {
    func load(_ config: PlayerConfig) -> Bool    
    func apply(_ config: PlayerConfig) -> Bool
    
    var view: UIView { get }
    
    var position: Int64 { get }
    var shouldPlay: Bool { get }
    func release()
}

public class PlayerConfig {
    public var mediaEntry : MediaEntry?
    public var position : Int64 = 0
    public var subtitleLanguage : String?
    public var audioLanguage : String?
}

