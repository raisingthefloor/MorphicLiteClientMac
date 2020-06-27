//
//  ContrastUIAutomation.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/26/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "VoiceOverUIAutomation")


public class VoiceOverUIAutomation: AccessibilityUIAutomation{
    
    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        guard let checked = value as? Bool else{
            os_log(.error, log: logger, "Passed non-boolean value")
            completion(false)
            return
        }
        showAccessibilityVoiceOverPreferences{
            accessibility in
            guard let accessibility = accessibility else{
                completion(false)
                return
            }
            guard let checkbox = accessibility.checkbox(titled: "Enable VoiceOver") else{
                os_log(.error, log: logger, "Failed to find VoiceOver checkbox")
                completion(false)
                return
            }
            guard checkbox.setChecked(checked) else{
                os_log(.error, log: logger, "Failed to press VoiceOver checkbox")
                completion(false)
                return
            }
            accessibility.wait(atMost: 5.0, for: {
                let running = NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == "com.apple.VoiceOver" })
                return running == checked
            }){
                success in
                completion(success)
            }
        }
    }
    
}
