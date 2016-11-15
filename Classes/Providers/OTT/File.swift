//
//  File.swift
//  Pods
//
//  Created by Admin on 15/11/2016.
//
//

import UIKit
import SwiftyJSON

class File {
    
    var id: String? = nil
    var type: String? = nil
    var url: URL? = nil
    var duration: TimeInterval? = nil
    
    private let idKey: String = "id"
    private let typeKey: String = "type"
    private let urlKey: String = "url"
    private let durationKey: String = "url"

    
    init(json:Any) {
        
        let fileJosn = JSON(json)
        self.id = fileJosn[idKey].string
        self.type = fileJosn[typeKey].string
        if let contentURL = fileJosn[urlKey].string{
                self.url = URL(string: contentURL)
        }
        self.duration =  fileJosn[durationKey].number?.doubleValue
    }
}
