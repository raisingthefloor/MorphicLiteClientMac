//
//  Storage.swift
//  MorphicCore
//
//  Created by Owen Shaw on 3/19/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import OSLog

private let logger = OSLog(subsystem: "MorphicCore", category: "Storage")

/// Application storage for Morphic on the local machine
public class Storage{
    
    /// The singleton `Storage` instance
    public private(set) static var shared = Storage()
    
    private init(){
        fileManager = .default
        root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("org.raisingthefloor.Morphic", isDirectory: true).appendingPathComponent("Data", isDirectory: true)
        queue = DispatchQueue(label: "org.raisingthefloor.Morphic.Storage", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    }
    
    public init(root url: URL){
        fileManager = .default
        root = url
        queue = DispatchQueue(label: "org.raisingthefloor.Morphic.Storage", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    }
    
    /// The file manager on which to make requests
    private var fileManager: FileManager
    
    /// The root of the Morphic storage area
    private var root: URL?
    
    /// The background queue on which to perform file operations
    private var queue: DispatchQueue
    
    // MARK: - Preferences
    
    private func url(for identifier: String, type: Record.Type) -> URL?{
        return root?.appendingPathComponent(type.typeName, isDirectory: true).appendingPathComponent(identifier).appendingPathExtension(".json")
    }
    
    /// Save the object
    ///
    /// - parameters:
    ///   - encodable: The object to save
    ///   - completion: The block to call when the save request completes
    ///   - success: Whether the object was saved successfully to disk
    public func save<RecordType>(record: RecordType, at url: URL?, completion: @escaping (_ success: Bool) -> Void) where RecordType: Encodable, RecordType: Record{
        queue.async {
            guard let url = self.url(for: record.identifier, type: RecordType.self) else{
                os_log(.error, log: logger, "Could not obtain a valid file url for saving")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            let encoder = JSONEncoder()
            guard let json = try? encoder.encode(record) else{
                os_log(.error, log: logger, "Failed to encode to JSON")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            let success = self.fileManager.createFile(atPath: url.path, contents: json, attributes: nil)
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    /// Load the object for the given identifier
    ///
    /// - parameters:
    ///   - identifier: The identifier of the object to load
    ///   - completion: The block to call with the loaded object
    ///   - document: The loaded object, or `nil` if no such identifier was saved
    public func load<RecordType>(identifier: String, completion: @escaping (_ document: RecordType?) -> Void) where RecordType: Decodable, RecordType: Record{
        queue.async {
            guard let url = self.url(for: identifier, type: RecordType.self) else{
                os_log(.error, log: logger, "Could not obtain a valid file url for loading")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            guard let data = self.fileManager.contents(atPath: url.path) else{
                os_log(.error, log: logger, "Could not read data")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            let decoder = JSONDecoder()
            guard let record = try? decoder.decode(RecordType.self, from: data) else{
                os_log(.error, log: logger, "Could not decode JSON")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async {
                completion(record)
            }
        }
    }
    
}
