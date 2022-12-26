// Copyright 2020-2022 Raising the Floor - International
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
import MorphicMacOSNative
import MorphicSettings
import MorphicUIAutomation

// MARK: scripts to open preferences panes for the user

class SettingsLinkActions {
    public enum SystemPreferencePane {
        case accessibilityOverview
        case accessibilityDisplayColorFilters
        case accessibilityDisplayCursor
        case accessibilityDisplayDisplay
        case accessibilitySpeech
        case accessibilityZoom
        case appearance
        case displaysDisplay
        case displaysNightShift
        case keyboardKeyboard
        case keyboardShortcutsScreenshots
        case languageandregionGeneral
        case mouse
    }

    static func openSystemSettingsPaneWithTelemetry(_ pane: SystemPreferencePane, category systemSettingsCategory: String) async throws {
        defer {
            AppDelegate.shared.recordCountlyOpenSystemSettingsEvent(category: systemSettingsCategory, tag: 1)
        }
        try await openSystemSettingsPane(pane)
    }

    // NOTE: this legacy implementation of openSystemSettingsPane is only compatible with macOS versions prior to macOS 13.0; once we deprecate support for earlier versions of macOS, we should delete this function and its callback
    static func openSystemSettingsPane(_ pane: SystemPreferencePane) async throws {
        if #available(macOS 13.0, *) {
            // NOTE: we will wait up to 5 seconds for the System Settings app to launch/attach; we may want to tweak this value in the future based on user feedback
            let waitForSystemSettingsLaunchTimespan = TimeInterval(5.0)

            let waitUntilFinishedLaunchingDeadline = ProcessInfo.processInfo.systemUptime + waitForSystemSettingsLaunchTimespan

            let systemSettingsApp: SystemSettingsApp
            do {
                systemSettingsApp = try await SystemSettingsApp.launchOrAttach(waitUntilFinishedLaunching: waitForSystemSettingsLaunchTimespan)
            } catch let error {
                throw error // UIAutomationApp.LaunchError
            }

            // NOTE: at this point, we have launched or attached to the System Settings app
            
            // make sure that the main window is available
            let waitUntilMainWindowIsAvailableInterval = Double.maximum(waitUntilFinishedLaunchingDeadline - ProcessInfo.processInfo.systemUptime, 0)
            let mainWindowIsAvailable: Bool
            do {
                mainWindowIsAvailable = try await systemSettingsApp.waitUntilMainWindowIsAvailable(waitUntilMainWindowIsAvailableInterval)
            } catch let error {
                throw error
            }
            guard mainWindowIsAvailable == true else {
                throw SystemSettingsApp.NavigationError.unspecified
            }

            //

            let waitForNavigationTimespan = TimeInterval(5.0)
            
            switch pane {
            case .accessibilityOverview:
                _ = try await systemSettingsApp.navigateTo(.accessibility, waitAtMost: waitForNavigationTimespan)
            case .accessibilityDisplayColorFilters:
                _ = try await systemSettingsApp.navigateTo(.colorFilters, waitAtMost: waitForNavigationTimespan)
            case .accessibilityDisplayCursor:
                _ = try await systemSettingsApp.navigateTo(.pointerSize, waitAtMost: waitForNavigationTimespan)
            case .accessibilityDisplayDisplay:
                _ = try await systemSettingsApp.navigateTo(.contrast, waitAtMost: waitForNavigationTimespan)
            case .accessibilitySpeech:
                _ = try await systemSettingsApp.navigateTo(.speech, waitAtMost: waitForNavigationTimespan)
            case .accessibilityZoom:
                _ = try await systemSettingsApp.navigateTo(.magnifier, waitAtMost: waitForNavigationTimespan)
            case .appearance:
                _ = try await systemSettingsApp.navigateTo(.appearance, waitAtMost: waitForNavigationTimespan)
            case .displaysDisplay:
                _ = try await systemSettingsApp.navigateTo(.displayBrightness, waitAtMost: waitForNavigationTimespan)
            case .displaysNightShift:
                _ = try await systemSettingsApp.navigateTo(.nightShift, waitAtMost: waitForNavigationTimespan)
            case .keyboardKeyboard:
                _ = try await systemSettingsApp.navigateTo(.keyboard, waitAtMost: waitForNavigationTimespan)
            case .keyboardShortcutsScreenshots:
                _ = try await systemSettingsApp.navigateTo(.screenshotKeyboardShortcuts, waitAtMost: waitForNavigationTimespan)
            case .languageandregionGeneral:
                _ = try await systemSettingsApp.navigateTo(.languageAndRegion, waitAtMost: waitForNavigationTimespan)
            case .mouse:
                _ = try await systemSettingsApp.navigateTo(.mouse, waitAtMost: waitForNavigationTimespan)
            }

            // NOTE: at this point, we have opened the requested view (category) within System Settings

            // show System Settings and raise it to the top of the application window stack
            let activateSuccess = systemSettingsApp.activate(options: .activateIgnoringOtherApps)
            guard activateSuccess == true else {
                throw MorphicError.unspecified
            }
        } else {
            // macOS 12.x and earlier
            switch pane {
            case .accessibilityOverview:
                let accessibilityUIAutomation = AccessibilityUIAutomation()
                accessibilityUIAutomation.showAccessibilityOverviewPreferences(completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .accessibilityDisplayColorFilters:
                let accessibilityUIAutomation = AccessibilityUIAutomation()
                accessibilityUIAutomation.showAccessibilityDisplayPreferences(tab: "Color Filters", completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .accessibilityDisplayCursor:
                let accessibilityUIAutomation = AccessibilityUIAutomation()
                let tabName: String
                if #available(macOS 12.0, *) {
                    // in macOS 12.0, this tab was renamed "Pointer"
                    tabName = "Pointer"
                } else {
                    // in earlier versions of macOS, this tab was called "Cursor"
                    tabName = "Cursor"
                }
                accessibilityUIAutomation.showAccessibilityDisplayPreferences(tab: tabName, completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .accessibilityDisplayDisplay:
                let accessibilityUIAutomation = AccessibilityUIAutomation()
                accessibilityUIAutomation.showAccessibilityDisplayPreferences(tab: "Display", completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .accessibilitySpeech:
                let accessibilityUIAutomation = AccessibilityUIAutomation()
                accessibilityUIAutomation.showAccessibilitySpeechPreferences(completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .accessibilityZoom:
                let accessibilityUIAutomation = AccessibilityUIAutomation()
                accessibilityUIAutomation.showAccessibilityZoomPreferences(completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .appearance:
                // NOTE: the dark mode (appearance) settings were located in the General tab in macOS v12.x and earlier
                let generalUIAutomation = GeneralUIAutomation()
                generalUIAutomation.showGeneralPreferences(completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .displaysDisplay:
                let displaysUIAutomation = DisplaysUIAutomation()
                displaysUIAutomation.showDisplaysPreferences(tabTitled: "Display", completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .displaysNightShift:
                let displaysUIAutomation = DisplaysUIAutomation()
                displaysUIAutomation.showDisplaysPreferences(tabTitled: "Night Shift", completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .keyboardKeyboard:
                let keyboardUIAutomation = KeyboardUIAutomation()
                keyboardUIAutomation.showKeyboardPreferences(tabTitled: "Keyboard", completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .keyboardShortcutsScreenshots:
                let keyboardUIAutomation = KeyboardUIAutomation()
                keyboardUIAutomation.showKeyboardShortcutsPreferences(categoryTitled: "Screenshots", completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .languageandregionGeneral:
                let languageAndRegionUIAutomation = LanguageAndRegionUIAutomation()
                languageAndRegionUIAutomation.showLanguageAndRegionPreferences(tabTitled: "General", completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            case .mouse:
                let mouseUIAutomation = MouseUIAutomation()
                mouseUIAutomation.showMousePreferences(completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
            }
        }
    }
    
    // NOTE: this function exists only to support our legacy code (for macOS 12.x and earlier); we should remove this function only all calls to it are eventually removed
    private static func raiseSystemPreferencesAfterNavigation(_ uiElement: MorphicSettings.UIElement?) {
        guard let _ = uiElement else {
            // if we could not successfully launch System Preferences and navigate to this pane, log the error
            // NOTE for future enhancement: notify the user of any errors here (and retry or try different methods)
            NSLog("Could not open settings pane")
            return
        }
        
        // show System Preferences and raise it to the top of the application window stack
        guard let systemPreferencesApplication = NSRunningApplication.runningApplications(withBundleIdentifier: SystemPreferencesElement.bundleIdentifier).first else {
            return
        }
        systemPreferencesApplication.activate(options: .activateIgnoringOtherApps)
    }
}
