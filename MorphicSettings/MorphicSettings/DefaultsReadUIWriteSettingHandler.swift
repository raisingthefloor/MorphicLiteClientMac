//
//  MacSettingHandler.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/23/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore

/// A setting handler that reads values from user defaults, but writes values using the system preferences UI
///
/// The asymmetry between read and write is because macOS won't let us write the user defaults directly.
/// Additionally, several system settings checkboxes actually change more than one default and call private
/// functions that we don't have access to, so using the UI is the best option.
public class DefaultsReadUIWriteSettingHandler: SettingHandler{
    
    public required init(setting: Setting) {
        super.init(setting: setting)
        defaults = UserDefaults(suiteName: description.defaultsDomain)
    }
    
    /// The user defaults object to use, based on the `defaultsDomain` from the setting's `handlerDescription`
    private var defaults: UserDefaults?
    
    /// The data model describing the properties for this kind of setting handler
    public struct Description: SettingHandlerDescription{
        
        public var type: Setting.HandlerType{
            return .defaultsReadUIWrite
        }
        
        /// The user defaults domain to read from
        public let defaultsDomain: String
        
        /// The user defaults key within the domain that stores the actual value
        public let defaultsKey: String
        
        public enum CodingKeys: String, CodingKey{
            case defaultsDomain = "defaults_domain"
            case defaultsKey = "defaults_key"
        }
        
        public init(from decoder: Decoder) throws{
            let container = try decoder.container(keyedBy: CodingKeys.self)
            defaultsDomain = try container.decode(String.self, forKey: .defaultsDomain)
            defaultsKey = try container.decode(String.self, forKey: .defaultsKey)
        }
    }
    
    /// The properly typed description for this handler
    private var description: Description{
        return setting.handlerDescription as! Description
    }
    
    public override func apply(_ value: Interoperable?, completion: @escaping (_ success: Bool) -> Void) {
        completion(false)
    }
    
    public override func read(completion: @escaping (_ result: SettingHandler.Result) -> Void) {
        switch setting.type{
        case .boolean:
            guard let boolValue = defaults?.bool(forKey: description.defaultsKey) else{
                completion(.failed)
                return
            }
            completion(.succeeded(value: boolValue))
        case .double:
            guard let doubleValue = defaults?.double(forKey: description.defaultsKey) else{
                completion(.failed)
                return
            }
            completion(.succeeded(value: doubleValue))
        case .integer:
            guard let intValue = defaults?.integer(forKey: description.defaultsKey) else {
                completion(.failed)
                return
            }
            completion(.succeeded(value: intValue))
        case .string:
            guard let stringValue = defaults?.string(forKey: description.defaultsKey) else{
                completion(.failed)
                return
            }
            completion(.succeeded(value: stringValue))
        }
    }
    
}
