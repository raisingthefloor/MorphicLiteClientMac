//
//  MorphicService.swift
//  MorphicService
//
//  Created by Owen Shaw on 3/18/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

/// Base class for all morphic services
public class Service{
    
    // MARK: - Creating a Service
    
    /// Create a service at the given endpoint using the given session
    ///
    /// - parameters:
    ///   - endpoint: The location of the remote server
    ///   - session: The URL session to use for requests to the remote server
    public init(session: URLSession, configuration: Configuration){
        self.session = session
        self.configuration = configuration
    }
    
    // MARK: - Location
    
    /// The URL session to use when making requests to the remote server
    public private(set) var session: URLSession
    
    /// Shared configuration for all services
    public private(set) var configuration: Configuration
    
    public class Configuration{

        /// The location of the remote server
        public private(set) var endpoint: URL
        
        /// The auth token string for the current session
        public var authToken: String?
        
        /// Create a config for the given endpoint
        public init(endpoint: URL){
            self.endpoint = endpoint
        }
        
        /// Get the auth token to send for the given URL, or `nil` if the URL is not within the `endpoint`
        public func authToken(for url: URL) -> String?{
            guard let token = authToken else{
                return nil
            }
            guard url.scheme == endpoint.scheme && url.host == endpoint.host && url.port == endpoint.port else{
                return nil
            }
            return token
        }
        
    }
    
}
