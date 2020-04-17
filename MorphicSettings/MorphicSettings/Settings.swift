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
        Handler.register(type: DisplayZoomHandler.self, for: .macosDisplayZoom)
        Handler.register(type: AudioVolumeHandler.self, for: .macosAudioVolume)
        Handler.register(type: AudioMuteHandler.self, for: .macosAudioMuted)
    }
    
    /// Apply a value for Morphic preference in the given solution
    public func apply(_ value: Interoperable?, for key: Preferences.Key) -> Bool{
        guard let handler = Handler.matching(key: key) else{
            os_log(.error, log: logger, "No handler found for preference")
            return false
        }
        do{
            try handler.apply(value)
            return true
        }catch Handler.ApplyError.notImplemented{
            os_log(.error, log: logger, "Apply function not implemented for %{public}s.%{public}s", key.solution, key.preference)
        }catch Handler.ApplyError.incorrectValueType{
            os_log(.error, log: logger, "Value provided is not the correct type for %{public}s.%{public}s", key.solution, key.preference)
        }catch Handler.ApplyError.invalidValue{
            os_log(.error, log: logger, "Value provided is not valid for %{public}s.%{public}s", key.solution, key.preference)
        }catch Handler.ApplyError.failed{
            os_log(.error, log: logger, "Failed to set %{public}s.%{public}s", key.solution, key.preference)
        }catch{
            os_log(.error, log: logger, "Uncaught error setting %{public}s.%{public}s", key.solution, key.preference)
        }
        return false
    }
    
}

public extension Preferences.Key{
    static var macosDisplayZoom = Preferences.Key(solution: "com.apple.macos.display", preference: "zoom")
    static var macosAudioVolume = Preferences.Key(solution: "com.apple.macos.audio", preference: "volume")
    static var macosAudioMuted = Preferences.Key(solution: "com.apple.macos.audio", preference: "muted")
}
