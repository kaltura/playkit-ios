// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import XCTest
import PlayKit
import GoogleCast


// showing how to handle ads
// showing how to handle tracks 



class GoogleCastTest: XCTestCase {
    
    let contentId = "entryId"
    let partnerId = "partnerId"
    let adTagURL = "adTagURL"
    let uiconfId = "uiconfId"
    let webPlayerURL = "webPlayerURL"
    
    let ks = "adTagURL"
    
    let format = "format"
    let initObject = ["initObject":[:]] as? [String:Any]
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreatingOVPMediaInfo() {
        
        let metadata = self.metadata()
        let mediaInfoBuilder = OVPCastBuilder()
            .set(ks: ks)                                                    //required
            .set(streamType: BasicCastBuilder.StreamType.vod)               //required
            .set(contentId: contentId)                                      //required
            .set(partnerID: partnerId)                                      //required
            .set(adTagURL: adTagURL)                                        //optional
            .set(uiconfID: uiconfId)                                        //optional
            .set(webPlayerURL: webPlayerURL)                                //optional
            .set(metaData: metadata)                                        // optional
        
        do {
            let mediaInfo = try mediaInfoBuilder.build()
            XCTAssert(mediaInfo.contentID == contentId )
            
            //Handle cast
            let castContext = GCKCastContext.sharedInstance()
            castContext
                .sessionManager
                .currentCastSession?
                .remoteMediaClient?
                .loadMedia(mediaInfo)
            
            //Handle ads
            castContext
                .sessionManager
            .currentCastSession?
            .remoteMediaClient?
            .adInfoParserDelegate = CastAdInfoParser.shared
            

            
        }catch{
            XCTFail()
        }
    }
    
    func testCreatingOTTMediaInfo() {
        
        let metadata = self.metadata()
        let mediaInfoBuilder = TVPAPICastBuilder()
            .set(streamType: BasicCastBuilder.StreamType.vod)           // required
            .set(contentId: contentId)                                  // required
            .set(partnerID: partnerId)                                  // required
            .set(webPlayerURL: webPlayerURL)                            // required
            .set(initObject: initObject)                                // required
            .set(format: format)                                        // required
            .set(metaData: metadata)                                    // optional
            .set(uiconfID: uiconfId)                                    // optional
            .set(adTagURL: adTagURL)                                    // optional

        do {
            let mediaInfo = try mediaInfoBuilder.build()
            XCTAssert(mediaInfo.contentID == contentId )
            
            //Handle cast
            let castContext = GCKCastContext.sharedInstance()
            castContext
                .sessionManager
                .currentCastSession?
                .remoteMediaClient?
                .loadMedia(mediaInfo)
            
            //Handle ads
            castContext
                .sessionManager
                .currentCastSession?
                .remoteMediaClient?
                .adInfoParserDelegate = CastAdInfoParser.shared
        
            //Handle Tracks
            
            
        }catch{
            XCTFail()
        }
    }

    
 
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    // Helpers
    
    func metadata() -> GCKMediaMetadata {
        
        let metaData = GCKMediaMetadata()
        metaData.addImage(GCKImage(url: URL(string:"www.test.com/image.png")!, width: 10, height: 10))
        metaData.addImage(GCKImage(url: URL(string:"www.test.com/image.png")!, width: 100, height: 100))
        metaData.setString("The title", forKey: kGCKMetadataKeyTitle)
        metaData.setString("The subtitle", forKey: kGCKMetadataKeySubtitle)
        
        return metaData
    }
    
}
