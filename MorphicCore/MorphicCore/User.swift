//
//  User.swift
//  MorphicCore
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

/// A Morphic user
public struct User: Codable, Record{
    
    // MARK: - Creating a User
    
    /// Create a new user by generating a new globally unique identifier
    ///
    /// Typically used for completely new users
    public init(){
        identifier = UUID().uuidString
        preferencesId = UUID().uuidString
    }
    
    /// Create a user with a known identifier
    ///
    /// - parameter identifier: The user's unique identifier
    public init(identifier: Identifier) {
        self.identifier = identifier
    }
    
    public static var typeName: String = "User"
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey{
        case identifier = "Id"
        case preferencesId = "PreferencesId"
        case firstName = "FirstName"
        case lastName = "LastName"
    }
    
    public init(from decoder: Decoder) throws{
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: CodingKeys.identifier)
        preferencesId = try container.decode(String?.self, forKey: CodingKeys.preferencesId)
        firstName = try container.decode(String?.self, forKey: CodingKeys.firstName)
        lastName = try container.decode(String?.self, forKey: CodingKeys.lastName)
    }
    
    public func encode(to encoder: Encoder) throws{
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: CodingKeys.identifier)
        try container.encode(preferencesId, forKey: CodingKeys.preferencesId)
        try container.encode(firstName, forKey: CodingKeys.firstName)
        try container.encode(lastName, forKey: CodingKeys.lastName)
    }
    
    // MARK: - Identification
    
    public typealias Identifier = String
    
    /// A globally unique identifier for the user
    public var identifier: Identifier
    
    // MARK: - Name
    
    /// The user's first name
    public var firstName: String?
    
    /// The user's last name
    public var lastName: String?
    
    // MARK: - Preferences
    
    public var preferencesId: String!
}
