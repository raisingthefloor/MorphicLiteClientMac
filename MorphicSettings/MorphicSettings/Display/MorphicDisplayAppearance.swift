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

public struct MorphicDisplayAppearance {
    public enum AppearanceTheme: Int {
        case light = 0
        case dark = 1
    }
    
    public static var currentAppearanceTheme: AppearanceTheme {
        get {
            let displayAppearanceAsUInt32 = SLSGetAppearanceThemeLegacy()
            switch displayAppearanceAsUInt32 {
            case 0:
                return .light
            case 1:
                return .dark
            default:
                // if we receive any other result, return "light" to gracefully degrade
                assertionFailure("SLSGetAppearanceThemeLegacy() returned unknown result")
                return .light
            }
        }
    }
    
    public static func setCurrentAppearanceTheme(_ appearanceTheme: AppearanceTheme) {
        let appearanceThemeAsApiArgument: UInt8
        
        switch appearanceTheme {
        case .light:
            appearanceThemeAsApiArgument = 0
        case .dark:
            appearanceThemeAsApiArgument = 1
        }
           
        // set the new appearance theme
        SLSSetAppearanceThemeLegacy(appearanceThemeAsApiArgument)
        
        // make sure that we set the theme to "not switch automatically" (or else macOS will change it again)
        let falseAsUInt32: UInt32 = 0
        SLSSetAppearanceThemeSwitchesAutomatically(falseAsUInt32)
    }
}
