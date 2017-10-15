// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit

@objc public protocol MediaEntryProvider {
    /**
     This method is triggering the creation of media base on custom parameters and actions.
     
     ## Important:  
     - In order to write custom provider you should implement this method
     - In order to send an informative error in the ResponseElement
     you should implement an error enum with the relevnat errors
    
     - parameter callback - a block that called on completion and returing response object wich contain the PKMediaEntry
     ```
        // example of usage:
         let cp : MediaEntryProvider =
            CustomMediaEntryProvider(customParameters)
     
         customMediaProvider.loadMedia { 
            (r:ResponseElement<PKMediaEntry>) in
             if (r.succedded){
             ...
     ```
     
     */
    func loadMedia(callback: @escaping (PKMediaEntry?, Error?) -> Void)

    func cancel()

}
