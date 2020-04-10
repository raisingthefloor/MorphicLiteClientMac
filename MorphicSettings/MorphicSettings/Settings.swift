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
                    os_log(.error, log: logger, "Value provided for com.apple.macos.display.zoom is not a string")
                    return false
                }
                guard let level = Display.ZoomLevel(rawValue: levelName) else{
                    os_log(.error, log: logger, "Value provided for com.apple.macos.display.zoom is not valid")
                    return false
                }
                if !(mainDisplay?.zoom(level: level) ?? false){
                    os_log(.error, log: logger, "Failed to set com.apple.macos.display.zoom")
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
