// ===================================================================================================
// Copyright (C) 2021 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================
//
//  PKMessageBus.swift
//  PlayKit
//
//  Created by Sergii Chausov on 07.11.2021.
//

import Foundation

public protocol PKMessageBus {
    func getMessageBus() -> MessageBus
}

extension PlayerLoader: PKMessageBus {
    
    func getMessageBus() -> MessageBus {
        return self.messageBus
    }
}
