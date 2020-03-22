//
//  Keychain.swift
//  MorphicCore
//
//  Created by Owen Shaw on 3/19/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import Security
import OSLog

private let logger = OSLog(subsystem: "MorphicCore", category: "Keychain")

/// Simpler interface to SECKeychain functionality for secure password/secret storage
public class Keychain{
    
    /// Create a keychain with the default identifier
    public init(){
    }
    
    /// Create a keychain with the given identifier
    public init(identifier: String){
        self.identifier = identifier
    }
    
    public private(set) static var shared = Keychain(identifier: "org.raisingthefloor.Morphic")
    
    /// This keychain's identifier
    public private(set) var identifier: String?
    
    // MARK: Getting Items
    
    /// Get a website login item
    public func login(for url: URL) -> Login?{
        guard let result = query(kSecClassInternetPassword, attributes: url.keychainAttributes) else{
            return nil
        }
        guard let url = URL.from(keychainAttributes: result) else{
            return nil
        }
        guard let username = result.string(for: kSecAttrAccount) else{
            return nil
        }
        guard let password = result.string(for: kSecValueData, encoding: .utf8) else{
            return nil
        }
        return Login(url: url, username: username, password: password)
    }
    
    public func secret(for url: URL, identifier: String) -> Secret?{
        return secret(for: "\(identifier);\(url.absoluteString)")
    }
    
    /// Get a secret
    public func secret(for identifier: String) -> Secret?{
        guard let result = query(kSecClassGenericPassword, attributes: [kSecAttrGeneric: identifier.data(using: .utf8)! as CFData]) else{
            return nil
        }
        guard let value = result.string(for: kSecValueData, encoding: .utf8) else{
            return nil
        }
        return Secret(identifier: identifier, value: value)
    }
    
    private func queryAttributes(for itemClass: CFString, merging: [CFString: CFTypeRef]?) -> [CFString: CFTypeRef]{
        var attributes: [CFString: CFTypeRef] = [
            kSecClass: itemClass,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: kCFBooleanTrue,
            kSecReturnAttributes: kCFBooleanTrue
        ]
        if let identifier = identifier{
            attributes[kSecAttrAccessGroup] = identifier as CFString
        }
        if let merging = merging{
            attributes.merge(merging)
        }
        return attributes
    }
    
    private func query(_ itemClass: CFString, attributes: [CFString: CFTypeRef]) -> [CFString: CFTypeRef]?{
        let attributes = queryAttributes(for: itemClass, merging: attributes)
        let result = UnsafeMutablePointer<CFTypeRef?>.allocate(capacity: 1)
        let status = SecItemCopyMatching(attributes as CFDictionary, result)
        guard status == errSecSuccess else{
            if status != errSecItemNotFound{
                os_log("Failed to query item in keychain: %d", log: logger, type: .error, status)
            }
            result.deallocate()
            return nil
        }
        guard let pointee = result.pointee else{
            result.deallocate()
            return nil
        }
        guard let resultAttributes = pointee as! CFDictionary as? [CFString: CFTypeRef] else{
            result.deallocate()
            return nil
        }
        result.deallocate()
        return resultAttributes
    }
    
    // MARK: - Saving Items
    
    private func attributes(for itemClass: CFString, merging: [CFString: CFTypeRef]?, data: Data) -> [CFString: CFTypeRef]{
        var attributes: [CFString: CFTypeRef] = [
            kSecClass: itemClass,
            kSecAttrSynchronizable: kCFBooleanFalse
        ]
        if let identifier = identifier{
            attributes[kSecAttrAccessGroup] = identifier as CFString
        }
        attributes[kSecValueData] = data as CFData
        if let merging = merging{
            attributes.merge(merging)
        }
        return attributes
    }
    
    public func save(login: Login) -> Bool{
        let query = queryAttributes(for: kSecClassInternetPassword, merging: login.url.keychainAttributes)
        var attributes = self.attributes(for: kSecClassInternetPassword, merging: login.url.keychainAttributes, data: login.password.data(using: .utf8)!)
        attributes[kSecAttrAccount] = login.username as CFString
        return save(query: query, attributes: attributes)
    }
    
