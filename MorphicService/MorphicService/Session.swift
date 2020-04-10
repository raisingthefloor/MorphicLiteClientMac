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
public class Session{
    
    /// Create a new session that talks to the given endpoint
    public init(endpoint: URL){
        urlSession = URLSession(configuration: .ephemeral)
        service = Service(endpoint: endpoint, session: self)
    }
    
    /// The underlying URL Session
    public private(set) var urlSession: URLSession
    
    /// The Morphic Service
    public private(set) var service: Service!
    
    /// Open a session, fetching the current user's data if we have saved credentials
    public func open(completion: @escaping () -> Void){
        // TODO: check for USB key
        if let userId = currentUserIdentifier{
            os_log(.info, log: logger, "Saved user ID, fetching updated user info...")
            // If the user wasn't logged out, query the user info
            _ = service.fetch(user: userId){
                user in
                guard let user = user else{
                    os_log(.error, log: logger, "User info fetch failed")
                    completion()
                    return
                }
                os_log(.info, log: logger, "Setting current user, fetching preferences...")
                self.user = user
                // Query the user's preferences
                _ = self.service.fetch(preferences: user.preferencesId){
                    preferences in
                    self.preferences = preferences
                    os_log(.info, log: logger, "Setting current preferences...")
                    self.applyAllPreferences()
                    completion()
                }
            }
        }else{
            // If the user isn't logged, we're going to need to prompt
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    // MARK: - Storage
    
    /// The local storage of cached Morphic data
    lazy var storage = Storage.shared
    
    // MARK: - Settings
    
    /// The local storage of cached Morphic data
    lazy var settings = Settings.shared
    
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
    func runningTask<ResponseBody>(with request: URLRequest?, completion: @escaping (_ response: ResponseBody?) -> Void) -> Task where ResponseBody: Decodable{
        if var request = request{
            os_log(.info, log: logger, "%{public}s %{public}s", request.httpMethod!, request.url!.path)
            let task = Task()
            task.urlTask = urlSession.dataTask(with: request){
                data, response, error in
                os_log(.error, log: logger, "%d %{public}s", (response as? HTTPURLResponse)?.statusCode ?? 0, request.url!.path)
                if response?.requiresMorphicAuthentication ?? false{
                    // If our token expired, try to reauthenticate with saved credentials
                    task.urlTask = self.authenticate{
                        success in
                        if success{
                            // If we got a new token, try the request again
                            os_log(.info, log: logger, "%{public}s %{public}s", request.httpMethod!, request.url!.path)
                            request.setValue(self.authToken, forHTTPHeaderField: "X-Morphic-Auth-Token")
                            task.urlTask = self.urlSession.dataTask(with: request){
                                data, response, error in
                                os_log(.error, log: logger, "%d %{public}s", (response as? HTTPURLResponse)?.statusCode ?? 0, request.url!.path)
                                let body: ResponseBody? = response?.morphicObject(from: data)
                                DispatchQueue.main.async {
                                    completion(body)
                                }
                            }
                            task.urlTask?.resume()
                        }else{
                            os_log(.info, log: logger, "Authentication failed")
                            DispatchQueue.main.async {
                                completion(nil)
                            }
                        }
                    }
                }else{
                    let body: ResponseBody? = response?.morphicObject(from: data)
                    DispatchQueue.main.async {
                        completion(body)
                    }
                }
            }
            task.urlTask?.resume()
            return task
        }
        DispatchQueue.main.async {
            completion(nil)
        }
        return Task()
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
    func runningTask(with request: URLRequest?, completion: @escaping (_ success: Bool) -> Void) -> Task{
        if var request = request{
            let task = Task()
            os_log(.info, log: logger, "%{public}s %{public}s", request.httpMethod!, request.url!.path)
            task.urlTask = urlSession.dataTask(with: request){
                data, response, error in
                os_log(.error, log: logger, "%d %{public}s", (response as? HTTPURLResponse)?.statusCode ?? 0, request.url!.path)
                if response?.requiresMorphicAuthentication ?? false{
                    // If our token expired, try to reauthenticate with saved credentials
                    task.urlTask = self.authenticate{
                        success in
                        if success{
                            // If we got a new token, try the request again
                            request.setValue(self.authToken, forHTTPHeaderField: "X-Morphic-Auth-Token")
                            os_log(.info, log: logger, "%{public}s %{public}s", request.httpMethod!, request.url!.path)
                            task.urlTask = self.urlSession.dataTask(with: request){
                                data, response, error in
                                os_log(.error, log: logger, "%d %{public}s", (response as? HTTPURLResponse)?.statusCode ?? 0, request.url!.path)
                                DispatchQueue.main.async {
                                    completion(response?.morphicSuccess ?? false)
                                }
                            }
                            task.urlTask?.resume()
                        }else{
                            os_log(.info, log: logger, "Authentication failed")
                            DispatchQueue.main.async {
                                completion(false)
                            }
                        }
                    }
                }else{
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
    public class Task{
        
        /// The underlying URL session task
        var urlTask: URLSessionTask?
        
        init(){
        }
        
        init(urlTask: URLSessionTask){
            self.urlTask = urlTask
        }
        
        /// Cancel the task
        public func cancel(){
            urlTask?.cancel()
        }
        
    }
    
    // MARK: - Authentication
    
    /// The keychain to use for user secrets
    lazy var keychain = Keychain.shared
    
    /// Get the saved secret key login from the keychain
    public var authToken: String?{
        get{
            if let identifier = currentUserIdentifier{
                return keychain.authToken(for: service.endpoint, userIdentifier: identifier)
            }
            return nil
        }
        set{
            guard let identifier = currentUserIdentifier else{
                return
            }
            if let token = newValue{
                if !keychain.save(authToken: token, for: service.endpoint, userIdentifier: identifier){
                    os_log(.fault, log: logger, "Failed to save token to keychain")
                }
            }else{
                if !keychain.removeAuthToken(for: service.endpoint, userIdentifier: identifier){
                    os_log(.fault, log: logger, "Failed to remove secret to keychain")
                }
            }
        }
    }
    
    /// Authenticate the user using whatever saved secret we have
    private func authenticate(completion: @escaping (_ success: Bool) -> Void) -> URLSessionTask?{
        if let identifier = currentUserIdentifier, let creds = credentialsForCurrentUser{
            let task = service.authenticate(credentials: creds){
                auth in
                if let auth = auth{
                    _ = self.keychain.save(authToken: auth.token, for: self.service.endpoint, userIdentifier: identifier)
                    completion(true)
                }else{
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
    private var credentialsForCurrentUser: Credentials?{
        guard let identifier = currentUserIdentifier else{
            return nil
        }
        if let username = UserDefaults.morphic.morphicUsername(for: identifier){
            if let creds = keychain.usernameCredentials(for: service.endpoint, username: username){
                return creds
            }
        }
        return keychain.keyCredentials(for: service.endpoint, userIdentifier: identifier)
    }
    
    // MARK: - User Info
    
    /// The identifier of the current user
    var currentUserIdentifier: String?{
        get{
            return UserDefaults.morphic.string(forKey: .morphicDefaultsKeyUserIdentifier)
        }
        set{
            UserDefaults.morphic.set(newValue, forKey: .morphicDefaultsKeyUserIdentifier)
        }
    }
    
    /// The current user
    public var user: User?{
        didSet{
            currentUserIdentifier = user?.identifier
        }
    }
    
    private func signin(user: User, completion: @escaping () -> Void){
        self.user = user
        _ = self.service.fetch(preferences: user.preferencesId){
            preferences in
            self.preferences = preferences
            self.applyAllPreferences()
            completion()
        }
    }
    
    public func signout(){
        self.user = nil
        self.preferences = nil
    }
    
    public func registerUser(completion: @escaping (_ success: Bool) -> Void){
        let user = User()
        let key = SymmetricKey(size: .init(bitCount: 512))
        let base64 = key.withUnsafeBytes{
            (bytes: UnsafeRawBufferPointer) in
            Data(Array(bytes)).base64EncodedString()
        }
        _ = service.register(user: user, key: base64){
            auth in
            if let auth = auth{
                let credentials = KeyCredentials(key: base64)
                if !self.keychain.save(keyCredentials: credentials, for: self.service.endpoint, userIdentifier: auth.user.identifier){
                    os_log(.error, log: logger, "Failed to save newly registered key credentials")
                }
                if !self.keychain.save(authToken: auth.token, for: self.service.endpoint, userIdentifier: auth.user.identifier){
                    os_log(.error, log: logger, "Failed to save newly registered auth token")
                }
                self.signin(user: auth.user){
                    completion(true)
                }
            }else{
                completion(false)
            }
        }
    }
    
    public func registerUser(username: String, password: String, completion: @escaping (_ success: Bool) -> Void){
        let user = User()
        _ = service.register(user: user, username: username, password: password){
            auth in
            if let auth = auth{
                let credentials = UsernameCredentials(username: username, password: password)
                if !self.keychain.save(usernameCredentials: credentials, for: self.service.endpoint){
                    os_log(.error, log: logger, "Failed to save newly registered username credentials")
                }
                if !self.keychain.save(authToken: auth.token, for: self.service.endpoint, userIdentifier: auth.user.identifier){
                    os_log(.error, log: logger, "Failed to save newly registered auth token")
                }
                UserDefaults.morphic.set(morphicUsername: username, for: auth.user.identifier)
                self.signin(user: auth.user){
                    completion(true)
                }
            }else{
                completion(false)
            }
        }
    }
    
    /// The current user's preferences
    public var preferences: Preferences?
    
    /// Save a preference change
    ///
    /// * Updates the local preferences
    /// * Applys the change to the system
    /// * Requests a cloud save
    public func save(_ value: Interoperable?, for preference: String, in solution: String){
        os_log(.error, log: logger, "Setting preference")
        preferences?.set(value, for: preference, in: solution)
        _ = settings.apply(value, for: preference, in: solution)
        setNeedsPreferencesSave()
    }
    
    public func string(for preference: String, in solution: String) -> String?{
        return preferences?.get(preference: preference, in: solution) as? String
    }
    
    public func int(for preference: String, in solution: String) -> Int?{
        return preferences?.get(preference: preference, in: solution) as? Int
    }
    
    public func double(for preference: String, in solution: String) -> Double?{
        return preferences?.get(preference: preference, in: solution) as? Double
    }
    
    public func applyAllPreferences(){
        os_log(.error, log: logger, "Applying all preferences")
        guard let preferences = preferences else{
            return
        }
        guard let defaults = preferences.defaults else{
            return
        }
        for (solution, preferencesSet) in defaults{
            for (preference, value) in preferencesSet.values{
                _ = settings.apply(value, for: preference, in: solution)
            }
        }
    }
    
    /// Save the preferences after a delay
    ///
    /// Allows many rapid changes to be batched into a single HTTP request
    private func setNeedsPreferencesSave(){
        os_log(.error, log: logger, "Queueing preferences save")
        preferencesSaveTimer?.invalidate()
        preferencesSaveTimer = .scheduledTimer(withTimeInterval: 5, repeats: false){
            timer in
            if let preferences = self.preferences{
                // TODO: save to storage
                os_log(.error, log: logger, "Saving prefefences to server")
                _ = self.service.save(preferences){
                    success in
                    if !success{
                        os_log(.error, log: logger, "Failed to save preference to server")
                    }
                    self.preferencesSaveTimer = nil
                }
            }else{
                os_log(.error, log: logger, "Save preferences timer fired with nil preferences")
            }
        }
    }
    
    /// Timer for delayed preference saving
    private var preferencesSaveTimer: Timer?
}

// MARK: - URL Request/Response Extensions

extension URLRequest{
    
    /// Create a new request for the given morphic session
    ///
    /// Adds the morphic auth header if a saved token exists
    ///
    /// - parameters:
    ///   - session: The morphic session
    ///   - path: The relative path of the request, which will be added to the session's endpoint
    ///   - method: The request method
    init(session: Session, path: String, method: Method){
        let url = URL(string: path, relativeTo: session.service.endpoint)!
        self.init(url: url)
        httpMethod = method.rawValue
        if let token = session.authToken{
            self.addValue(token, forHTTPHeaderField: "X-Morphic-Auth-Token")
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
    init?<Body>(session: Session, path: String, method: Method, body: Body) where Body: Encodable{
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
    enum Method: String{
        
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

extension URLResponse{
    
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
    func morphicObject<T>(from data: Data?) -> T? where T : Decodable{
        guard let response = self as? HTTPURLResponse else{
            return nil
        }
        guard response.statusCode == 200 else{
            return nil
        }
        guard let contentType = response.value(forHTTPHeaderField: "Content-Type")?.lowercased() else{
            return nil
        }
        guard contentType == "application/json; charset=utf-8" else{
            return nil
        }
        guard let data = data else{
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
    var morphicSuccess: Bool{
        guard let response = self as? HTTPURLResponse else{
            return false
        }
        return response.statusCode / 100 == 2
    }
    
    /// Check if the Morphic HTTP request failed because of authentication required
    ///
    /// In order to be considered an auth failure:
    /// * The response object must be an `HTTPURLResponse`
    /// * The HTTP `statusCode` must be `401`
    var requiresMorphicAuthentication: Bool{
        guard let response = self as? HTTPURLResponse else{
            return false
        }
        return response.statusCode == 401
    }
    
}
