//
//  AccessibilityUIAutomation.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/27/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "AccessibilityUIAutomation")


public class AccessibilityUIAutomation: UIAutomation{
    
    public required init() {
    }
    
    public func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        fatalError("Not implemented")
    }
        
    public func showAccessibilityPreferences(completion: @escaping (_ accessibility: AccessibilityPreferencesElement?) -> Void){
        let app = SystemPreferencesElement()
        app.open{
            success in
            guard success else {
                os_log(.error, log: logger, "Failed to open system preferences")
                completion(nil)
                return
            }
            app.showAccessibility{
                success, accessibility in
                guard success else {
                    os_log(.error, log: logger, "Failed to show Accessibility pane")
                    completion(nil)
                    return
                }
                completion(accessibility)
            }
        }
    }
    
    public func showAccessibilityDisplayPreferences(tab: String, completion: @escaping (_ accessibility: AccessibilityPreferencesElement?) -> Void){
        showAccessibilityPreferences{
            accessibility in
            guard let accessibility = accessibility else{
                completion(nil)
                return
            }
            accessibility.selectDisplay{
                success in
                guard success else{
                    os_log(.error, log: logger, "Failed to select Display category")
                    completion(nil)
                    return
                }
                guard accessibility.select(tabTitled: "Display") else{
                    os_log(.error, log: logger, "Failed to select Display tab")
                    completion(nil)
                    return
                }
                completion(accessibility)
            }
        }
    }
    
    public func showAccessibilityVoiceOverPreferences(completion: @escaping (_ accessibility: AccessibilityPreferencesElement?) -> Void){
        showAccessibilityPreferences{
            accessibility in
            guard let accessibility = accessibility else{
                completion(nil)
                return
            }
            accessibility.selectVoiceOver{
                success in
                guard success else{
                    os_log(.error, log: logger, "Failed to select VoiceOver category")
                    completion(nil)
                    return
                }
                completion(accessibility)
            }
        }
    }
    
}
