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
    func register(user: User, username: String, password: String, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> Session.Task{
        let body = RegisterUsernameRequest(username: username, password: password, firstName: user.firstName, lastName: user.lastName)
        let request = URLRequest(session: session, path: "register/username", method: .post, body: body)
        return session.runningTask(with: request, completion: captureAuthToken(completion: completion))
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
    func register(user: User, key: String, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> Session.Task{
        let body = RegisterKeyRequest(key: key, firstName: user.firstName, lastName: user.lastName)
        let request = URLRequest(session: session, path: "register/key", method: .post, body: body)
        return session.runningTask(with: request, completion: captureAuthToken(completion: completion))
    }
    
    func authenticate(credentials: Credentials, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> Session.Task{
        if let keyCredentials = credentials as? KeyCredentials{
            return authenticate(key: keyCredentials.key, completion: completion)
        }
        if let usernameCredentials = credentials as? UsernameCredentials{
            return authenticate(username: usernameCredentials.username, password: usernameCredentials.password, completion: completion)
        }
        return session.runningTask(with: nil, completion: completion)
    }
    
    /// Authenticate using a username
    ///
    /// - parameters:
    ///   - username: The usrename to login with
    ///   - password: The password to use
    ///   - completion: The block to call when the task has completed
    ///   - authentication: The authentication response
    /// - returns: The URL session task that is making the remote request for preferences data
    func authenticate(username: String, password: String, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> Session.Task{
        let body = AuthUsernameRequest(username: username, password: password)
        let request = URLRequest(session: session, path: "auth/username", method: .post, body: body)
        return session.runningTask(with: request, completion: captureAuthToken(completion: completion))
    }
    
    /// Authenticate using a secret key
    ///
    /// - parameters:
    ///   - key: The secret key
    ///   - completion: The block to call when the task has loaded
    ///   - success: Whether the save request succeeded
    /// - returns: The URL session task that is making the remote request for preferences data
    func authenticate(key: String, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> Session.Task{
        let body = AuthKeyRequest(key: key)
        let request = URLRequest(session: session, path: "auth/key", method: .post, body: body)
        return session.runningTask(with: request, completion: captureAuthToken(completion: completion))
    }
    
    private func captureAuthToken(completion: @escaping (AuthentiationResponse?) -> Void) -> (AuthentiationResponse?) -> Void{
        return {
            auth in
            if let token = auth?.token{
                self.session.authToken = token
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
