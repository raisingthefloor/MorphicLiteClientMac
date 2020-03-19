//
//  URLSession+Morphic.swift
//  MorphicService
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import OSLog

private var logger = OSLog(subsystem: "morphic-service", category: "urlsession")

extension URLSession{
    
    /// Create a data task that decodes a JSON object from the response
    ///
    /// Makes a `GET` request to the given URL
    ///
    /// Expects the `Content-Type` response header to be `application/json; charset=utf-8`
    ///
    /// - parameters:
    ///   - request: The URL request
    ///   - completion: The block to call when the request completes
    ///   - response: The `Decodable` object that was sent as a response
    ///
    /// - returns: The created task
    func runningDataTask<ResponseBody>(with request: URLRequest, completion: @escaping (_ response: ResponseBody?) -> Void) -> URLSessionDataTask where ResponseBody: Decodable{
        let task = dataTask(with: request){
            data, response, error in
            let body: ResponseBody? = response?.morphicObject(from: data)
            DispatchQueue.main.async {
                completion(body)
            }
        }
        task.resume()
        return task
    }
    
    /// Create a data task by encoding a JSON object as the request body
    ///
    /// Prepares a `URLRequest` and calls `dataTask(with:completionHandler:)` using that
    /// request, calling the `completion` handler on the main thread.
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
    /// - returns: The created task, or `nil` if the object encoding failed
    func runningDataTask(with request: URLRequest, completion: @escaping (_ success: Bool) -> Void) -> URLSessionDataTask{
        let task = dataTask(with: request){
            data, response, error in
            DispatchQueue.main.async {
                completion(response?.morphicSuccess ?? false)
            }
        }
        task.resume()
        return task
    }
}


extension URLRequest{
    
    /// Create a new request for the given morphic service config
    init(url: URL, method: Method, morphicConfiguration: Service.Configuration){
        self.init(url: url)
        httpMethod = method.rawValue
        if let token = morphicConfiguration.authToken(for: url){
            self.addValue(token, forHTTPHeaderField: "X-Morphic-Auth-Token")
        }
    }
    
    init?<Body>(url: URL, method: Method, body: Body, morphicConfiguration: Service.Configuration) where Body: Encodable{
        self.init(url: url, method: method, morphicConfiguration: morphicConfiguration)
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
    
}
