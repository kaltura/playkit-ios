//
//  File.swift
//  Pods
//
//  Created by Admin on 15/11/2016.
//
//

import UIKit
import SwiftyJSON

internal class OTTFile: OTTBaseObject {

    internal var id: String
    internal var type: String?
    internal var url: URL?
    internal var duration: TimeInterval?

    private let idKey: String = "id"
    private let typeKey: String = "type"
    private let urlKey: String = "url"
    private let durationKey: String = "url"

    internal init(id: String) {
        self.id = id
    }

    internal required init?(json:Any) {

        let fileJosn = JSON(json)

        if let id = fileJosn[idKey].number {
            self.id = id.stringValue
        } else {
            return nil
        }

        self.type = fileJosn[typeKey].string
        if let contentURL = fileJosn[urlKey].string {
                self.url = URL(string: contentURL)
        }
        self.duration =  fileJosn[durationKey].number?.doubleValue
    }
}
