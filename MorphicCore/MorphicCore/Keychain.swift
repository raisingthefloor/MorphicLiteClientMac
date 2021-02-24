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
import Security
import OSLog

private let logger = OSLog(subsystem: "MorphicCore", category: "Keychain")

/// Simpler interface to SECKeychain functionality for secure password/secret storage
public class Keychain {
    
    /// Create a keychain with the given identifier
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    public private(set) static var shared: Keychain = {
        let prefix = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String ?? ""
        return Keychain(identifier: "\(prefix)org.raisingthefloor.Morphic")
    }()
    
    /// This keychain's identifier
    public private(set) var identifier: String
    
    // MARK: - Username/Password Logins
    
    /// Get a website login item
    public func usernameCredentials(for url: URL, username: String) -> UsernameCredentials? {
        let query = identifyingAttributes(for: url, username: username)
        guard let result = first(matching: query) else {
            return nil
        }
        guard let username = result.string(for: kSecAttrAccount) else {
            return nil
        }
        guard let password = result.string(for: kSecValueData, encoding: .utf8) else {
            return nil
        }
        return UsernameCredentials(username: username, password: password)
    }
    
    public func save(usernameCredentials: UsernameCredentials, for url: URL) throws {
        let query = identifyingAttributes(for: url, username: usernameCredentials.username)
        var attributes = query
        attributes[kSecValueData] = usernameCredentials.password.data(using: .utf8)! as CFData
        try save(attributes: attributes, matching: query)
    }
    
    public func removeUsernameCredentials(for url: URL, username: String) throws {
        let query = identifyingAttributes(for: url, username: username)
        try remove(matching: query)
    }
    
    private func identifyingAttributes(for url: URL, username: String) -> [CFString: CFTypeRef] {
        var attributes: [CFString: CFTypeRef] = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrAccessGroup: identifier as CFString,
            kSecAttrAccount: username as CFString
        ]
        attributes.merge(url.keychainAttributes)
        return attributes
    }
    
    // MARK: - Secret Key Logins
    
    public func keyCredentials(for url: URL, userIdentifier: String) -> KeyCredentials? {
        let query = identifyingAttributes(for: url, service: secretKeyService, userIdentifier: userIdentifier)
        guard let result = first(matching: query) else {
            return nil
        }
        guard let key = result.string(for: kSecValueData, encoding: .utf8) else {
            return nil
        }
        return KeyCredentials(key: key)
    }
    
    public func save(keyCredentials: KeyCredentials, for url: URL, userIdentifier: String) throws {
        let query = identifyingAttributes(for: url, service: secretKeyService, userIdentifier: userIdentifier)
        var attributes = query
        attributes[kSecValueData] = keyCredentials.key.data(using: .utf8)! as CFData
        try save(attributes: attributes, matching: query)
    }
    
    public func removeKeyCredentials(for url: URL, userIdentifier: String) throws {
        let query = identifyingAttributes(for: url, service: secretKeyService, userIdentifier: userIdentifier)
        try remove(matching: query)
    }
    
    private var secretKeyService = "org.raisingthefloor.morphic.secret-key"
    
    private func identifyingAttributes(for url: URL, service: String, userIdentifier: String) -> [CFString: CFTypeRef] {
        return [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessGroup: identifier as CFString,
            kSecAttrService: service as CFString,
            kSecAttrAccount: userIdentifier as CFString,
            kSecAttrGeneric: url.absoluteString.data(using: .utf8)! as CFData
        ]
    }
    
    // MARK: - Auth Tokens
    
    public func authToken(for url: URL, userIdentifier: String) -> String? {
        let query = identifyingAttributes(for: url, service: authTokenService, userIdentifier: userIdentifier)
        guard let result = first(matching: query) else {
            return nil
        }
        guard let token = result.string(for: kSecValueData, encoding: .utf8) else {
            return nil
        }
        return token
    }
    
    public func save(authToken: String, for url: URL, userIdentifier: String) throws {
        // NOTE: sometimes overwriting a token returns success but does not overwrite it; therefore we erase any existing token beforehand
        // NOTE: if we store additional data in the keychain in the future, consider moving this "remove" code to the "save(attributes:matching:) function (and also possibly checking if it exists before removing it, to surpress intentional failures in macOS Console's logs).
        _ = try? removeAuthToken(for: url, userIdentifier: userIdentifier)
        
        let query = identifyingAttributes(for: url, service: authTokenService, userIdentifier: userIdentifier)
        var attributes = query
        attributes[kSecValueData] = authToken.data(using: .utf8)! as CFData
        try save(attributes: attributes, matching: query)
    }
    
    public func removeAuthToken(for url: URL, userIdentifier: String) throws {
        let query = identifyingAttributes(for: url, service: authTokenService, userIdentifier: userIdentifier)
        try remove(matching: query)
    }
    
    private var authTokenService = "org.raisingthefloor.morphic.auth-token"
    
    // MARK: - Querying
    
    private func first(matching query: [CFString: CFTypeRef]) -> [CFString: CFTypeRef]? {
        var query = query
        if #available(macOS 10.15, *) {
            query[kSecUseDataProtectionKeychain] = kCFBooleanTrue
        }
        query[kSecReturnData] = kCFBooleanTrue
        query[kSecReturnAttributes] = kCFBooleanTrue
        query[kSecMatchLimit] = kSecMatchLimitOne
        let result = UnsafeMutablePointer<CFTypeRef?>.allocate(capacity: 1)
        let status = SecItemCopyMatching(query as CFDictionary, result)
        guard status == errSecSuccess else {
            if status != errSecItemNotFound{
                os_log(.error, log: logger, "Failed to query item in keychain: %d", status)
            }
            result.deallocate()
            return nil
        }
        guard let pointee = result.pointee else {
            result.deallocate()
            return nil
        }
        guard let resultAttributes = pointee as! CFDictionary as? [CFString: CFTypeRef] else {
            result.deallocate()
            return nil
        }
        result.deallocate()
        return resultAttributes
    }
    
    private func save(attributes: [CFString: CFTypeRef], matching query: [CFString: CFTypeRef]) throws {
        var attributes = attributes
        if #available(macOS 10.15, *) {
            attributes[kSecUseDataProtectionKeychain] = kCFBooleanTrue
        }
        attributes[kSecAttrSynchronizable] = kCFBooleanFalse
        attributes[kSecAttrIsInvisible] = kCFBooleanFalse
        attributes[kSecAttrModificationDate] = Date() as CFDate
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            attributes[kSecAttrCreationDate] = attributes[kSecAttrModificationDate]
            status = SecItemAdd(attributes as CFDictionary, nil)
            if status != errSecSuccess {
                os_log(.error, log: logger, "Failed to add item to keychain: %d", status)
                throw MorphicError()
            }
            return
        }
        if status != errSecSuccess {
            os_log(.error, log: logger, "Failed to update item in keychain: %d", status)
            throw MorphicError()
        }
    }
    
    private func remove(matching query: [CFString: CFTypeRef]) throws {
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            os_log(.error, log: logger, "Failed to remove item from keychain: %d", status)
            throw MorphicError()
        }
    }
    
}

