//
//  MediaEntry.swift
//  PlayKit
//
//  Created by Noam Tamim on 08/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit


public protocol MediaEntryProvider {
    /**
     This method is triggering the creation of media base on custom parameters and actions.
     
     ## Important:  
     - In order to write custom provider you should implement this method
     - In order to send an informative error in the ResponseElemnt
     you should implement an error enum with the relevnat errors
    
     - parameter callback - a block that called on completion and returing response object wich contain the MediaEntry
     ```
        // example of usage:
         let cp : MediaEntryProvider =
            CustomMediaEntryProvider(customParameters)
     
         customMediaProvider.loadMedia { 
            (r:ResponseElemnt<MediaEntry>) in
             if (r.succedded){
             ...
     ```
     
     */
    func loadMedia(callback:(_ response:ResponseElemnt<MediaEntry>)->Void)
}




