//
//  OVPMediaProviederTest.swift
//  PlayKit
//
//  Created by Rivka Peleg on 29/11/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import PlayKit

let entryID = "1_1h1vsv3z"


class OVPMediaProviederTest: XCTestCase, SessionProvider {
    
    
    var partnerId: Int64 = 2209591
    var serverURL: String  = "http://cdnapi.kaltura.com"
    
    func loadKS(completion: (_ result :Result<String>) -> Void){
        
        completion(Result(data: "djJ8MjIwOTU5MXyDmkKuVhHfzNvca2oQWbhyKBVWMCvAGLcEH2QBS1VBmpqoszqPLwCFwl_V-Qdc2-nt9M21RaJIoea-VP0wpcxOHIHlzXADcdKUZ4rovtCRx-U5bnFIwSx17UUfBB80vzM=", error: nil))
    }

    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let provider = OVPMediaProvider(sessionProvider: self, entryId: "1_1h1vsv3z", uiconfId:nil , executor: OVPMockExecutor() )
        provider.loadMedia { (r:Result<MediaEntry>) in
            print(r)
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}


class OVPMockExecutor: RequestExecutor {
    
    
    let serviceKey = "service"
    let actionKey = "action"
    
    
    func send(request:Request){
        
        var fileName = "ovp"
        
        let urlComponent = request.url.absoluteString.components(separatedBy: "/")
        
        var serviceName: String? = nil
        var actionName: String? = nil
        
        let serviceKeyIndex = urlComponent.index(of: serviceKey)
        
        if let serviceKeyIndex = serviceKeyIndex{
                serviceName = urlComponent[serviceKeyIndex + 1]
        }
        
        
        let actionKeyIndex = urlComponent.index(of: actionKey)
        if let actionKeyIndex = actionKeyIndex{
            actionName = urlComponent[actionKeyIndex+1]
        }
        
        
        if let service = serviceName{
            fileName.append(".\(service)")
        }
        else{
            fileName.append("._")
        }
        
        
        if let action = actionName{
            fileName.append(".\(action)")
        }
        else{
            fileName.append("._")
        }
        
        fileName.append(".\(entryID)")

        
        let bundle = Bundle.main
        let path = bundle.path(forResource: fileName, ofType: "json")
        guard let filePath = path else {
            
            if let completion = request.completion{
                completion(Response(data: nil, error: nil))
            }
            return
        }
        
        let content =  NSData(contentsOfFile:filePath) as Data?
        
        guard let contentFile = content else {
            if let completion = request.completion{
                completion(Response(data: nil, error: nil))
            }
            return
        }
        
        do{
            let result = try JSONSerialization.jsonObject(with: contentFile, options: JSONSerialization.ReadingOptions())
            if let completion = request.completion{
                completion(Response(data: result, error: nil))
            }
            
        }catch{
            if let completion = request.completion{
                completion(Response(data: nil, error: nil))
            }
            
        }
        
    }
    
    func cancel(request:Request){
        
    }
    
    func clean(){
        
    }
}
