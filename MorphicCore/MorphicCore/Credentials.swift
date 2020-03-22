//
//  Credentials.swift
//  MorphicCore
//
//  Created by Owen Shaw on 3/22/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

/// Morphic authentication credentials
public protocol Credentials{
}

/// Secret key based credentials
public struct KeyCredentials: Credentials{
    public var key: String
    
    public init(key: String){
        self.key = key
    }
}

/// Username/password credentials
public struct UsernameCredentials: Credentials{
    public var username: String
    public var password: String
    
    public init(username: String, password: String){
        self.username = username
        self.password = password
    }
    
}
