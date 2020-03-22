//
//  Preferences.swift
//  MorphicCore
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public struct Preferences: Codable, Record{
    
    // MARK: - Creating Preferences
    
    /// Create a new preferences object from the given identifier
    ///
    /// Typically used for completely new users
    public init(identifier: String){
        self.identifier = identifier;
    }
    
    // MARK: - Identifier
    
    public static var typeName: String = "Preferences"
    
    /// The prefernces unique identifier
    public var identifier: String
    
    /// The the id of the user that the preferences belong to
    public var userId: String!
    
    // MARK: - Solution Preferences
    
    public typealias PreferencesSet = [String: Solution]
    
    /// The default map of solution identifier to solution prefs
    public var defaults: PreferencesSet?

    /// The preferences for a specific solution
    public struct Solution: Codable{
        
        /// Each solution can store arbitrary values
        public var values = [String: Interoperable?]();
        
        public init(){
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ArbitraryKeys.self)
            values = try container.decodeInteroperableDictionary()
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: ArbitraryKeys.self)
            try values.encodeElements(to: &container)
        }
        
    }
    
    public mutating func set(_ value: Interoperable?, for preference: String, in solution: String){
        if defaults == nil{
            defaults = [:]
        }
        if defaults?[solution] == nil{
            defaults?[solution] = Solution()
        }
        defaults?[solution]?.values[preference] = value
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey{
        case identifier = "Id"
        case userId = "UserId"
        case defaults = "Default"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        userId = try container.decode(String?.self, forKey: .userId)
        defaults = try container.decode(PreferencesSet?.self, forKey: .defaults)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(userId, forKey: .userId)
        try container.encode(defaults, forKey: .defaults)
    }
    
}
