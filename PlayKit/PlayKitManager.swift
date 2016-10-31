//
//  PlayKitManager.swift
//  PlayKit
//
//  Created by Noam Tamim on 31/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit

public class PlayKitManager: NSObject {
    public static func createPlayer() -> Player {
        return PlayerImp();
    }
}
