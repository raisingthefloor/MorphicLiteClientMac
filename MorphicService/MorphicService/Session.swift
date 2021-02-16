// Copyright 2020 Raising the Floor - International
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Foundation
import MorphicCore
import MorphicSettings
import OSLog
import CryptoKit

private let logger = OSLog(subsystem: "MorphicService", category: "Session")

/// Manage a user's session with Morphic
public class Session {
    /// Create a new session that talks to the given endpoint
    public init(endpoint: URL) {
        urlSession = URLSession(configuration: .ephemeral)
        service = Service(endpoint: endpoint, session: self)
    }
    
    /// The underlying URL Session
    public private(set) var urlSession: URLSession
    
    /// The Morphic Service
    public private(set) var service: Service!
    
    /// Open a session, fetching the current user's data if we have saved credentials
    public func open(completion: @escaping () -> Void) {
        let loadPreferences = {
            let identifier = self.user?.preferencesId ?? "__default__"
            self.storage.load(identifier: identifier) {
                (status: Storage.LoadStatus, prefs: Preferences?) in
                switch status {
                case .success:
                    self.preferences = prefs
                case .fileUrlMissing,
                     .couldNotReadFile,
                     .couldNotDecodeJson:
                    // NOTE: this may be informational (file does not exist) or it may be an error (file was corrupt)
                    os_log(.error, log: logger, "Could not retrieve preferences from storage")
                    
                    // degrade gracefully: initialize a default set of preferences
                    self.preferences = Preferences(identifier: identifier)
                }
                
                completion()
            }
        }
        if let userId = currentUserIdentifier {
            storage.load(identifier: userId) {
                (_, user: User?) in
                self.user = user
                loadPreferences()
            }
        } else {
            loadPreferences()
        }
    }
    
    // MARK: - Storage
    
    /// The local storage of cached Morphic data
    lazy public private(set) var storage = Storage.shared
    
    // MARK: - Settings
    
    /// The local storage of cached Morphic data
    lazy public private(set) var settings = SettingsManager.shared
    
    // MARK: - Requests
    
    /// Create a data task that decodes a JSON object from the response
    ///
    /// Expects the `Content-Type` response header to be `application/json; charset=utf-8`
    ///
    /// - parameters:
    ///   - request: The URL request
    ///   - completion: The block to call when the request completes
    ///   - response: The `Decodable` object that was sent as a response
    ///
    /// - returns: The created task
    func runningTask<ResponseBody>(with request: URLRequest?, completion: @escaping (_ response: ResponseBody?) -> Void) -> Task where ResponseBody: Decodable {
        return runningTask(with: request) {
            (response: Service.Response<ResponseBody, EmptyBadRequestBody>) in
            switch response {
            case .success(let body):
                completion(body)
            case .badRequest, .failed:
                completion(nil)
            }
        }
    }
    
