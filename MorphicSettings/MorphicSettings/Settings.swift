//
//  Settings.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 3/22/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "Settings")

/// Manages system settings based on morphic preferences
public class Settings{
    
    /// The singleton object representing this system's settings
    public static var shared: Settings = Settings()
    
    private init(){
    }
    
    /// Apply a value for Morphic preference in the given solution
    public func apply(_ value: Interoperable?, for preference: String, in solution: String) -> Bool{
        // FIXME: Exmple only.  Real implementation should be able to apply settings by looking up solutions in
        // a solution registry and dynamically apply them based on the solution description
        if solution == "com.apple.macos.display"{
            if preference == "zoom"{
                guard let levelName = value as? String else{
                    os_log("Value provided for com.apple.macos.display.zoom is not a string", log: logger, type: .error)
                    return false
                }
                guard let level = Display.ZoomLevel(rawValue: levelName) else{
                    os_log("Value provided for com.apple.macos.display.zoom is not valid", log: logger, type: .error)
                    return false
                }
                if !(mainDisplay?.zoom(level: level) ?? false){
                    os_log("Failed to set com.apple.macos.display.zoom", log: logger, type: .error)
                    return false
                }
                return true
            }
            return false
        }
        return false
    }
    
    // MARK: - Display
    
    /// The main display on this system
    private var mainDisplay = Display.main
    
}
