//
//  MediaEntryProviderResponseDelegate.swift
//  Pods
//
//  Created by Rivka Peleg on 03/07/2017.
//
//

import Foundation
import KalturaNetKit

//This protocol provides a way to use the response data of the requests are being sent by MediaEntryProvider.
//For example the response of getPlaybackContext, or additional meta data.

public protocol MediaEntryProviderResponseDelegate: class {
    
    func providerGotResponse(sender: MediaEntryProvider?, response: Response) -> Void

}
