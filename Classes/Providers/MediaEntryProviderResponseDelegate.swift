//
//  MediaEntryProviderResponseDelegate.swift
//  Pods
//
//  Created by Rivka Peleg on 03/07/2017.
//
//

import Foundation

//This protocol provides a way to use the response data of the requests are being sent by MediaEntryProvider.
//For example the response of getPlaybackContext, or additional meta data.

@objc public protocol MediaEntryProviderResponseDelegate {
    
    @objc func providerGotResponse(sender: MediaEntryProvider?, response: [String:Any]?) -> Void

}
