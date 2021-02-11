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

public class SystemPreferencesElement: ApplicationElement {
    
    public static let bundleIdentifier = "com.apple.systempreferences"
    
    public init() {
        super.init(bundleIdentifier: SystemPreferencesElement.bundleIdentifier)
    }
    
    public required init(accessibilityElement: MorphicA11yUIElement?) {
        fatalError("init(accessibilityElement:) has not been implemented")
    }
    
    public enum PaneIdentifier {
        case accessibility
        case displays
        case general
        case keyboard
        case languageAndRegion
        case mouse 
        
        public var buttonTitle: String {
            get {
                switch self {
                case .accessibility:
                    return "Accessibility"
                case .displays:
                    return "Displays"
                case .general:
                    return "General"
                case .keyboard:
                    return "Keyboard"
                case .languageAndRegion:
                    return "Language\n& Region"
                case .mouse:
                    return "Mouse"
                }
            }
        }
        
        public enum IdentificationMethod {
            case uiElementMatchFunction(_ function: (_ uiElement: UIElement) -> Bool)
            case windowTitle(_ title: String)
        }
        
        public var paneIdentificationMethod: PaneIdentifier.IdentificationMethod {
            get {
                switch self {
                case .accessibility:
                    return .windowTitle("Accessibility")
                case .displays:
                    return .uiElementMatchFunction(
                        { displaysAsUIElement in
                            guard let displays = displaysAsUIElement as? DisplaysPreferencesElement else {
                                return false
                            }
                            return displays.checkbox(titled: "Show mirroring options in the menu bar when available") != nil
                        })
                case .general:
                    return .windowTitle("General")
                case .keyboard:
                    return .windowTitle("Keyboard")
                case .languageAndRegion:
                    return .windowTitle("Language & Region")
                case .mouse:
                    return .windowTitle("Mouse")
                }
            }
        }
    }
    
    public func showAccessibility(completion: @escaping (_ success: Bool, _ pane: AccessibilityPreferencesElement?) -> Void) {
        return show(pane: .accessibility, completion: completion)
    }

    public func showDisplays(completion: @escaping (_ success: Bool, _ pane: DisplaysPreferencesElement?) -> Void) {
        return show(pane: .displays, completion: completion)
    }

    public func showGeneral(completion: @escaping (_ success: Bool, _ pane: GeneralPreferencesElement?) -> Void) {
        return show(pane: .general, completion: completion)
    }

    public func showKeyboard(completion: @escaping (_ success: Bool, _ pane: KeyboardPreferencesElement?) -> Void) {
        return show(pane: .keyboard, completion: completion)
    }

    public func showLanguageAndRegion(completion: @escaping (_ success: Bool, _ pane: LanguageAndRegionPreferencesElement?) -> Void) {
        return show(pane: .languageAndRegion, completion: completion)
    }

    public func showMouse(completion: @escaping (_ success: Bool, _ pane: MousePreferencesElement?) -> Void) {
        return show(pane: .mouse, completion: completion)
    }

    public func show<ElementType: UIElement>(pane identifier: PaneIdentifier, completion: @escaping (_ success: Bool, _ pane: ElementType?) -> Void) {
        var window: WindowElement! = mainWindow
        if window == nil {
            // if System Preferences does not expose a mainWindow, we need to try to find its main (only) window and raise it
            guard let windows = windows else {
                completion(false, nil)
                return
            }
            // if there is more than one window, we have an unknown situation; perhaps we could raise them all but for now we should just assert
            guard windows.count == 1 else {
                assertionFailure("System Preferences does not expose a main window, but exposes multiple windows (so we don't know which one to raise)")
                completion(false, nil)
                return
            }
            window = windows[0]

            // raise the sole System Preferences window (so it becomes the mainWindow)
            // NOTE: if desired, in the future we could requery for the "mainWindow"
            guard window.raise() else {
                completion(false, nil)
                return
            }
        }
        //
        let windowAsUIElement = ElementType(accessibilityElement: window.accessibilityElement)
        //
        switch identifier.paneIdentificationMethod {
        case .uiElementMatchFunction(let matchFunction):
            if matchFunction(windowAsUIElement) == true {
                completion(true, ElementType(accessibilityElement: window.accessibilityElement))
                return
            }
        case .windowTitle(let identifierWindowTitle):
            guard window.title != identifierWindowTitle else {
                completion(true, ElementType(accessibilityElement: window.accessibilityElement))
                return
            }
        }
        guard let showAllButton = window.toolbar?.button(titled: "Show All") else {
            completion(false, nil)
            return
        }
        guard showAllButton.press() else {
            completion(false, nil)
            return
        }
        AsyncUtils.wait(atMost: 3.0, for: { window.title == "System Preferences" }) {
            success in
            guard success else {
                completion(false, nil)
                return
            }
            guard let paneButton = window.button(titled: identifier.buttonTitle) else {
                completion(false, nil)
                return
            }
            guard paneButton.press() else {
                completion(false, nil)
                return
            }
            AsyncUtils.wait(atMost: 3.0,
                for: {
                    switch identifier.paneIdentificationMethod {
                    case .uiElementMatchFunction(let matchFunction):
                        return matchFunction(windowAsUIElement) == true
                    case .windowTitle(let identifierWindowTitle):
                        return window.title == identifierWindowTitle
                    }
            }) {
                success in
                completion(success, ElementType(accessibilityElement: window.accessibilityElement))
            }
        }
    }
    
}
