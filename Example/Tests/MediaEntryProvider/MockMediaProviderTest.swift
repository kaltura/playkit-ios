import UIKit
import XCTest
import PlayKit
import SwiftyJSON

class MockMediaProviderTest: XCTestCase {
    
    
    
    var filePath : URL?
    var fileContent: Any?
    
    
    override func setUp() {
        super.setUp()
        
        let bundle = Bundle.main
        let path = bundle.path(forResource: "Entries", ofType: "json")
        guard let filePath = path else {return}
        self.filePath = URL(string:filePath)
        
        guard let stringPath = self.filePath?.absoluteString else {
            return
        }
        guard  let data = NSData(contentsOfFile: stringPath)  else {
            return
        }
        let json = JSON(data: data as Data)
        self.fileContent = json.object

    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMediaProviderSuccessFlow() {
        
        let theExeption = expectation(description: "test")
        
        let mediaProvider1 : MediaEntryProvider = MockMediaEntryProvider()
            .set(url: self.filePath!)
            .set(id: "m001")
        
        mediaProvider1.loadMedia { (r:Result<MediaEntry>) in
            print(r)
            if r.data != nil {
                theExeption.fulfill()
            }
            else{
                XCTFail()
            }
        }
        
        
        self.waitForExpectations(timeout: 6.0) { (_) -> Void in
            
            
        }
    }
    
    func testMediaProviderMediaNotFoundFlow() {
        
        let theExeption = expectation(description: "test")
        let mediaProvider2 : MediaEntryProvider = MockMediaEntryProvider().set(url: self.filePath!).set(id: "sdf")
        
        mediaProvider2.loadMedia { (r:Result<MediaEntry>) in
            if  r.error != nil {
                theExeption.fulfill()
            }else{
                XCTFail()
            }
            
            self.waitForExpectations(timeout: 6.0) { (_) -> Void in
                
            }
            
        }
    }
    
    
    func testMediaProvideFileNotFoundFlow() {
        
        let theExeption = expectation(description: "test")
        let mediaProvider2 : MediaEntryProvider = MockMediaEntryProvider().set(url: URL(string:"asdd")).set(id: "sdf")
        
        mediaProvider2.loadMedia { (r:Result<MediaEntry>) in
            if r.error != nil {
                theExeption.fulfill()
            }else{
                XCTFail()
            }
            
            self.waitForExpectations(timeout: 6.0) { (_) -> Void in
                
            }
            
        }
    }
    
    func testMediaProviderByJson() -> Void {
        
        let theExeption = expectation(description: "test")
        
        let mediaProvider1 : MediaEntryProvider = MockMediaEntryProvider()
            .set(content: self.fileContent)
            .set(id: "m001")
        
        mediaProvider1.loadMedia { (r:Result<MediaEntry>) in
            if let mediaEntry = r.data {
                if let sources = mediaEntry.sources, sources.count > 0{
                    
                    let source = sources[0]
                    if let url = source.contentUrl , url.absoluteString.isEmpty == false {
                        theExeption.fulfill()
                    }else{
                       XCTFail()
                    }
                }else{
                    XCTFail()
                }
            }
            else{
                XCTFail()
            }
        }
        
        
        self.waitForExpectations(timeout: 6.0) { (_) -> Void in
            
            
        }

    }
    
    

}
