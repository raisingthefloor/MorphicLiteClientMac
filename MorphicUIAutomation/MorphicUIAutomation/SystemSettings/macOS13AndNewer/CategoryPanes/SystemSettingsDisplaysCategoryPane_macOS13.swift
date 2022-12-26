// Copyright 2020-2022 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/raisingthefloor/morphic-macos/blob/master/LICENSE.txt
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
import MorphicMacOSNative

internal class SystemSettingsDisplaysCategoryPane_macOS13 {
    private let systemSettingsMainWindow: SystemSettingsMainWindow_macOS13
    private let groupUIElement: GroupUIElement
    
    public required init(systemSettingsMainWindow: SystemSettingsMainWindow_macOS13, groupUIElement: GroupUIElement) {
        self.systemSettingsMainWindow = systemSettingsMainWindow
        self.groupUIElement = groupUIElement
    }
    
    public enum Button {
        case nightShift
    }
    
    private static func labelForButton(_ button: Button) -> String {
        if #available(macOS 13.0, *) {
            switch button {
            case .nightShift:
                return "Night Shift…"
            }
        } else {
            fatalError("This version of macOS is not yet supported by this code")
        }
    }

    /// NOTE: we may be looking at the wrong automation value; "Night Shift..." may be a title instead of a label, etc.  TBD.
    public func pressButton(_ button: Button) throws {
        let requiredButtonLabel = SystemSettingsDisplaysCategoryPane_macOS13.labelForButton(button)

        // STEP 1: find the button by its text
        let buttonA11yUiElement: MorphicA11yUIElement?
        switch button {
        case .nightShift:
            do {
                // NOTE: the button in this dialog is within a scroll view, potentially at various depths, etc.  Ideally we would navigate through a more specific hieratchy; for our initial implementation, we are choosing to find the element--but if we find that there are multiple buttons and we are locating the wrong one, then we should revise this code
                buttonA11yUiElement = try self.groupUIElement.accessibilityUiElement.dangerousFirstDescendant(where: {
                    guard $0.role == .button else {
                        return false
                    }

                    // NOTE: in our testing, the button label in this dialog is represented as the description value (i.e. not the title, and not the title ui element's value)
                    // NOTE: if we cannot get the title of the label, we intentionally ignore the issue
                    guard let buttonLabel: String = try? $0.value(forAttribute: .description) else {
                        return false
                    }

                    return buttonLabel == requiredButtonLabel
                })
            } catch let error {
                throw error
            }
        }

        // if we could not find the button, return an error
        guard let buttonA11yUiElement = buttonA11yUiElement else {
            throw SystemSettingsApp.NavigationError.unspecified
        }
        
        // STEP 2: convert the button to a ButtonUIElement and press it
        let buttonUIElement = ButtonUIElement(accessibilityUiElement: buttonA11yUiElement)
        do {
            try buttonUIElement.press()
        } catch let error {
            throw error
        }
    }
    
}
