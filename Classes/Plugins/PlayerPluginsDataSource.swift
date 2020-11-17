// ===================================================================================================
// Copyright (C) 2020 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation

public protocol PlayerPluginsDataSource {
    
    /// Filtering loaded plugins by certain type.
    func getLoadedPlugins<T>(ofType type: T.Type) -> [T]
}

extension PlayerLoader: PlayerPluginsDataSource {
    
    public func getLoadedPlugins<T>(ofType type: T.Type) -> [T] {
        
        return self.loadedPlugins
            .filter { $0.value.plugin is T }
            .compactMap { $0.value.plugin as? T }
    }
    
}
