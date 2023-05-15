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

import Cocoa
import MorphicCore
import MorphicMacOSNative

internal class SystemSettingsAccessibilityDisplayCategoryPane_macOS13: SystemSettingsGroupUIElementWrapper {
    public required init(systemSettingsMainWindow: SystemSettingsMainWindow_macOS13, groupUIElement: GroupUIElement) {
        super.init(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: groupUIElement)
    }
    
    public enum Checkbox: A11yUICheckboxIdentifier {
        case colorFilters
        case differentiateWithoutColor
        case increaseContrast
        case invertColors
        case reduceMotion
        case reduceTransparency
        case shakeMousePointerToLocate
        
        public func a11yUIIdentifier() -> String {
            // NOTE: at the time of writing, these have been validated with macOS 13.0 (but not earlier versions)
            if #available(macOS 13.0, *) {
                switch self {
                case .colorFilters:
                    return "AX_DISPLAY_FILTER_ENABLED"
                case .differentiateWithoutColor:
                    return "AX_DIFFERENTIATE_WITHOUT_COLOR"
                case .increaseContrast:
                    return "AX_INCREASE_CONTRAST"
                case .invertColors:
                    return "AX_INVERT_COLOR"
                case .reduceMotion:
                    return "AX_REDUCE_MOTION"
                case .reduceTransparency:
                    return "AX_REDUCE_TRANSPARENCY"
                case .shakeMousePointerToLocate:
                    return "AX_FIND_CURSOR"
                }
            } else {
                fatalError("This version of macOS is not yet supported by this code")
            }
        }
    }

    public enum RadioGroup: A11yUIRadioGroupIdentifier {
        case invertColorsMode
        
        public func a11yUIIdentifier() -> String {
            // NOTE: at the time of writing, these have been validated with macOS 13.0 (but not earlier versions)
            if #available(macOS 13.0, *) {
                switch self {
                case .invertColorsMode:
                    return "AX_INVERT_COLOR_MODE"
                }
            } else {
                fatalError("This version of macOS is not yet supported by this code")
            }
        }
    }
    
    public enum InvertColorsModeRadioButton: A11yUIRadioButtonLabel {
        case classic
        case smart
        
        public func a11yUILabel() -> String {
            // NOTE: at the time of writing, these have been validated with macOS 13.0 (but not earlier versions)
            if #available(macOS 13.0, *) {
                switch self {
                case .classic:
                    return "Classic"
                case .smart:
                    return "Smart"
                }
            } else {
                fatalError("This version of macOS is not yet supported by this code")
            }
        }
    }

    public enum Slider: A11yUISliderIdentifier {
        case colorFiltersIntensity
        case pointerSize
        
        public func a11yUIIdentifier() -> String {
            // NOTE: at the time of writing, these have been validated with macOS 13.0 (but not earlier versions)
            if #available(macOS 13.0, *) {
                switch self {
                case .colorFiltersIntensity:
                    return "AX_DISPLAY_FILTER_INTENSITY"
                case .pointerSize:
                    return "AX_CURSOR_SIZE"
                }
            } else {
                fatalError("This version of macOS is not yet supported by this code")
            }
        }
    }
}