    /// Create a data task that decodes a JSON object from the response, or decodes an error response from a 400 result
    ///
    /// Expects the `Content-Type` response header to be `application/json; charset=utf-8`
    ///
    /// - parameters:
    ///   - request: The URL request
    ///   - completion: The block to call when the request completes
    ///   - response: The respone status
    ///
    /// - returns: The created task
    func runningTask<ResponseBody, BadRequestBody>(with request: URLRequest?, completion: @escaping (_ response: Service.Response<ResponseBody, BadRequestBody>) -> Void) -> Task where ResponseBody: Decodable, BadRequestBody: Decodable {
        if var request = request {
            let handleResponse: (_ response: URLResponse?, _ data: Data?) -> Void = {
                response, data in
                guard let response = response else {
                    DispatchQueue.main.async {
                        completion(.failed)
                    }
                    return
                }
                if response.morphicBadRequest {
                    if let body: BadRequestBody = response.morphicObject(from: data, for: 400) {
                        DispatchQueue.main.async {
                            completion(.badRequest(body: body))
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        completion(.failed)
                    }
                    return
                }
                if let body: ResponseBody = response.morphicObject(from: data) {
                    DispatchQueue.main.async {
                        completion(.success(body: body))
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(.failed)
                }
            }
            os_log(.info, log: logger, "%{public}s %{public}s", request.httpMethod!, request.url!.path)
            let task = Task()
            task.urlTask = urlSession.dataTask(with: request) {
                data, response, error in
                os_log(.error, log: logger, "%d %{public}s", (response as? HTTPURLResponse)?.statusCode ?? 0, request.url!.path)
                if response?.requiresMorphicAuthentication ?? false {
                    // If our token expired, try to reauthenticate with saved credentials
                    task.urlTask = self.authenticate {
                        success in
                        if success {
                            // If we got a new token, try the request again
                            os_log(.info, log: logger, "%{public}s %{public}s", request.httpMethod!, request.url!.path)
                            request.setValue(self.authToken, forHTTPHeaderField: "X-Morphic-Auth-Token")
                            task.urlTask = self.urlSession.dataTask(with: request) {
                                data, response, error in
                                os_log(.error, log: logger, "%d %{public}s", (response as? HTTPURLResponse)?.statusCode ?? 0, request.url!.path)
                                handleResponse(response, data)
                            }
                            task.urlTask?.resume()
                        } else {
                            os_log(.info, log: logger, "Authentication failed")
                            DispatchQueue.main.async {
                                completion(.failed)
                            }
                        }
                    }
                } else {
                    handleResponse(response, data)
                }
            }
            task.urlTask?.resume()
            return task
        }
        DispatchQueue.main.async {
            completion(.failed)
        }
        return Task()
    }
    
    private struct EmptyBadRequestBody: Decodable {
    }
    
    /// Create a data task that results in a yes/no response
    ///
    /// The completion function has a single `Bool` argument, ideal for cases that don't return any data
    ///
    /// Sets the `Content-Type` header to `application/json; charset=utf-8`
    ///
    /// - parameters:
    ///   - request: The URL request
    ///   - completion: The block to call when the request completes
    ///   - success: Whether the request succeeded
    ///
    /// - returns: The created task
    func runningTask(with request: URLRequest?, completion: @escaping (_ success: Bool) -> Void) -> Task {
        if var request = request {
            let task = Task()
            os_log(.info, log: logger, "%{public}s %{public}s", request.httpMethod!, request.url!.path)
            task.urlTask = urlSession.dataTask(with: request) {
                data, response, error in
                os_log(.error, log: logger, "%d %{public}s", (response as? HTTPURLResponse)?.statusCode ?? 0, request.url!.path)
                if response?.requiresMorphicAuthentication ?? false {
                    // If our token expired, try to reauthenticate with saved credentials
                    task.urlTask = self.authenticate {
                        success in
                        if success {
                            // If we got a new token, try the request again
                            request.setValue(self.authToken, forHTTPHeaderField: "X-Morphic-Auth-Token")
                            os_log(.info, log: logger, "%{public}s %{public}s", request.httpMethod!, request.url!.path)
                            task.urlTask = self.urlSession.dataTask(with: request) {
                                data, response, error in
                                os_log(.error, log: logger, "%d %{public}s", (response as? HTTPURLResponse)?.statusCode ?? 0, request.url!.path)
                                DispatchQueue.main.async {
                                    completion(response?.morphicSuccess ?? false)
                                }
                            }
                            task.urlTask?.resume()
                        } else {
                            os_log(.info, log: logger, "Authentication failed")
                            DispatchQueue.main.async {
                                completion(false)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(response?.morphicSuccess ?? false)
                    }
                }
            }
            task.urlTask?.resume()
            return task
        }
        DispatchQueue.main.async {
            completion(false)
        }
        return Task()
    }
    
    /// A cancelable session task
    ///
    /// May encapsulate several sequential URL requests.  For example, if the intial request fails
    /// due to authentication, an auth request will be made followed by a retry of the original request.
    public class Task {
        
        /// The underlying URL session task
        var urlTask: URLSessionTask?
        
        init() {
        }
        
        init(urlTask: URLSessionTask) {
            self.urlTask = urlTask
        }
        
        /// Cancel the task
        public func cancel() {
            urlTask?.cancel()
        }
        
    }
    
    // MARK: - Authentication
    
    /// The keychain to use for user secrets
    lazy var keychain = Keychain.shared
    
    private var temporarAuthToken: String?
    
    /// Get the saved secret key login from the keychain
    public var authToken: String? {
        get {
            if let identifier = currentUserIdentifier {
                return temporarAuthToken ?? keychain.authToken(for: service.endpoint, userIdentifier: identifier)
            }
            return temporarAuthToken
        }
        set {
            guard let identifier = currentUserIdentifier else {
                return
            }
            if let token = newValue {
                if !keychain.save(authToken: token, for: service.endpoint, userIdentifier: identifier) {
                    os_log(.fault, log: logger, "Failed to save token to keychain")
                }
            } else {
                if !keychain.removeAuthToken(for: service.endpoint, userIdentifier: identifier) {
                    os_log(.fault, log: logger, "Failed to remove secret to keychain")
                }
            }
        }
    }
    
    /// Authenticate the user using whatever saved secret we have
    private func authenticate(completion: @escaping (_ success: Bool) -> Void) -> URLSessionTask? {
        if let identifier = currentUserIdentifier, let creds = credentialsForCurrentUser {
            let task = service.authenticate(credentials: creds) {
                auth in
                if let auth = auth {
                    _ = self.keychain.save(authToken: auth.token, for: self.service.endpoint, userIdentifier: identifier)
                    completion(true)
                } else {
                    completion(false)
                }
            }
            return task.urlTask
        }
        DispatchQueue.main.async {
            completion(false)
        }
        return nil
    }
    
    /// Get the credentials for the current user
    private var credentialsForCurrentUser: Credentials? {
        guard let identifier = currentUserIdentifier else {
            return nil
        }
        if let username = UserDefaults.morphic.morphicUsername(for: identifier) {
            if let creds = keychain.usernameCredentials(for: service.endpoint, username: username) {
                return creds
            }
        }
        return keychain.keyCredentials(for: service.endpoint, userIdentifier: identifier)
    }
    
    public func authenticate(usingUsername credentials: UsernameCredentials, completion: @escaping (_ success: Bool) -> Void) -> URLSessionTask? {
        let task = service.authenticate(username: credentials.username, password: credentials.password) {
            auth in
            if let auth = auth {
                _ = self.keychain.save(usernameCredentials: credentials, for: self.service.endpoint)
                UserDefaults.morphic.set(morphicUsername: credentials.username, for: auth.user.identifier)
                self.user = auth.user
                self.authToken = auth.token
                self.signin(user: auth.user, preFetchedPreferences: nil) {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
        return task.urlTask
    }
    
    // MARK: - User Info
    
    /// The identifier of the current user
    var currentUserIdentifier: String? {
        get {
            return UserDefaults.morphic.string(forKey: .morphicDefaultsKeyUserIdentifier)
        }
        set {
            UserDefaults.morphic.set(newValue, forKey: .morphicDefaultsKeyUserIdentifier)
        }
    }
    
    var selectedUserCommunityIdentifier: String? {
        get {
            guard let currentUserIdentifier = self.currentUserIdentifier else {
                return nil
            }
            return UserDefaults.morphic.selectedUserCommunityId(for: currentUserIdentifier)
        }
        set {
            guard let currentUserIdentifier = self.currentUserIdentifier else {
                return
            }
            UserDefaults.morphic.set(selectedUserCommunityIdentifier: newValue, for: currentUserIdentifier)
        }
    }
    
    /// The current user
    public var user: User? {
        didSet {
            currentUserIdentifier = user?.identifier
        }
    }
    
    public var isCaptureAndApplyEnabled: Bool = true
    public var isServerPreferencesSyncEnabled: Bool = true
    
    private func signin(user: User, preFetchedPreferences: Preferences?, completion: @escaping () -> Void) {
        let saveDefaultPreferencesIfNeeded: (@escaping () -> Void) -> Void = {
            completion in
            if self.user == nil {
                if self.isCaptureAndApplyEnabled == true {
                    // If we're going from no user to a logged in user, capture the
                    // computer's current settings as the default preference that will
                    // be applied back when the user logs out.
                    if let preferences = self.preferences {
                        if preferences.identifier == "__default__" {
                            let capture = CaptureSession(settingsManager: self.settings, preferences: preferences)
                            capture.addAllSolutions()
                            capture.run {
                                self.storage.save(record: capture.preferences) {
                                    success in
                                    completion()
                                }
                            }
                        }
                    }
                } else {
                    completion()
                }
            } else {
                // If we are going from one user to another, we don't want to do
                // anything because the computer's current settings are the first
                // user's rather than whatever the computer was before that user
                // logged in
                completion()
            }
        }
        
        let fetchPreferencesIfNeeded: (@escaping (_ preferences: Preferences?) -> Void) -> Void = {
            completion in
            if self.isServerPreferencesSyncEnabled == true {
                if let preferences = preFetchedPreferences {
                    completion(preferences)
                } else {
                    _ = self.service.fetch(userPreferences: user, completion: completion)
                }
            } else {
                // create empty preference set
                var preferences = Preferences(identifier: user.identifier)
                preferences.userId = user.preferencesId
                completion(preferences)
            }
        }
        
        saveDefaultPreferencesIfNeeded {
            self.user = user
            fetchPreferencesIfNeeded {
                preferences in
                self.preferences = preferences
                self.storage.save(record: user) {
                    success in
                    if preferences != nil {
                        self.storage.save(record: preferences!) {
                            success in
                            completion()
                            NotificationCenter.default.post(name: .morphicSessionUserDidChange, object: self)
                        }
                    } else {
                        completion()
                        NotificationCenter.default.post(name: .morphicSessionUserDidChange, object: self)
                    }
                }
            }
        }
    }
    
    public func signout(completion: @escaping () -> Void) {
        user = nil
        authToken = nil
        storage.load(identifier: "__default__") {
            (_, defaultPreferences: Preferences?) in
            if self.isCaptureAndApplyEnabled == true {
                self.preferences = defaultPreferences
                let apply = ApplySession(settingsManager: self.settings, preferences: defaultPreferences!)
                apply.run {
                    completion()
                    NotificationCenter.default.post(name: .morphicSessionUserDidChange, object: self)
                }
            } else {
                completion()
                NotificationCenter.default.post(name: .morphicSessionUserDidChange, object: self)
            }
        }
    }
    
    public func register(user: User, credentials: UsernameCredentials, preferences: Preferences, completion: @escaping (_ result: RegistrationResult) -> Void) {
        _ = service.register(user: user, username: credentials.username, password: credentials.password) {
            result in
            switch result {
            case .success(let auth):
                if !self.keychain.save(usernameCredentials: credentials, for: self.service.endpoint) {
                    os_log(.error, log: logger, "Failed to save newly registered username credentials")
                }
                if !self.keychain.save(authToken: auth.token, for: self.service.endpoint, userIdentifier: auth.user.identifier) {
                    os_log(.error, log: logger, "Failed to save newly registered auth token")
                }
                var createdUser = auth.user
                createdUser.email = createdUser.email ?? user.email
                var createdPreferences = preferences
                createdPreferences.identifier = createdUser.preferencesId
                createdPreferences.userId = createdUser.identifier
                self.temporarAuthToken = auth.token
                _ = self.service.save(createdPreferences) {
                    _ in
                    self.temporarAuthToken = nil
                    UserDefaults.morphic.set(morphicUsername: credentials.username, for: auth.user.identifier)
                    self.signin(user: createdUser, preFetchedPreferences: createdPreferences) {
                        completion(result)
                    }
                }
            default:
                completion(result)
            }
        }
    }
    
    // MARK: Community Bar
    
    func downloadMorphicUserCommunity(user: User, userCommunity: Service.UserCommunity, completion: @escaping (_ success: Bool, _ userCommunityDetails: Service.UserCommunityDetails?) -> Void) {
        _ = self.service.userCommunityDetails(user: user, community: userCommunity) {
            userCommunityDetails in
            if let userCommunityDetails = userCommunityDetails {
                completion(true, userCommunityDetails)
                return
            } else {
                completion(false, nil)
            }
        }
    }
    
    func downloadMorphicUserCommunities(user: User, userCommunities: [Service.UserCommunity], completion: @escaping (_ success: Bool, _ detailsByUserCommunityId: [String : Service.UserCommunityDetails]?) -> Void) {
        var userCommunityQueue = userCommunities
        
        var detailsByUserCommunityId: [String : Service.UserCommunityDetails] = [:]
        
        var downloadNextCommunity: (() -> Void)!
        downloadNextCommunity = {
            if userCommunityQueue.count == 0 {
                // if we're all out of communities, return our result
                completion(true, detailsByUserCommunityId)
                return
            }
            
            let userCommunity = userCommunityQueue.removeFirst()
            
            // download the next userCommunity in our queue
            self.downloadMorphicUserCommunity(user: user, userCommunity: userCommunity) {
                success, userCommunityDetails in
                //
                guard success == true else {
                    completion(false, nil)
                    return
                }
                
                // if we successfully downloaded the user community, add its details to our response and then call ourselves again
                detailsByUserCommunityId[userCommunity.id] = userCommunityDetails
                downloadNextCommunity()
            }
        }
        // start the download chain by downloading the first community
        downloadNextCommunity()
    }

    public func downloadAndSaveMorphicUserCommunities(user: User, completion: @escaping (_ success: Bool) -> Void) {
        _ = self.service.userCommunities(user: user) {
            userCommunities in
                        
            if let userCommunities = userCommunities {
                self.downloadMorphicUserCommunities(user: user, userCommunities: userCommunities.communities) {
                    success, detailsByUserCommunityId in
                    
                    if success == false {
                        completion(false)
                        return
                    }
                    
                    var communityBarsItems: [String: String] = [:]
                    
                    // encode each community bar's items into JSON and then store them all
                    for (userCommunityId, userCommunityDetails) in detailsByUserCommunityId! {
                        let userCommunityDetailsAsJsonData = try! JSONEncoder().encode(userCommunityDetails)
                        let userCommunityDetailsAsJsonString = String(data: userCommunityDetailsAsJsonData, encoding: .utf8)!
                        communityBarsItems[userCommunityId] = userCommunityDetailsAsJsonString
                    }

                    self.set(communityBarsItems, for: .morphicCustomMorphicBarsAsJson)
                    self.savePreferences(waitFiveSecondsBeforeSave: false) {
                        success in
                        
                        completion(success)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    // MARK: Fields
    
    /// The initial default preferences
    public static var initialPreferences: Preferences?
    
    /// The current user's preferences
    public var preferences: Preferences?
    
    public func apply(_ value: Interoperable?, for key: Preferences.Key, completion: @escaping (_ success: Bool) -> Void) {
        settings.apply(value, for: key, completion: completion)
    }
    
    public func set(_ value: Interoperable?, for key: Preferences.Key) {
        preferences?.set(value, for: key)
        savePreferences(waitFiveSecondsBeforeSave: true) { _ in }
    }

    public func set(_ value: [Interoperable?], for key: Preferences.Key) {
        preferences?.set(value, for: key)
        savePreferences(waitFiveSecondsBeforeSave: true) { _ in }
    }
    
    public func set(_ value: [String: Interoperable?], for key: Preferences.Key) {
        preferences?.set(value, for: key)
        savePreferences(waitFiveSecondsBeforeSave: true) { _ in }
    }

    public func string(for key: Preferences.Key) -> String? {
        return (preferences?.get(key: key) ?? Session.initialPreferences?.get(key: key)) as? String
    }
    
    public func int(for key: Preferences.Key) -> Int? {
        return (preferences?.get(key: key) ?? Session.initialPreferences?.get(key: key)) as? Int
    }
    
    public func double(for key: Preferences.Key) -> Double? {
        return (preferences?.get(key: key) ?? Session.initialPreferences?.get(key: key)) as? Double
    }
    
    public func bool(for key: Preferences.Key) -> Bool? {
        return (preferences?.get(key: key) ?? Session.initialPreferences?.get(key: key)) as? Bool
    }
    
    public func array(for key: Preferences.Key) -> [Interoperable?]? {
        return (preferences?.get(key: key) ?? Session.initialPreferences?.get(key: key)) as? [Interoperable?]
    }
    
    public func dictionary(for key: Preferences.Key) -> [String: Interoperable?]? {
        return (preferences?.get(key: key) ?? Session.initialPreferences?.get(key: key)) as? [String: Interoperable?]
    }
    
    public func applyAllPreferences(completion: @escaping () -> Void) {
        guard let preferences = self.preferences else {
            completion()
            return
        }
        let apply = ApplySession(settingsManager: settings, preferences: preferences)
        apply.run(completion: completion)
    }
    
    public private(set) var preferencesSaveIsQueued: Bool = false
    
    /// Save the preferences after a delay
    ///
    /// Allows many rapid changes to be batched into a single HTTP request
    public func savePreferences(waitFiveSecondsBeforeSave: Bool, completion: @escaping (_ success: Bool) -> Void) {
        os_log(.error, log: logger, "Queueing preferences save")
        preferencesSaveIsQueued = true
        preferencesSaveTimer?.invalidate()
        
        let savePreferencesAsynchronously: (() -> Void) = {
            self.preferencesSaveIsQueued = false
            self.preferencesSaveTimer = nil
            if let preferences = self.preferences {
                os_log(.info, log: logger, "Saving preferences to disk")
                self.savePreferencesToDisk {
                    success in
                    if self.isServerPreferencesSyncEnabled == true {
                        if self.user != nil {
                            os_log(.info, log: logger, "Saving preferences to server")
                            if preferences.userId != nil {
                                _ = self.service.save(preferences) {
                                    success in
                                    if success {
                                        os_log(.info, log: logger, "Saved preferences to server")
                                        completion(true)
                                        return
                                    } else {
                                        os_log(.error, log: logger, "Failed to save preference to server")
                                        completion(true)
                                        return
                                    }
                                }
                            } else {
                                os_log(.error, log: logger, "Failed to save preference to server because userId is nil")
                                completion(false)
                                return
                            }
                        } else {
                            completion(true)
                            return
                        }
                    } else {
                        // in Morphic Community, we do not save preferences to the server
                        completion(success)
                        return
                    }
                }
            } else {
                os_log(.error, log: logger, "Save preferences timer fired with nil preferences")
                completion(false)
                return
            }
        }
        
        if waitFiveSecondsBeforeSave == true {
            preferencesSaveTimer = .scheduledTimer(withTimeInterval: 5, repeats: false) {
                timer in
                //
                savePreferencesAsynchronously()
            }
        } else {
            savePreferencesAsynchronously()
        }
    }
    
    private func savePreferencesToDisk(callback: @escaping (Bool) -> ()) {
        if let preferences = self.preferences {
            os_log(.info, log: logger, "Saving preferences to disk")
            self.storage.save(record: preferences) {
                success in
                if success {
                    os_log(.info, log: logger, "Saved preferences to disk")
                } else {
                    os_log(.error, log: logger, "Failed to save preferences to disk")
                }
                
                callback(success)
            }
        } else {
            os_log(.error, log: logger, "Save preferences calledd with nil preferences")

            callback(false)
        }
    }
    
    /// Timer for delayed preference saving
    private var preferencesSaveTimer: Timer?
}

// MARK: - URL Request/Response Extensions

extension URLRequest {
    
    /// Create a new request for the given morphic session
    ///
    /// Adds the morphic auth header if a saved token exists
    ///
    /// - parameters:
    ///   - session: The morphic session
    ///   - path: The relative path of the request, which will be added to the session's endpoint
    ///   - method: The request method
    init(session: Session, path: String, method: Method) {
        let url = URL(string: path, relativeTo: session.service.endpoint)!
        self.init(url: url)
        httpMethod = method.rawValue
	// NOTE: consider making the bearer token optional (so that we don't send it with login requests, etc.)
        if let token = session.authToken {
            self.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    /// Create a new request for the given morphic session and request body
    ///
    /// Adds the morphic auth header if a saved token exists
    ///
    /// Serializes the body into a JSON payload
    ///
    /// - returns: `nil` if the JSON encoding fails
    /// - parameters:
    ///   - session: The morphic session
    ///   - path: The relative path of the request, which will be added to the session's endpoint
    ///   - method: The request method
    ///   - body: The object to encode as JSON in the request body
    init?<Body>(session: Session, path: String, method: Method, body: Body) where Body: Encodable {
        self.init(session: session, path: path, method: method)
        addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        do {
            httpBody = try encoder.encode(body)
        } catch {
            os_log(.error, log: logger, "Error encoding data for %{public}s: %{public}s", String(describing: Body.self), error.localizedDescription)
            return nil
        }
    }
    
    /// Common request methods
    enum Method: String {
        
        /// `GET` requests, for reading data from a resource
        case get = "GET"
        /// `PUT` requests, for writing data to a resource
        case put = "PUT"
        /// `POST` requests, for performing custom operations
        case post = "POST"
        /// `DELETE` requests, for deleting resources
        case delete = "DELETE"
    }
}

extension HTTPURLResponse {
    // NOTE: this function re-implements functionality present in macOS 10.15 and beyond (for macOS <=10.14 compatibility)
    @available(macOS, obsoleted: 10.15)
    public func value(forHTTPHeaderField field: String) -> String? {
        // if we found a case-sensitive result, return it immediately
        if let value = self.allHeaderFields[field] {
            return value as? String
        }

        // do a case-insensitive search on the key
        for (key, value) in self.allHeaderFields {
            guard let keyAsString = key as? String else {
                continue
            }
            
            if keyAsString.caseInsensitiveCompare(field) == .orderedSame {
                return value as? String
            }
        }
        
        // if we did not find a value, return nil
        return nil
    }
}

extension URLResponse {
    
    /// Get a Morphic model object by decoding the response JSON data
    ///
    /// In order for an object to be returned:
    /// * The response object must be an `HTTPURLResponse`
    /// * The HTTP `statusCode` must be `200`
    /// * The HTTP `Content-Type` header must be `application/json; charset=utf-8`
    /// * The JSON decoding must succeed
    ///
    /// - parameters:
    ///   - data: The response data
    ///
    /// - returns: The decoded object, or `nil` if either the response or decoding failed
    func morphicObject<T>(from data: Data?, for status: Int = 200) -> T? where T : Decodable {
        guard let response = self as? HTTPURLResponse else {
            return nil
        }
        guard response.statusCode == status else {
            return nil
        }
        guard let contentType = response.value(forHTTPHeaderField: "Content-Type")?.lowercased() else {
            return nil
        }
        guard contentType == "application/json; charset=utf-8" else {
            return nil
        }
        guard let data = data else {
            return nil
        }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            os_log(.error, log: logger, "Error decoding data for %{public}s: %{public}s", String(describing: T.self), error.localizedDescription)
            return nil
        }
    }
    
    /// Check if the Morphic HTTP request succeeded
    ///
    /// In order to be considered a success:
    /// * The response object must be an `HTTPURLResponse`
    /// * The HTTP `statusCode` must be `2xx`
    var morphicSuccess: Bool {
        guard let response = self as? HTTPURLResponse else {
            return false
        }
        return response.statusCode / 100 == 2
    }
    
    /// Check if the Morphic HTTP request succeeded
    ///
    /// In order to be considered a success:
    /// * The response object must be an `HTTPURLResponse`
    /// * The HTTP `statusCode` must be `2xx`
    var morphicBadRequest: Bool {
        guard let response = self as? HTTPURLResponse else {
            return false
        }
        return response.statusCode == 400
    }
    
    /// Check if the Morphic HTTP request failed because of authentication required
    ///
    /// In order to be considered an auth failure:
    /// * The response object must be an `HTTPURLResponse`
    /// * The HTTP `statusCode` must be `401`
    var requiresMorphicAuthentication: Bool {
        guard let response = self as? HTTPURLResponse else {
            return false
        }
        return response.statusCode == 401
    }
    
}

public extension NSNotification.Name {
    
    static let appleInterfaceThemeChanged = NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification")
    
    static let morphicSessionUserDidChange = NSNotification.Name(rawValue: "org.raisingthefloor.morphicSessionUserDidChange")
    
}

public extension Preferences.Key {
    /// The preference key that stores which items appear in each community on the MorphicBar (Morphic Community managed community bar)
    static var morphicCustomMorphicBarsAsJson = Preferences.Key(solution: "org.raisingthefloor.morphic.morphicBars", preference: "customMorphicBarsAsJson")
}

// preferences which indicate that we have changed the default values for a setting once.
public extension Preferences.Key {
    static var morphicDidSetInitialColorFilterType = Preferences.Key(solution: "org.raisingthefloor.morphic.didInitialSet", preference: "colorFilterType")
    static var morphicDidSetInitialMagnifierZoomStyle = Preferences.Key(solution: "org.raisingthefloor.morphic.didInitialSet", preference: "magnifierZoomStyle")
    static var morphicDidSetInitialAutorunAfterLoginEnabled = Preferences.Key(solution: "org.raisingthefloor.morphic.didInitialSet", preference: "autorunAfterLoginEnabled")
}
