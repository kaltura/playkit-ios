//
//  KalturaRequestBuilderTest.swift
//  PlayKit
//
//  Created by Gal Orlanczyk on 08/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import Quick
import Nimble
@testable import PlayKit
@testable import KalturaNetKit
import SwiftyJSON

class KalturaRequestBuilderTest: QuickSpec {
        
    override func spec() {
        describe("KalturaRequestBuilder Test") {
            it("should build a request") {
                let expectedUrl = "https://cdnapisec.kaltura.com/service/test/action/add"
                let expectedBody = JSON(["test": "test"])
                
                let url = "https://cdnapisec.kaltura.com"
                let service = "test"
                let action = "add"
                let kalturaRequestBuilder: KalturaRequestBuilder! = KalturaRequestBuilder(url: url, service: service, action: action)
                expect(kalturaRequestBuilder).toNot(beNil())
                // the result
                let request = kalturaRequestBuilder.setBody(key: "test", value: "test").build()
                // check the result against expected
                let parsedRequestBody = JSON.init(parseJSON: String.init(data: request.dataBody!, encoding: .utf8)!)
                expect(expectedBody).to(equal(parsedRequestBody))
                expect(expectedUrl).to(equal(request.url.absoluteString))
            }
        }
    }
}
