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
    func fetch(preferences identifier: String, completion: @escaping (_ preferences: Preferences?) -> Void) -> Session.Task{
        let request = URLRequest(session: session, path: "preferences/\(identifier)", method: .get)
        return session.runningTask(with: request, completion: completion)
    }
    
    /// Save the preferences for the given user
    ///
    /// - parameters:
    ///   - preferences: The preferences to save
    ///   - user: The user to save preferences for
    ///   - completion: The block to call when the task has loaded
    ///   - success: Whether the save request succeeded
    /// - returns: The URL session task that is making the remote request for preferences data
    func save(_ preferences: Preferences, completion: @escaping (_ success: Bool) -> Void) -> Session.Task{
        let request = URLRequest(session: session, path: "preferences/\(preferences.identifier)", method: .put, body: preferences)
        return session.runningTask(with: request, completion: completion)
    }
    
}
