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

import Cocoa
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "WordRibbonUIAutomation")

public class WordRibbonUIAutomation: UIAutomation {
    public required init() {
    }
    
    public func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        WordRibbonUIAutomation.RefreshRibbon()     //making this default action for now
    }
    
    public static func RefreshRibbon() {
        let app = WordApplicationElement()
        app.open(hide: true, attachOnly: true, completion: {
            success in
            guard success else {
                os_log("No open Word instance found")
                return  //if we add outputs, this should be marked as a success
            }
            do {
                for window: WindowElement in app.windows! {
                    if(window.accessibilityElement.subrole == .dialog) {
                        let close = window.closeButton()
                        try close?.perform(action: .press)
                    }
                }
            } catch {
                return
            }
            guard WordRibbonUIAutomation.NewDocument(app: app) else {
                os_log("Could not open new Word document")
                return
            }
            let nwindow = app.windows?.first
            guard WordRibbonUIAutomation.CallPreferences(app: app) else {
                os_log("Could not open Word preferences")
                return
            }
            for window: WindowElement in app.windows! {
                let windowTitle: String = window.title!
                if(windowTitle == "Word Preferences") {
                    do{ //sends preferences window offscreen for duration
                        try window.accessibilityElement.setValue(CGPoint(x: 0, y: 100000), forAttribute: .position)
                    } catch {}
                    window.perform(action: .press(buttonTitle: "Ribbon & Toolbar")) { (success, _) in
                        if(!success) {
            	                os_log("Error switching to Ribbon tab")
                            return
                        }
                        do {
                            let check = window.firstCheckbox()
                            try check?.accessibilityElement.perform(action: .press)
                            try check?.accessibilityElement.perform(action: .press)
                            window.perform(action: .press(buttonTitle: "Save"), completion: { (success2, _) in
                                if(!success2) {
                                    os_log("Error applying settings")
                                    return
                                }
                                do {
                                    let close = window.closeButton()
                                    try close?.perform(action: .press)
                                    let nclose = nwindow?.closeButton()
                                    try nclose?.perform(action: .press)
                                    return
                                } catch {
                                    os_log("Error closing preferences window")
                                    return
                                }
                            })
                        } catch {
                            os_log("Error selecting checkbox in preferences")
                            return
                        }
                    }
                    return
                }
            }
        });
    }
    
    private static func CallPreferences(app: WordApplicationElement) -> Bool {
        guard let topMenu: MorphicA11yUIElement = app.accessibilityElement.value(forAttribute: .menuBar) else {
            return false
        }
        do {
            for menuHeader: MorphicA11yUIElement in topMenu.children()! {
                let headerTitle: String = menuHeader.value(forAttribute: NSAccessibility.Attribute.title)!
                if(headerTitle == "Word") {
                    let subMenu: MorphicA11yUIElement = (menuHeader.children()?.first)!
                    for menuItem: MorphicA11yUIElement in subMenu.children()! {
                        let itemTitle: String = menuItem.value(forAttribute: NSAccessibility.Attribute.title)!
                        if(itemTitle == "Preferences...") {
                            try menuItem.perform(action: NSAccessibility.Action.press)
                            return true
                        }
                    }
                }
            }
        } catch {
            return false
        }
        return false
    }
    
    private static func NewDocument(app: WordApplicationElement) -> Bool {
        guard let topMenu: MorphicA11yUIElement = app.accessibilityElement.value(forAttribute: .menuBar) else {
            return false
        }
        do {
            for menuHeader: MorphicA11yUIElement in topMenu.children()! {
                let headerTitle: String = menuHeader.value(forAttribute: NSAccessibility.Attribute.title)!
                if(headerTitle == "File") {
                    let subMenu: MorphicA11yUIElement = (menuHeader.children()?.first)!
                    for menuItem: MorphicA11yUIElement in subMenu.children()! {
                        let itemTitle: String = menuItem.value(forAttribute: NSAccessibility.Attribute.title)!
                        if(itemTitle == "New Document") {
                            try menuItem.perform(action: NSAccessibility.Action.press)
                            return true
                        }
                    }
                }
            }
        } catch {
            return false
        }
        return false
    }
}
