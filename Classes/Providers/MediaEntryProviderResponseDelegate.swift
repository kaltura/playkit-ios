// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import KalturaNetKit

//This protocol provides a way to use the response data of the requests are being sent by MediaEntryProvider.
//For example the response of getPlaybackContext, or additional meta data.

public protocol PKMediaEntryProviderResponseDelegate: AnyObject {
    
    func providerGotResponse(sender: MediaEntryProvider?, response: Response) -> Void

}
