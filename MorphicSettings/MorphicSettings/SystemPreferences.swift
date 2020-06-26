//
//  SystemPreferences.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class SystemPreferences{
    
    private init(){
    }
    
    public static let shared = SystemPreferences()
    
    public let accessibility = AccessibilitySystemPreferencesPane()
    
    public enum PaneIdentifier: String, Codable{
        case accessibility
    }
    
    public func pane(for identifier: PaneIdentifier) -> SystemPreferencesPane{
        switch identifier {
        case .accessibility:
            return accessibility
        }
    }
    
}

public class SystemPreferencesPane{
    
}

public class AccessibilitySystemPreferencesPane: SystemPreferencesPane{
    
    
    
}
