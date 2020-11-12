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

/// Main interface that MediaEntry Interceptor Plugin should adopt.
@objc public protocol PKMediaEntryInterceptor: class {
    
    /// In this method we have to take MediaEntry, change MediaSource in it an return Error if needed.
    /// Consider of making this method performing all logic in concurrent thread, if this logic is time consuming.
    @objc func apply(entry: PKMediaEntry, completion: @escaping (Error?) -> Void)
}

@objc public protocol MediaEntryInterceptorsDatasource {
    
    @objc var interceptors: [PKMediaEntryInterceptor] { get }
}

extension PlayerLoader: MediaEntryInterceptorsDatasource {
    
    public var interceptors: [PKMediaEntryInterceptor] {
        
        return self.loadedPlugins
            .filter { $0.value.plugin is PKMediaEntryInterceptor }
            .compactMap { $0.value.plugin as? PKMediaEntryInterceptor }
    }
    
}
