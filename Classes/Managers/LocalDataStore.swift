// ===================================================================================================
// Copyright (C) 2018 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation

@objc public protocol LocalDataStore {
    func save(key: String, value: Data) throws
    func load(key: String) throws -> Data
    func remove(key: String) throws
    func exists(key: String) -> Bool
}

/// Implementation of LocalDataStore that saves data to files in the Library directory.
@objc public class DefaultLocalDataStore: NSObject, LocalDataStore {
    
    static let pkLocalDataStore = "pkLocalDataStore"
    let storageDirectory: URL
    
    @objc public static func defaultDataStore() -> DefaultLocalDataStore? {
        return try? DefaultLocalDataStore(directory: .libraryDirectory)
    }
    
    private override init() {
        fatalError("Private initializer, use a factory or `init(directory:)`")
    }
    
    static func storageDir(_ directory: FileManager.SearchPathDirectory = .libraryDirectory) throws -> URL {
        let baseDir = try FileManager.default.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: false)
        let storageDirectory = baseDir.appendingPathComponent(DefaultLocalDataStore.pkLocalDataStore, isDirectory: true)
        
        try FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true, attributes: nil)
        
        return storageDirectory
    }
    
    @objc public init(directory: FileManager.SearchPathDirectory) throws {
        try self.storageDirectory = type(of: self).storageDir(directory)
    }
    
    private func file(_ key: String) -> URL {
        return self.storageDirectory.appendingPathComponent(key)
    }
    
    @objc public func save(key: String, value: Data) throws {
        let f = file(key)
        PKLog.debug("Saving key to \(f)")
        try value.write(to: f, options: .atomic)
    }
    
    @objc public func load(key: String) throws -> Data {
        let f = file(key)
        PKLog.debug("Loading key from \(f)")
        return try Data.init(contentsOf: f, options: [])
    }
    
    @objc public func exists(key: String) -> Bool {
        return FileManager.default.fileExists(atPath: file(key).path)
    }
    
    @objc public func remove(key: String) throws {
        let f = file(key)
        PKLog.debug("Removing key at \(f)")
        try FileManager.default.removeItem(at: f)
    }
}
