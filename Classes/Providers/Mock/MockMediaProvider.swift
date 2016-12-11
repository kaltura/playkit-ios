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
        case unableToParseJSON
        case mediaNotFound
        
    }
    
    
    public var id: String
    public var url: URL?
    public var content: Data?
    
    private var objects: JSON?
  
    /**
     Constructor
     init mokc media proviedr with file url and media entry id,
     
     The file content should be as follow:
     ```
     "entryID": {
        "duration": int,
        "id": "entryID",
        "name": string,
        "sources": [
        {
            "id": "sourceid",
            "mimeType": string,
            "url": string
        }
        ]
     }
     ```
     
     - parameter fileURL full path of file
     - parameter mediaEntryId the id of the media we want to load from the file
     */
    public init(fileURL:URL, mediaEntryId:String)
    {
        self.url = fileURL
        self.id = mediaEntryId
        
    }
    
    
    /**
     Constructor
     init mokc media proviedr with file url and media entry id,
     
     The content should be json as follow:
     ```
     "entryID": {
     "duration": int,
     "id": "entryID",
     "name": string,
     "sources": [
     {
     "id": "sourceid",
     "mimeType": string,
     "url": string
     }
     ]
     }
     ```
     
     - parameter the data for loading the media
     - parameter mediaEntryId the id of the media we want to load from the file
     */
    public init(data:Data, mediaEntryId:String)
    {
        self.content = data
        self.id = mediaEntryId
    }
    
    
    public func loadMedia(callback: @escaping (Result<MediaEntry>) -> Void){
        
        if self.content == nil {
            guard let stringPath = self.url?.absoluteString else {return }
            self.content = NSData(contentsOfFile: stringPath) as Data?
        }
        
        
        guard let content = self.content  else {
            
            callback(Result(data: nil, error: MockError.fileIsEmptyOrNotFound))
            return
        }
        guard  let jsonObjects: JSON = JSON(data:self.content!), jsonObjects != .null  else {
            callback(Result(data: nil, error: MockError.unableToParseJSON))
            return
        }
        guard let jsonObject: JSON = jsonObjects[self.id] , jsonObject != .null else {
            callback(Result(data: nil, error:MockError.mediaNotFound))
            return
        }
        
        let mediaEntry : MediaEntry? = MediaEntry(json: jsonObject)
        callback(Result(data: mediaEntry, error: nil))
    }
    
    public func cancel() {
        
    }
    
}
