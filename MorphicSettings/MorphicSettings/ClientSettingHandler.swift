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
