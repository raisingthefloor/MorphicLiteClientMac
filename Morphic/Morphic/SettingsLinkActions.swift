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
import MorphicSettings

// MARK: scripts to open preferences panes for the user

class SettingsLinkActions {
    public enum SystemPreferencePane {
        case accessibilityOverview
        case accessibilityDisplayColorFilters
        case accessibilityDisplayDisplay
        case accessibilitySpeech
        case accessibilityZoom
        case displaysNightShift
        case general
    }
    
    static func openSystemPreferencesPane(_ pane: SystemPreferencePane) {
        switch pane {
        case .accessibilityOverview:
            let accessibilityUIAutomation = AccessibilityUIAutomation()
            accessibilityUIAutomation.showAccessibilityOverviewPreferences(completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
        case .accessibilityDisplayColorFilters:
            let accessibilityUIAutomation = AccessibilityUIAutomation()
            accessibilityUIAutomation.showAccessibilityDisplayPreferences(tab: "Color Filters", completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
        case .accessibilityDisplayDisplay:
            let accessibilityUIAutomation = AccessibilityUIAutomation()
            accessibilityUIAutomation.showAccessibilityDisplayPreferences(tab: "Display", completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
        case .accessibilitySpeech:
            let accessibilityUIAutomation = AccessibilityUIAutomation()
            accessibilityUIAutomation.showAccessibilitySpeechPreferences(completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
        case .accessibilityZoom:
            let accessibilityUIAutomation = AccessibilityUIAutomation()
            accessibilityUIAutomation.showAccessibilityZoomPreferences(completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
        case .displaysNightShift:
            let displaysUIAutomation = DisplaysUIAutomation()
            displaysUIAutomation.showDisplaysPreferences(tabTitled: "Night Shift", completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
        case .general:
            let accessibilityUIAutomation = GeneralUIAutomation()
            accessibilityUIAutomation.showGeneralPreferences(completion: SettingsLinkActions.raiseSystemPreferencesAfterNavigation)
        }
    }
    
    private static func raiseSystemPreferencesAfterNavigation(_ uiElement: UIElement?) {
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
