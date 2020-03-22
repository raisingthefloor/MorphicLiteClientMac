//
//  Session.swift
//  MorphicService
//
//  Created by Owen Shaw on 3/22/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore
import MorphicSettings
import OSLog

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
            // If the user wasn't logged out, get the locally cached preferences
            storage.load(identifier: userId){
                (user: User?) in
                self.user = user
                if let preferencesId = user?.preferencesId{
                    self.storage.load(identifier: preferencesId){
                        (preferences: Preferences?) in
                        self.preferences = preferences
                        completion()
                    }
                }else{
                    // We don't have the user information stored locally
                    // TODO: try the server?
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
        if let request = request{
            let task = Task()
            task.urlTask = urlSession.dataTask(with: request){
                data, response, error in
                if response?.requiresMorphicAuthentication ?? false{
                    // If our token expired, try to reauthenticate with saved credentials
                    task.urlTask = self.authenticate{
                        success in
                        if success{
                            // If we got a new token, try the request again
                            task.urlTask = self.urlSession.dataTask(with: request){
                                data, response, error in
                                let body: ResponseBody? = response?.morphicObject(from: data)
                                DispatchQueue.main.async {
                                    completion(body)
                                }
                            }
                            task.urlTask?.resume()
                        }else{
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
        if let request = request{
            let task = Task()
            task.urlTask = urlSession.dataTask(with: request){
                data, response, error in
                if response?.requiresMorphicAuthentication ?? false{
                    // If our token expired, try to reauthenticate with saved credentials
                    task.urlTask = self.authenticate{
                        success in
                        if success{
                            // If we got a new token, try the request again
                            task.urlTask = self.urlSession.dataTask(with: request){
                                data, response, error in
                                DispatchQueue.main.async {
                                    completion(response?.morphicSuccess ?? false)
                                }
                            }
                            task.urlTask?.resume()
                        }else{
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
    
    /// Get the saved username login from the keychain
    public var savedUsernameCredentials: UsernameCredentials?{
        get{
            if let login = keychain.login(for: service.endpoint){
                return UsernameCredentials(username: login.username, password: login.password)
            }
            return nil
        }
        set{
            if let credentials = newValue{
                let login = Keychain.Login(url: service.endpoint, username: credentials.username, password: credentials.password)
                if !keychain.save(login: login){
                    os_log(.fault, log: logger, "Failed to save login to keychain")
                }
            }else{
                if let login = keychain.login(for: service.endpoint){
                    if !keychain.remove(login: login){
                        os_log(.fault, log: logger, "Failed to remove login to keychain")
                    }
                }
            }
        }
    }
    
    /// Get the saved secret key login from the keychain
    public var savedKeyCredentials: KeyCredentials?{
        get{
            if let key = keychain.secret(for: service.endpoint, identifier: "key")?.value{
                return KeyCredentials(key: key)
            }
            return nil
        }
        set{
            if let key = newValue?.key{
                let secret = Keychain.Secret(url: service.endpoint, identifier: "key", value: key)
                if !keychain.save(secret: secret){
                    os_log(.fault, log: logger, "Failed to save secret to keychain")
                }
            }else{
                if let secret = keychain.secret(for: service.endpoint, identifier: "key"){
                    if !keychain.remove(secret: secret){
                        os_log(.fault, log: logger, "Failed to remove secret to keychain")
                    }
                }
            }
        }
    }
    
    /// Get the saved secret key login from the keychain
    public var authToken: String?{
        get{
            return keychain.secret(for: service.endpoint, identifier: "token")?.value
        }
        set{
            if let token = newValue{
                let secret = Keychain.Secret(url: service.endpoint, identifier: "token", value: token)
                if !keychain.save(secret: secret){
                    os_log(.fault, log: logger, "Failed to save token to keychain")
                }
            }else{
                if let secret = keychain.secret(for: service.endpoint, identifier: "token"){
                    if !keychain.remove(secret: secret){
                        os_log(.fault, log: logger, "Failed to remove secret to keychain")
                    }
                }
            }
        }
    }
    
    /// Authenticate the user using whatever saved secret we have
    private func authenticate(completion: @escaping (_ success: Bool) -> Void) -> URLSessionTask?{
        if let creds: Credentials = savedKeyCredentials ?? savedUsernameCredentials{
            let task = service.authenticate(credentials: creds){
                auth in
                completion(auth != nil)
            }
            return task.urlTask
        }
        DispatchQueue.main.async {
            completion(false)
        }
        return nil
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
    public var user: User?
    
    /// The current user's preferences
    public var preferences: Preferences?
    
    /// Save a preference change
    ///
    /// * Updates the local preferences
    /// * Applys the change to the system
    /// * Requests a cloud save
    public func save(_ value: Interoperable?, for preference: String, in solution: String){
        preferences?.set(value, for: preference, in: solution)
        _ = settings.apply(value, for: preference, in: solution)
        setNeedsPreferencesSave()
    }
    
    /// Save the preferences after a delay
    ///
    /// Allows many rapid changes to be batched into a single HTTP request
    private func setNeedsPreferencesSave(){
        preferencesSaveTimer?.invalidate()
        preferencesSaveTimer = .scheduledTimer(withTimeInterval: 10, repeats: false){
            timer in
            if let preferences = self.preferences{
                // TODO: save to storage
                _ = self.service.save(preferences){
                    success in
                    if !success{
                        os_log("Failed to save preference to server", log: logger, type: .error)
                    }
                    self.preferencesSaveTimer = nil
                }
            }else{
                os_log("Save preferences timer fired with nil preferences", log: logger, type: .error)
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
