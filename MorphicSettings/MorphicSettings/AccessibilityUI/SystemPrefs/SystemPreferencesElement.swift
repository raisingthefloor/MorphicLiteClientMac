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
    
    public init() {
        super.init(bundleIdentifier: "com.apple.systempreferences")
    }
    
    public required init(accessibilityElement: MorphicA11yUIElement?) {
        fatalError("init(accessibilityElement:) has not been implemented")
    }
    
    public enum PaneIdentifier {
        case accessibility
        case general
        
        public var buttonTitle: String {
            get{
                switch self {
                case .accessibility:
                    return "Accessibility"
                case .general:
                    return "General"
                }
            }
        }
        
        public var windowTitle: String {
            get{
                switch self {
                case .accessibility:
                    return "Accessibility"
                case .general:
                    return "General"
                }
            }
        }
    }
    
    public func showAccessibility(completion: @escaping (_ success: Bool, _ pane: AccessibilityPreferencesElement?) -> Void) {
        return show(pane: .accessibility, completion: completion)
    }
    
    public func showGeneral(completion: @escaping (_ success: Bool, _ pane: GeneralPreferencesElement?) -> Void) {
        return show(pane: .general, completion: completion)
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
        guard window.title != identifier.windowTitle else {
            completion(true, ElementType(accessibilityElement: window.accessibilityElement))
            return
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
            AsyncUtils.wait(atMost: 3.0, for: { window.title == identifier.windowTitle }) {
                success in
                completion(success, ElementType(accessibilityElement: window.accessibilityElement))
            }
        }
    }
    
}
