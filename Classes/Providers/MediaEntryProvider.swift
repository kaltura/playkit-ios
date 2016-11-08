//
//  MediaEntry.swift
//  PlayKit
//
//  Created by Noam Tamim on 08/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit


public protocol MediaEntryProvider {
    func loadMedia(callback:(_ response:ResponseElemnt<MediaEntry>)->Void)
}