    public func save(secret: Secret) -> Bool{
        let query = queryAttributes(for: kSecClassGenericPassword, merging: [kSecAttrGeneric: secret.identifier.data(using: .utf8)! as CFData])
        let attributes = self.attributes(for: kSecClassGenericPassword, merging: [kSecAttrGeneric: secret.identifier.data(using: .utf8)! as CFData], data: secret.value.data(using: .utf8)!)
        return save(query: query, attributes: attributes)
    }
    
    private func save(query: [CFString: CFTypeRef], attributes: [CFString: CFTypeRef]) -> Bool{
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound{
            status = SecItemAdd(attributes as CFDictionary, nil)
            if status != errSecSuccess{
                os_log("Failed to add item to keychain: %d", log: logger, type: .error, status)
                return false
            }
            return true
        }
        if status != errSecSuccess{
            os_log("Failed to update item in keychain: %d", log: logger, type: .error, status)
            return false
        }
        return true
    }
    
    // MARK: - Removing Items
    
    public func remove(login: Login) -> Bool{
        let query = queryAttributes(for: kSecClassInternetPassword, merging: login.url.keychainAttributes)
        return remove(query: query)
    }
    
    public func remove(secret: Secret) -> Bool{
        let query = queryAttributes(for: kSecClassGenericPassword, merging: [kSecAttrGeneric: secret.identifier.data(using: .utf8)! as CFData])
        return remove(query: query)
    }
    
    private func remove(query: [CFString: CFTypeRef]) -> Bool{
        var query = query
        query.removeValue(forKey: kSecMatchLimit)
        query.removeValue(forKey: kSecReturnData)
        query.removeValue(forKey: kSecReturnAttributes)
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess{
            os_log("Failed to remove item from keychain: %d", log: logger, type: .error, status)
            return false
        }
        return true
    }
    
    public struct Login{
        public var url: URL
        public var username: String
        public var password: String
        
        public init(url: URL, username: String, password: String){
            self.url = url
            self.username = username
            self.password = password
        }
    }
    
    public struct Secret{
        public var identifier: String
        public var value: String
        
        public init(url: URL, identifier: String, value: String){
            self.init(identifier: "\(identifier);\(url.absoluteString)", value: value)
        }
        
        public init(identifier: String, value: String){
            self.identifier = identifier
            self.value = value
        }
    }
    
}

fileprivate extension Dictionary where Key: CFString, Value: CFTypeRef{
    
    func string(for key: Key) -> String?{
        guard let value = self[key] else{
            return nil
        }
        return value as! CFString as String
    }
    
    func string(for key: Key, encoding: String.Encoding) -> String?{
        guard let data = data(for: key) else{
            return nil
        }
        return String(data: data, encoding: encoding)
    }
    
    func data(for key: Key) -> Data?{
        guard let value = self[key] else{
            return nil
        }
        return value as! CFData as Data
    }
    
    func number(for key: Key) -> NSNumber?{
        guard let value = self[key] else{
            return nil
        }
        return value as! CFNumber as NSNumber
    }
    
    func int(for key: Key) -> Int?{
        return number(for: key)?.intValue
    }
    
    mutating func merge(_ other: [Key: Value]){
        for (k,v) in other{
            self[k] = v
        }
    }
    
}

fileprivate extension URL{
    
    static func from(keychainAttributes: [CFString : CFTypeRef]) -> URL?{
        var components = URLComponents()
        if let proto = keychainAttributes.string(for: kSecAttrProtocol){
            if proto == kSecAttrProtocolHTTP as String{
                components.scheme = "http"
            }else if proto == kSecAttrProtocolHTTPS as String{
                components.scheme = "https"
            }
        }
        if let host = keychainAttributes.string(for: kSecAttrServer){
            components.host = host
        }
        if let port = keychainAttributes.int(for: kSecAttrPort){
            components.port = port
        }
        if let path = keychainAttributes.string(for: kSecAttrPath){
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
