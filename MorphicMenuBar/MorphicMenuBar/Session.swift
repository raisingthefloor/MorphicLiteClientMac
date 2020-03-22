//
//  Morphic.swift
//  MorphicMenuBar
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import OSLog
import MorphicCore
import MorphicService

private let logger = OSLog(subsystem: "app", category: "Session")

/// Extension to MorphicService.Session to create a shared session for the app
extension Session{
    
    static var shared: Session = {
        return Session(endpoint: Session.mainBundleEndpoint)
    }()
    
    /// The root URL endpoint for the Morphic service
    ///
    /// Obtained from the `MorhpicServiceEndpoint` entry in `Info.plist`, which itself is
    /// populated by the `MORPHIC_SERVICE_ENDPOINT` build configuration variable.
    ///
    /// The production endpoint URL is hard-coded in `Release.xcconfig`, and a default
    /// URL is specified in `Debug.xcconfig`, each developer can override the setting by
    /// creating a `Local.xcconfig` with whatever value is relevant to their local setup.
    static var mainBundleEndpoint: URL! = {
        guard let endpointString = Bundle.main.infoDictionary?["MorphicServiceEndpoint"] as? String else{
            os_log(.fault, log: logger, "Missing morphic endpoint.  Check build config files")
            return nil
        }
        guard let endpoint = URL(string: endpointString) else{
            os_log(.fault, log: logger, "Invalid morphic endpoint.  Check build config files")
            return nil
        }
        return endpoint
    }()
    
}
