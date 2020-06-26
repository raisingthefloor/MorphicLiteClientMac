//
//  SystemPreferencesElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class SystemPreferencesElement: ApplicationElement{
    
    public init() {
        super.init(bundleIdentifier: "com.apple.systempreferences")
    }
    
    public required init(accessibilityElement: MorphicA11yUIElement?) {
        fatalError("init(accessibilityElement:) has not been implemented")
    }
    
    public enum PaneIdentifier{
        case accessibility
        
        public var buttonTitle: String{
            get{
                switch self {
                case .accessibility:
                    return "Accessibility"
                }
            }
        }
        
        public var windowTitle: String{
            get{
                switch self {
                case .accessibility:
                    return "Accessibility"
                }
            }
        }
    }
    
    public func showAccessibility(completion: @escaping (_ success: Bool, _ pane: AccessibilityPreferencesElement?) -> Void){
        return show(pane: .accessibility, completion: completion)
    }
    
    public func show<ElementType: UIElement>(pane identifier: PaneIdentifier, completion: @escaping (_ success: Bool, _ pane: ElementType?) -> Void){
        guard let window = mainWindow else{
            completion(false, nil)
            return
        }
        guard window.raise() else{
            completion(false, nil)
            return
        }
        guard window.title != identifier.windowTitle else{
            completion(true, ElementType(accessibilityElement: window.accessibilityElement))
            return
        }
        guard let showAllButton = window.toolbar?.button(titled: "Show All") else{
            completion(false, nil)
            return
        }
        guard showAllButton.press() else{
            completion(false, nil)
            return
        }
        wait(atMost: 3.0, for: { window.title == "System Preferences" }){
            success in
            guard success else{
                completion(false, nil)
                return
            }
            guard let paneButton = window.button(titled: identifier.buttonTitle) else{
                completion(false, nil)
                return
            }
            guard paneButton.press() else{
                completion(false, nil)
                return
            }
            self.wait(atMost: 3.0, for: { window.title == identifier.windowTitle }){
                success in
                completion(success, ElementType(accessibilityElement: window.accessibilityElement))
            }
        }
    }
    
}
