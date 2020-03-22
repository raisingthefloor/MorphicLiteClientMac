//
//  UserService.swift
//  MorphicService
//
//  Created by Owen Shaw on 3/22/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore

/// Interface to the remote Morphic preferences server
public extension Service{
    
    // MARK: - Requests
    
    /// Fetch the preferences for the given user
    ///
    /// - parameters:
    ///   - user: The user's identifier
    ///   - completion: The block to call when the task has loaded
    ///   - user: The user, if the load was successful
    /// - returns: The URL session task that is making the remote request for user data
    func fetch(user identifier: String, completion: @escaping (_ user: User?) -> Void) -> Session.Task{
        let request = URLRequest(session: session, path: "users/\(identifier)", method: .get)
        return session.runningTask(with: request, completion: completion)
    }
    
    /// Save the preferences for the given user
    ///
    /// - parameters:
    ///   - preferences: The user to save
    ///   - user: The user to save
    ///   - completion: The block to call when the task has loaded
    ///   - success: Whether the save request succeeded
    /// - returns: The URL session task that is making the remote request for user data
    func save(_ user: User, completion: @escaping (_ success: Bool) -> Void) -> Session.Task{
        let request = URLRequest(session: session, path: "preferences/\(user.identifier)", method: .put, body: user)
        return session.runningTask(with: request, completion: completion)
    }
    
}
