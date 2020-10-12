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

public struct MorphicDisplayAccessibilitySettings {
    public static var colorFiltersEnabled: Bool {
        get {
            // NOTE: per our manual reverse engineering analysis, arg0 must be a nonzero number (or else the function will return 0); in testing, only arg0 value "1" (out of a range of 0...3) successfully retrieved the enabled state.  Reverse-engineering of the code which sets System Preference's checkbox states from the corresponding plist file also uses a fixed value of "1".
            let resultAsInt32: Int32 = MADisplayFilterPrefGetCategoryEnabled(1)
            let result: Bool = resultAsInt32 != 0
            return result
        }
    }
    
    // NOTE: this function does not currently disable "invert colors" when turning on color filters; if that behavior (i.e. the behavior caused by enabling color filters in System Preferences) is required then the caller should currently use UI automation instead.
    public static func setColorFiltersEnabled(_ value: Bool) {
        // NOTE: per our manual reverse engineering analysis, arg0 must be a nonzero number (or else the function will return 0); in testing, only arg0 value "1" (out of a range of 0...3) successfully set the enabled state.  Reverse-engineering of the code which sets System Preference's checkbox states from the corresponding plist file also uses a fixed value of "1".
        // NOTE: calling this function appears to send out a system event (which System Preferences > Accessibility > Display > Color Filters reflects in real-time)
        MADisplayFilterPrefSetCategoryEnabled(1 /* presumably index or display id */, value ? 1 : 0 /* enabled state */)
        
        // NOTE: the OS disables "invert colors" if color filters are enabled; we would do the same here, but we would need "user-preference-write" or "file-write-data" sandbox access to write preferences outside of our application's container
//        MorphicColorFilters.setInvertColorsEnabled(false)

        // matching the behavior of the System Preferences: call UAGrayscaleSynchronizeLegacyPref() after updating the "color filters enabled" and "invert colors" properties
        UAGrayscaleSynchronizeLegacyPref()
    }
    
    public static var invertColorsEnabled: Bool {
        get {
            let resultAsInt32: Int32 = UAWhiteOnBlackIsEnabled()
            let result: Bool = resultAsInt32 != 0
            return result
        }
    }
    
    public static func setInvertColorsEnabled(_ value: Bool) {
        UAInvertColorsUserInitiatedSetEnabled(value == true ? 1 : 0)
    }
    
    public static var increaseContrastEnabled: Bool {
        get {
            if #available(macOS 10.15, *) {
                let resultAsInt32: Int32 = UAIncreaseContrastIsEnabled()
                let result: Bool = resultAsInt32 != 0
                return result
            } else {
                fatalError("UAIncreaseContrastIsEnabled is not supported in this version of macOS")
            }
        }
    }
    
    // NOTE: we would need "user-preference-write" or "file-write-data" sandbox access to write preferences outside of our application's container
    public static func setIncreaseContrastEnabled(_ value: Bool) {
        if #available(macOS 10.15, *) {
            // get the current state of "increase contrast enabled"
            let currentIncreaseContrastEnabled = MorphicDisplayAccessibilitySettings.increaseContrastEnabled
            
            // only update our contrast (and deal with reducing transparency if necessary) if it the state is actually changing; this is following the same pattern used by "System Preferences > Accessibility > Display > Display > 'Increase contrast'" in macOS 10.15.7; it's probably not a necessary check, but since this is reverse-engineered we're doing it out of an abundance of caution
            if currentIncreaseContrastEnabled != value {
                UAIncreaseContrastSetEnabled(value == true ? 1 : 0)
            }
        } else {
            fatalError("UAIncreaseContrastSetEnabled is not supported in this version of macOS")
        }
    }
}
