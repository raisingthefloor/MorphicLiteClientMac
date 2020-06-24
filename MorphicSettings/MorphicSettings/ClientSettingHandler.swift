//
//  ClientSettingHandler.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/23/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore

/// Base class for client handlers that run custom code specific to the setting
public class ClientSettingHandler: SettingHandler{
    
    /// Factory method for creating a client setting handler
    ///
    /// Types are registered via `register(type:for:)`
    ///
    /// - parameter setting: The setting for which a handler should be created
    public static func create(for setting: Setting) -> ClientSettingHandler?{
        guard let description = setting.handlerDescription as? Description else{
            return nil
        }
        let key = Preferences.Key(solution: description.solution, preference: description.preference)
        guard let type = handlerTypesByKey[key] else{
            return nil
        }
        return type.init(setting: setting)
    }
    
    /// Register a client handler of the given type for the given key
    ///
    /// Registered types are avaiable to `create(for:)`
    ///
    /// - parameters:
    ///   - type: The `ClientSettingHandler` subclass to use for the given key
    ///   - key: The key that identifies when to use the given type
    public static func register(type: ClientSettingHandler.Type, for key: Preferences.Key){
        handlerTypesByKey[key] = type
    }
    
    /// The map of keys to types
    private static var handlerTypesByKey = [Preferences.Key: ClientSettingHandler.Type]()
    
    /// The properly typed description for this handler
    private var description: Description{
        return setting.handlerDescription as! Description
    }
    
    /// Data model describing the properites for a client setting handler
    public struct Description: SettingHandlerDescription{
        
        public var type: Setting.HandlerType{
            return .client
        }

        /// The solution identifier
        public let solution: String
        
        /// The setting name
        public let preference: String
        
        /// A preference key created by combining `solution` and `preference`
        public var key: Preferences.Key {
            return Preferences.Key(solution: solution, preference: preference)
        }
        
    }
}
