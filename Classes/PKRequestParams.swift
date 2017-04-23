//
//  PKRequestInfo.swift
//  Pods
//
//  Created by Gal Orlanczyk on 04/04/2017.
//
//

import Foundation

/// `PKRequestParamsDecorator` used for getting updated request info
@objc public protocol PKRequestParamsAdapter {
    func adapt(requestParams: PKRequestParams) -> PKRequestParams
}

@objc public class PKRequestParams: NSObject {
    
    public let url: URL
    public let headers: [String: String]?
    
    init(url: URL, headers: [String: String]?) {
        self.url = url
        self.headers = headers
    }
}

