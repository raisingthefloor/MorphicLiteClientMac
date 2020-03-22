//
//  MorphicService.swift
//  MorphicService
//
//  Created by Owen Shaw on 3/18/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicService", category: "Service")

/// Base class for all morphic services
public class Service{
    
    // MARK: - Creating a Service
    
    /// Create a service at the given endpoint using the given session
    ///
    /// - parameters:
    ///   - endpoint: The location of the remote server
    ///   - session: The URL session to use for requests to the remote server
    public init(endpoint: URL, session: Session){
        self.endpoint = endpoint
        self.session = session
    }
    
    // MARK: - Location
    
    /// The location of the remote server
    public private(set) var endpoint: URL
    
    /// The URL session to use when making requests to the remote server
    public private(set) weak var session: Session!
}