fileprivate extension Dictionary where Key: CFString, Value: CFTypeRef {
    
    func string(for key: Key) -> String? {
        guard let value = self[key] else {
            return nil
        }
        return value as! CFString as String
    }
    
    func string(for key: Key, encoding: String.Encoding) -> String? {
        guard let data = data(for: key) else {
            return nil
        }
        return String(data: data, encoding: encoding)
    }
    
    func data(for key: Key) -> Data? {
        guard let value = self[key] else {
            return nil
        }
        return value as! CFData as Data
    }
    
    func number(for key: Key) -> NSNumber? {
        guard let value = self[key] else {
            return nil
        }
        return value as! CFNumber as NSNumber
    }
    
    func int(for key: Key) -> Int? {
        return number(for: key)?.intValue
    }
    
    mutating func merge(_ other: [Key: Value]) {
        for (k,v) in other{
            self[k] = v
        }
    }
    
}

fileprivate extension URL{
    
    static func from(keychainAttributes: [CFString : CFTypeRef]) -> URL? {
        var components = URLComponents()
        if let proto = keychainAttributes.string(for: kSecAttrProtocol) {
            if proto == kSecAttrProtocolHTTP as String {
                components.scheme = "http"
            }else if proto == kSecAttrProtocolHTTPS as String {
                components.scheme = "https"
            }
        }
        if let host = keychainAttributes.string(for: kSecAttrServer) {
            components.host = host
        }
        if let port = keychainAttributes.int(for: kSecAttrPort) {
            components.port = port
        }
        if let path = keychainAttributes.string(for: kSecAttrPath) {
            components.path = path
        }
        return components.url
    }
    
    var keychainAttributes: [CFString : CFTypeRef] {
        var attributes: [CFString : CFTypeRef] = [
            kSecAttrPath: path as CFString
        ]
        if let host = host{
            attributes[kSecAttrServer] = host as CFString
        }
        if let port = port{
            attributes[kSecAttrPort] = port as CFNumber
        }
        if let scheme = scheme{
            if scheme == "http"{
                attributes[kSecAttrProtocol] = kSecAttrProtocolHTTP
            }else if scheme == "https"{
                attributes[kSecAttrProtocol] = kSecAttrProtocolHTTPS
            }
            
        }
        return attributes
    }
    
}
