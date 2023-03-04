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

public class AccessibilityDisplayUIAutomationScript_macOS13 {
    public static func getIncreaseContrastIsEnabled(sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws -> Bool {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost
        
        // step 1: launch the System Settings app and navigate to the Accessibility > Display pane
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let accessibilityDisplayCategoryPane = try await Self.launchOrAttachSystemSettingsThenNavigativeToAccessibilityDisplay(sequence: sequence, waitFor: waitForTimespan)

        // step 2: check/uncheck the "Increase contrast" checkbox (if it is not already appropriately checked/unchecked)
        let increaseContrastIsEnabled = try accessibilityDisplayCategoryPane.getValue(forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane_macOS13.Checkbox.increaseContrast)
        
        return increaseContrastIsEnabled
    }

    public static func setIncreaseContrastIsEnabled(_ value: Bool, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost
                
        // step 1: launch the System Settings app and navigate to the Accessibility > Display pane
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let accessibilityDisplayCategoryPane = try await Self.launchOrAttachSystemSettingsThenNavigativeToAccessibilityDisplay(sequence: sequence, waitFor: waitForTimespan)

        // step 2: check/uncheck the "Increase contrast" checkbox (if it is not already appropriately checked/unchecked)
        try accessibilityDisplayCategoryPane.setValue(value, forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane_macOS13.Checkbox.increaseContrast)

        // step 3: verify that the value has been changed successfully
        let remainingWaitTime = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let verifySuccess = try await AsyncUtils.wait(atMost: remainingWaitTime) {
            let checkboxValue = try accessibilityDisplayCategoryPane.getValue(forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane_macOS13.Checkbox.increaseContrast)
            return checkboxValue == value
        }
        if verifySuccess == false {
            // timeout occurred while waiting for checkbox to be confirmed as changed
            throw MorphicError.unspecified
        }
    }

    public static func setReduceTransparencyIsEnabled(_ value: Bool, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost
                
        // step 1: launch the System Settings app and navigate to the Accessibility > Display pane
        let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let accessibilityDisplayCategoryPane = try await Self.launchOrAttachSystemSettingsThenNavigativeToAccessibilityDisplay(sequence: sequence, waitFor: waitForTimespan)

        // step 2: check/uncheck the "Increase contrast" checkbox (if it is not already appropriately checked/unchecked)
        try accessibilityDisplayCategoryPane.setValue(value, forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane_macOS13.Checkbox.reduceTransparency)

        // step 3: verify that the value has been changed successfully
        let remainingWaitTime = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let verifySuccess = try await AsyncUtils.wait(atMost: remainingWaitTime) {
            let checkboxValue = try accessibilityDisplayCategoryPane.getValue(forCheckboxWithIdentifier: SystemSettingsAccessibilityDisplayCategoryPane_macOS13.Checkbox.reduceTransparency)
            return checkboxValue == value
        }
        if verifySuccess == false {
            // timeout occurred while waiting for checkbox to be confirmed as changed
            throw MorphicError.unspecified
        }
    }
        
    public static func setColorFilterType(_ value: MorphicSettings.AccessibilityDisplaySettings.ColorFilterType, sequence: UIAutomationSequence? = nil, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        try UIAutomationScriptUtils.verifyA11yAuthorization()

        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost

        // check the current color filter type (in case it's not necessary to change anything)
        do {
            if let currentValue = try AccessibilityDisplaySettings.getColorFilterType() {
                // if there is nothing to change, return now
                if currentValue.intValue == value.intValue {
                    return
                }
            }
        } catch {
            // ignore any errors while trying to get color filter type
        }

        // step 1: launch the System Settings app and navigate to the Accessibility > Display pane
        var waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let accessibilityDisplayCategoryPane = try await Self.launchOrAttachSystemSettingsThenNavigativeToAccessibilityDisplay(sequence: sequence, waitFor: waitForTimespan)

        // step 2: set the value of the Color Filter section's "Filter type" drop-down
        guard let valueAsString = value.stringValue else {
            // if the requested value is not representable with a string (which we need so we can select the appropriate pop-up item), throw an error
            throw MorphicError.unspecified
        }
        waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        try await accessibilityDisplayCategoryPane.setValue(valueAsString, forPopUpButtonWithIdentifier: SystemSettingsAccessibilityZoomCategoryPane_macOS13.PopUpButton.colorFilterType, waitAtMost: waitForTimespan)
        
        // step 3: verify that the value has been changed successfully
        let remainingWaitTime = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let verifySuccess = try await AsyncUtils.wait(atMost: remainingWaitTime) {
            let colorFilterTypeValue = try accessibilityDisplayCategoryPane.getValue(forPopUpButtonWithIdentifier: SystemSettingsAccessibilityZoomCategoryPane_macOS13.PopUpButton.colorFilterType)
            return colorFilterTypeValue == valueAsString
        }
        if verifySuccess == false {
            // timeout occurred while waiting for pop-up to be confirmed as changed
            throw MorphicError.unspecified
        }
    }
    
    /* helper functions */

    private static func launchOrAttachSystemSettingsThenNavigativeToAccessibilityDisplay(sequence: UIAutomationSequence?, waitFor: TimeInterval) async throws -> SystemSettingsAccessibilityDisplayCategoryPane_macOS13 {
        let (categoryPane, launchedSystemSettingsApp) = try await SystemSettingsApp.launchOrAttachThenNavigateTo(.accessibilityDisplay, waitUntilFinishedLaunching: waitFor)
        if launchedSystemSettingsApp == true { sequence?.setScriptLaunchedApplicationFlag() }

        return categoryPane as! SystemSettingsAccessibilityDisplayCategoryPane_macOS13
    }
}
