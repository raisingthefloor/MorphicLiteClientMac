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
public class PreferencesService{
    
    // MARK: - Creating a Preferences Service
    
    /// Create a preferences service at the given endpoint using the given session
    ///
    /// - parameters:
    ///   - endpoint: The location of the remote server
    ///   - session: The URL session to use for requests to the remote server
    public init(endpoint: URL, session: URLSession){
        self.endpoint = endpoint
        self.session = session
    }
    
    /// Create a preferences service at the given endpoint
    ///
    /// - parameter endpoint: The location of the remote server
    public convenience init(endpoint: URL){
        self.init(endpoint: endpoint, session: .shared)
    }
    
    // MARK: - Location
    
    /// The location of the remote server
    public private(set) var endpoint: URL
    
    /// The URL session to use when making requests to the remote server
    public private(set) var session: URLSession
    
    // MARK: - Requests
    
    private lazy var preferencesBaseURL: URL = URL(string: "preferences/", relativeTo: endpoint)!
    private func preferencesURL(for user: User) -> URL{
        return preferencesBaseURL.appendingPathComponent(user.identifier)
    }
    
    /// Fetch the preferences for the given user
    ///
    /// - parameters:
    ///   - user: The user to fetch preferences for
    ///   - completion: The block to call when the task has loaded
    ///   - preferences: The preferences for the user, if the load was successful
    /// - returns: The URL session task that is making the remote request for preferences data
    public func fetch(preferencesFor user: User, completion: @escaping (_ preferences: Preferences?) -> Void) -> URLSessionTask{
        return session.runningDataTask(with: preferencesURL(for: user), completion: completion)
    }
    
    /// Save the preferences for the given user
    ///
    /// - parameters:
    ///   - preferences: The preferences to save
    ///   - user: The user to save preferences for
    ///   - completion: The block to call when the task has loaded
    ///   - success: Whether the save request succeeded
    /// - returns: The URL session task that is making the remote request for preferences data
    public func save(_ preferences: Preferences, for user: User, completion: @escaping (_ success: Bool) -> Void) -> URLSessionTask?{
        return session.runningDataTask(with: preferencesURL(for: user), jsonEncodable: preferences, method: .put, completion: completion)
    }
    
}
