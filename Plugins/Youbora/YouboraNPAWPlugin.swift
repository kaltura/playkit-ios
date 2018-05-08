//
//  YouboraNPAWPlugin.swift
//  PlayKit
//
//  Created by Gilad Nadav on 5/7/18.
//

import UIKit
import YouboraLib

class YouboraNPAWPlugin: YBPlugin {
    override init(options: YBOptions?) {
        super.init(options: options)
    }
    override init(options: YBOptions?, andAdapter adapter: YBPlayerAdapter<AnyObject>?) {
        super.init(options: options, andAdapter: adapter)
    }
}
