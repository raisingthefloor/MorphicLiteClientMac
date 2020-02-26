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
    ///   - url: The URL of the request
    ///   - method: The request method to use
    ///   - completion: The block to call when the request completes
    ///   - success: Whether the request succeeded
    ///
    /// - returns: The created task, or `nil` if the object encoding failed
    func runningDataTask<T>(with url: URL, completion: @escaping (_ jsonDecodable: T?) -> Void) -> URLSessionDataTask where T: Decodable{
        let task = dataTask(with: url){
            data, response, error in
            DispatchQueue.main.async {
                completion(response?.morphicObject(from: data))
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
    /// Because the completion handler only reports a `Bool` success/fail, this method is appropritate
    /// for operations like save calls where the server doesn't return data or the returned data is
    /// identical to what was submitted
    ///
    /// Sets the `Content-Type` header to `application/json; charset=utf-8`
    ///
    /// - parameters:
    ///   - url: The URL of the request
    ///   - morphicObject: The `Encodable` object to send as JSON in the request body
    ///   - method: The request method to use
    ///   - completion: The block to call when the request completes
    ///   - success: Whether the request succeeded
    ///
    /// - returns: The created task, or `nil` if the object encoding failed
    func runningDataTask<T>(with url: URL, jsonEncodable: T, method: URLRequest.Method, completion: @escaping (_ success: Bool) -> Void) -> URLSessionDataTask? where T: Encodable{
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(jsonEncodable)
        } catch {
            os_log(.error, log: logger, "Error encoding data for %{public}s: %{public}s", String(describing: T.self), error.localizedDescription)
            DispatchQueue.main.async {
                completion(false)
            }
            return nil
        }
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
