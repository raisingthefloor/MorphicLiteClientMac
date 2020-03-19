//
//  PreferencesService.swift
//  MorphicService
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore

/// Interface to the remote Morphic auth server
public extension Service{
    
    // MARK: - Requests
    
    /// Register using a username
    ///
    /// - parameters:
    ///   - user: The user info
    ///   - username: The usrename to login with
    ///   - password: The password to use
    ///   - completion: The block to call when the task has completed
    ///   - authentication: The authentication response
    /// - returns: The URL session task that is making the remote request for preferences data
    func register(user: User, username: String, password: String, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> URLSessionTask?{
        let body = RegisterUsernameRequest(username: username, password: password, firstName: user.firstName, lastName: user.lastName)
        guard let request = URLRequest(service: self, path: "register/username", method: .post, body: body) else{
            return nil
        }
        return session.runningDataTask(with: request, completion: captureAuthToken(completion: completion))
    }
    
    /// Register using a secret key
    ///
    /// - parameters:
    ///   - user: The user info
    ///   - key: The secret key to use
    ///   - password: The password to use
    ///   - completion: The block to call when the task has completed
    ///   - authentication: The authentication response
    /// - returns: The URL session task that is making the remote request for preferences data
    func register(user: User, key: String, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> URLSessionTask?{
        let body = RegisterKeyRequest(key: key, firstName: user.firstName, lastName: user.lastName)
        guard let request = URLRequest(service: self, path: "register/key", method: .post, body: body) else{
            return nil
        }
        return session.runningDataTask(with: request, completion: captureAuthToken(completion: completion))
    }
    
    /// Authenticate using a username
    ///
    /// - parameters:
    ///   - username: The usrename to login with
    ///   - password: The password to use
    ///   - completion: The block to call when the task has completed
    ///   - authentication: The authentication response
    /// - returns: The URL session task that is making the remote request for preferences data
    func authenticate(username: String, password: String, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> URLSessionTask?{
        let body = AuthUsernameRequest(username: username, password: password)
        guard let request = URLRequest(service: self, path: "auth/username", method: .post, body: body) else{
            return nil
        }
        return session.runningDataTask(with: request, completion: captureAuthToken(completion: completion))
    }
    
    /// Authenticate using a secret key
    ///
    /// - parameters:
    ///   - key: The secret key
    ///   - completion: The block to call when the task has loaded
    ///   - success: Whether the save request succeeded
    /// - returns: The URL session task that is making the remote request for preferences data
    func authenticate(key: String, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> URLSessionTask?{
        let body = AuthKeyRequest(key: key)
        guard let request = URLRequest(service: self, path: "auth/key", method: .post, body: body) else{
            return nil
        }
        return session.runningDataTask(with: request, completion: captureAuthToken(completion: completion))
    }
    
    private func captureAuthToken(completion: @escaping (AuthentiationResponse?) -> Void) -> (AuthentiationResponse?) -> Void{
        return {
            auth in
            if let token = auth?.token{
                self.authToken = token
            }
            completion(auth)
        }
    }
    
}

struct RegisterUsernameRequest: Codable{
    public var username: String
    public var password: String
    public var firstName: String?
    public var lastName: String?
}

struct RegisterKeyRequest: Codable{
    public var key: String
    public var firstName: String?
    public var lastName: String?
}

struct AuthUsernameRequest: Codable{
    public var username: String
    public var password: String
}

struct AuthKeyRequest: Codable{
    public var key: String
}

public struct AuthentiationResponse: Codable{
    
    /// The authentication token to be used in the `X-Morphic-Auth-Token` header of subsequent requests
    public var token: String
    
    /// The authenticated user information
    public var user: User
}
