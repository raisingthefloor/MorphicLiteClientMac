//
//  User.swift
//  MorphicCore
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

/// A Morphic user
public struct User: Codable{
    
    // MARK: - Creating a User
    
    /// Create a new user by generating a new globally unique identifier
    ///
    /// Typically used for completely new users
    public init(){
        identifier = UUID().uuidString
    }
    
    /// Create a user with a known identifier
    ///
    /// - parameter identifier: The user's unique identifier
    public init(identifier: Identifier) {
        self.identifier = identifier
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey{
        case identifier
    }
    
    public init(from decoder: Decoder) throws{
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: CodingKeys.identifier)
    }
    
    public func encode(to encoder: Encoder) throws{
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: CodingKeys.identifier)
    }
    
    // MARK: - Identification
    
    public typealias Identifier = String
    
    /// A globally unique identifier for the user
    public var identifier: Identifier
    
}
