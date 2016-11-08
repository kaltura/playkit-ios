//
//  MockMediaProvider.swift
//  Pods
//
//  Created by Admin on 08/11/2016.
//
//

import UIKit
import SwiftyJSON



public class MockMediaEntryProvider: MediaEntryProvider {
    
    
   public enum MockError: Error {
        case fileIsEmptyOrNotFound
        case invalidJSON
        case mediaNotFound
        
    }
    
    
    public var id : String
    public var url : URL?
    public var content : Data?
    
    private var objects : JSON?
    
    
    public init(fileURL:URL,mediaEntryId:String)
    {
        self.url = fileURL
        self.id = mediaEntryId
        
    }
    
    public init(contentOfFile:Data,mediaEntryId:String)
    {
        self.content = contentOfFile
        self.id = mediaEntryId
    }
    
    
    public func loadMedia(callback: (ResponseElemnt<MediaEntry>) -> Void) {
        
        if self.content == nil {
            guard let stringPath = self.url?.absoluteString else {return }
            self.content = NSData(contentsOfFile: stringPath) as Data?
        }
        
        guard let content = self.content  else {
            callback(ResponseElemnt<MediaEntry>(response: nil, succedded: false, error:MockError.fileIsEmptyOrNotFound)); return}
        guard  let jsonObjects: JSON = JSON(data:self.content!), jsonObjects != .null  else {
            callback(ResponseElemnt<MediaEntry>(response: nil, succedded: false, error:MockError.invalidJSON)); return}
        guard let jsonObject: JSON = jsonObjects[self.id] , jsonObject != .null else {
            callback(ResponseElemnt<MediaEntry>(response: nil, succedded: false, error:MockError.mediaNotFound)); return}
        let mediaEntry : MediaEntry = MediaEntry(json: jsonObject)
        callback(ResponseElemnt(response: mediaEntry, succedded: true, error:nil))
    }
    
}
