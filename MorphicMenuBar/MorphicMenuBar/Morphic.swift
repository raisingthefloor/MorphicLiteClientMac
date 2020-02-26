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

private let logger = OSLog(subsystem: "app", category: "morhpic")

/// Keeps track of common app objects and data
///
/// Makes it easy for various application components to use the same shared objects and data
class Morphic{

   /// A singleton object to use
    static var shared = Morphic()
    
    private init(){
    }
    
    // MARK: - Common Service Information
    
    /// The custom URL session to use when making requests to the Morphic service
    ///
    /// Currently coded as a private session, but this may change as we build out the application based
    /// on needs such as cookie retention
    lazy var session: URLSession = {
        return URLSession(configuration: .ephemeral)
    }()
    
    /// The root URL endpoint for the Morphic service
    ///
    /// Obtained from the `MorhpicServiceEndpoint` entry in `Info.plist`, which itself is
    /// populated by the `MORPHIC_SERVICE_ENDPOINT` build configuration variable.
    ///
    /// The production endpoint URL is hard-coded in `Release.xcconfig`, and a default
    /// URL is specified in `Debug.xcconfig`, each developer can override the setting by
    /// creating a `Local.xcconfig` with whatever value is relevant to their local setup.
    lazy var endpoint: URL! = {
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
    
    enum EndpointError: Error{
        case missing
        case invalid
    }
    
    // MARK: - User Preferences
    
    /// The identifier of the current user
    var currentUserIdentifier: String?{
        get{
            return UserDefaults.morphic.string(forKey: .morphicDefaultsKeyUserIdentifier)
        }
        set{
            UserDefaults.morphic.set(newValue, forKey: .morphicDefaultsKeyUserIdentifier)
        }
    }
    
    /// The perferences for the current user
    ///
    /// Only populated after `fetchUserPreferences` is called and completes successfully
    var preferences: Preferences?
    
    /// Fetch the user preferences from the Morphic service
    ///
    /// Should be called early during app launch.
    ///
    /// Will do nothing if there is no `userIdentifier` entry yet saved in `UserDefaults`. (This
    /// design may change as we continue app development and design the login UI)
    func fetchUserPreferences(){
        guard let identifier = currentUserIdentifier else{
            return
        }
        preferencesFetchTask?.cancel()
        let user = User(identifier: identifier)
        preferencesFetchTask = preferencesService.fetch(preferencesFor: user){
            preferences in
            self.preferences = preferences
            self.preferencesFetchTask = nil
        }
    }
    
    /// Indicates if a fetch is current in progress
    var isFetchingPreferences: Bool{
        return preferencesFetchTask != nil
    }
    
    /// The preferences service
    private lazy var preferencesService = PreferencesService(endpoint: endpoint, session: session)
    
    /// The active task that is fetching user preferences, if any
    private var preferencesFetchTask: URLSessionTask?
    
    // MARK: - Configurator App
    
    func launchConfigurator(){
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "org.raisingthefloor.MorphicConfigurator") else{
            os_log(.error, log: logger, "Configurator app not found")
            return
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config){
            (app, error) in
            guard error == nil else{
                os_log(.error, log: logger, "Failed to launch configurator: %{public}s", error!.localizedDescription)
                return
            }
        }
    }
    
}
