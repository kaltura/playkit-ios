import UIKit
import XCTest
import PlayKit

class MockMediaProviderTest: XCTestCase {
    
    
    
    var filePath : URL?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
        let bundle = Bundle.main
        let path = bundle.path(forResource: "Entries", ofType: "json")
        guard let filePath = path else {return}
        self.filePath = URL(string:filePath)
        
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMediaProviderSuccessFlow() {
        
        let theExeption = expectation(description: "test")
        
        let mediaProvider1 : MediaEntryProvider = MockMediaEntryProvider(fileURL: self.filePath! , mediaEntryId: "m001")
        mediaProvider1.loadMedia { (r:Response<MediaEntry>) in
            print(r)
            if r.data != nil {
                theExeption.fulfill()
            }
            else{
                XCTFail()
            }
        }
        
        
        waitForExpectations(timeout: 6.0) { (_) -> Void in
            
            
        }
    }
    
    func testMediaProviderMediaNotFoundFlow() {
        
        let theExeption = expectation(description: "test")
        
        let mediaProvider2 : MediaEntryProvider = MockMediaEntryProvider(fileURL: self.filePath! , mediaEntryId: "sdf")
        mediaProvider2.loadMedia { (r:Response<MediaEntry>) in
            if let err = r.error as? MockMediaEntryProvider.MockError {
                if( err == MockMediaEntryProvider.MockError.mediaNotFound){
                    theExeption.fulfill()
                }else{
                    XCTFail()
                }
            }else{
                XCTFail()
            }
            
            
            waitForExpectations(timeout: 6.0) { (_) -> Void in
                
            }
            
        }
    }
    
    func testMediaProvideFileNotFoundFlow() {
        
        let theExeption = expectation(description: "test")
        
        let mediaProvider2 : MediaEntryProvider = MockMediaEntryProvider(fileURL: URL(string:"asdd")! , mediaEntryId: "sdf")
        mediaProvider2.loadMedia { (r:Response<MediaEntry>) in
            if let err = r.error as? MockMediaEntryProvider.MockError {
                if( err == MockMediaEntryProvider.MockError.fileIsEmptyOrNotFound){
                    theExeption.fulfill()
                }else{
                    XCTFail()
                }
            }else{
                XCTFail()
            }
            
            
            waitForExpectations(timeout: 6.0) { (_) -> Void in
                
            }
            
        }
    }
    
    

}
