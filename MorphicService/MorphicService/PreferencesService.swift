//
//  PreferencesService.swift
//  MorphicService
//
//  Created by Owen Shaw on 2/25/20.
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
    ///   - user: The user to fetch preferences for
    ///   - completion: The block to call when the task has loaded
    ///   - preferences: The preferences for the user, if the load was successful
    /// - returns: The URL session task that is making the remote request for preferences data
    func fetch(preferencesFor user: User, completion: @escaping (_ preferences: Preferences?) -> Void) -> URLSessionTask{
        let request = URLRequest(service: self, path: "preferences/\(user.preferencesId!)", method: .get)
        return session.runningDataTask(with: request, completion: completion)
    }
    
    /// Save the preferences for the given user
    ///
    /// - parameters:
    ///   - preferences: The preferences to save
    ///   - user: The user to save preferences for
    ///   - completion: The block to call when the task has loaded
    ///   - success: Whether the save request succeeded
    /// - returns: The URL session task that is making the remote request for preferences data
    func save(_ preferences: Preferences, for user: User, completion: @escaping (_ success: Bool) -> Void) -> URLSessionTask?{
        guard let request = URLRequest(service: self, path: "preferences/\(user.preferencesId!)", method: .put, body: preferences) else{
            return nil
        }
        return session.runningDataTask(with: request, completion: completion)
    }
    
}
