// Copyright 2020-2023 Raising the Floor - US, Inc.
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

import Foundation
import MorphicCore
import MorphicMacOSNative
import MorphicSettings

public class AccessibilitySpokenContentUIAutomationScript_macOS13 {
    public static func getSpeakSelectionIsEnabled(sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws -> Bool {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()
        
        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost
        
        // step 1: launch the System Settings app and navigate to the Spoken Content pane
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let accessibilityDisplayCategoryPane = try await Self.launchOrAttachSystemSettingsThenNavigativeToAccessibilitySpokenContent(sequence: sequence, waitFor: waitForTimespan)

        // step 2: check/uncheck the "Speak selection" checkbox (if it is not already appropriately checked/unchecked)
        let speakSelectionIsEnabled = try accessibilityDisplayCategoryPane.getValue(forCheckboxWithIdentifier: SystemSettingsAccessibilitySpokenContentCategoryPane_macOS13.Checkbox.speakSelection)
        return speakSelectionIsEnabled
    }

    public static func setSpeakSelectionIsEnabled(_ value: Bool, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost
        
        // step 1: launch the System Settings app and navigate to the Spoken Content pane
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let accessibilityDisplayCategoryPane = try await Self.launchOrAttachSystemSettingsThenNavigativeToAccessibilitySpokenContent(sequence: sequence, waitFor: waitForTimespan)

        // step 2: check/uncheck the "Increase contrast" checkbox (if it is not already appropriately checked/unchecked)
        try accessibilityDisplayCategoryPane.setValue(value, forCheckboxWithIdentifier: SystemSettingsAccessibilitySpokenContentCategoryPane_macOS13.Checkbox.speakSelection)

        // step 3: verify that the value has been changed successfully
        let remainingWaitTime = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let verifySuccess = try await AsyncUtils.wait(atMost: remainingWaitTime) {
            let checkboxValue = try accessibilityDisplayCategoryPane.getValue(forCheckboxWithIdentifier: SystemSettingsAccessibilitySpokenContentCategoryPane_macOS13.Checkbox.speakSelection)
            return checkboxValue == value
        }
        if verifySuccess == false {
            // timeout occurred while waiting for checkbox to be confirmed as changed
            throw MorphicError.unspecified
        }
    }
    
    /* helper functions */
    
    private static func launchOrAttachSystemSettingsThenNavigativeToAccessibilitySpokenContent(sequence: UIAutomationSequence?, waitFor: TimeInterval) async throws -> SystemSettingsAccessibilitySpokenContentCategoryPane_macOS13 {
        let (categoryPane, launchedSystemSettingsApp) = try await SystemSettingsApp.launchOrAttachThenNavigateTo(.accessibilitySpokenContent, waitUntilFinishedLaunching: waitFor)
        if launchedSystemSettingsApp == true { sequence?.setScriptLaunchedApplicationFlag() }

        return categoryPane as! SystemSettingsAccessibilitySpokenContentCategoryPane_macOS13
    }
}
