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

import Foundation

@objc public protocol PlaylistProvider {
    
    func loadPlaylist(callback: @escaping (PKPlaylist?, Error?) -> Void)
    
    func cancel()
}
