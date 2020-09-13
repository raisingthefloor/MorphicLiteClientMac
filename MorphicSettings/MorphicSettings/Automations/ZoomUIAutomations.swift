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
import Carbon.HIToolbox

private let logger = OSLog(subsystem: "MorphicSettings", category: "ZoomUIAutomations")

public class ZoomCheckboxUIAutomation: AccessibilityUIAutomation {
    
    var checkboxTitle: String! { nil }
    
    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        guard let checked = value as? Bool else {
            os_log(.error, log: logger, "Passed non-boolean value")
            completion(false)
            return
        }
        showAccessibilityZoomPreferences {
            accessibility in
            guard let accessibility = accessibility else{
                completion(false)
                return
            }
            guard let checkbox = accessibility.checkbox(titled: self.checkboxTitle) else {
                os_log(.error, log: logger, "Failed to find checkbox")
                completion(false)
                return
            }
            guard checkbox.setChecked(checked) else {
                os_log(.error, log: logger, "Failed to check checkbox")
                completion(false)
                return
            }
            completion(true)
        }
        
    }
    
}

public class ZoomPopupButtonUIAutomation: AccessibilityUIAutomation {
    
    var buttonTitle: String! { nil }
    
    var optionTitles: [Int: String]! { nil }
    
    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        guard let value = value as? Int else {
            os_log(.error, log: logger, "Passed non-int value to popup")
            completion(false)
            return
        }
        guard let stringValue = optionTitles[value] else {
            os_log(.error, log: logger, "Passed invalid int value to popup")
            completion(false)
            return
        }
        showAccessibilityZoomPreferences {
            accessibility in
            guard let accessibility = accessibility else {
                completion(false)
                return
            }
            guard let button = accessibility.popUpButton(titled: self.buttonTitle) else {
                os_log(.error, log: logger, "Failed to find popup button")
                completion(false)
                return
            }
            button.setValue(stringValue) {
                success in
                guard success else {
                    os_log(.error, log: logger, "Failed to set popup button value")
                    completion(false)
                    return
                }
                completion(true)
            }
        }
        
    }
    
}


public class ZoomEnabledUIAutomation: AccessibilityUIAutomation {
    
    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        guard let checked = value as? Bool else {
            os_log(.error, log: logger, "Passed non-boolean value")
            completion(false)
            return
        }
        showAccessibilityZoomPreferences {
            accessibility in
            guard let accessibility = accessibility else {
                completion(false)
                return
            }
            guard let checkbox = accessibility.checkbox(titled: "Use keyboard shortcuts to zoom") else {
                os_log(.error, log: logger, "Failed to find zoom keyboard shortcuts checkbox")
                completion(false)
                return
            }
            guard checkbox.check() else {
                os_log(.error, log: logger, "Failed to enable zoom keyboard shortcuts checkbox")
                completion(false)
                return
            }
            guard let defaults = UserDefaults(suiteName: "com.apple.universalaccess") else {
                os_log(.error, log: logger, "Failed to load defaults to determine current zoom level")
                completion(false)
                return
            }
            if #available(macOS 10.15, *) {
                guard checked != defaults.bool(forKey: "closeViewZoomedIn") else {
                    completion(true)
                    return
                }
            } else {
                // backwards compatibility for macOS 10.14
                if checked == true {
                    guard 1.0 == defaults.double(forKey: "closeViewZoomFactor") else {
                        completion(true)
                        return
                    }
                } else {
                    guard 1.0 != defaults.double(forKey: "closeViewZoomFactor") else {
                        completion(true)
                        return
                    }
                }
            }
            guard WorkspaceElement.shared.sendKey(keyCode: CGKeyCode(kVK_ANSI_8), keyOptions: [.withCommandKey, .withAlternateKey]) else {
                os_log(.error, log: logger, "Failed to send key shortcut")
                completion(false)
                return
            }
            if #available(macOS 10.15, *) {
                AsyncUtils.wait(atMost: 5.0, for: { checked == defaults.bool(forKey: "closeViewZoomedIn") }) {
                    success in
                    completion(success)
                }
            } else {
                // backwards compatibility for macOS 10.14
                AsyncUtils.wait(atMost: 5.0, for: {
                    if checked == true {
                        return 1.0 != defaults.double(forKey: "closeViewZoomFactor")
                    } else {
                        return 1.0 == defaults.double(forKey: "closeViewZoomFactor")
                    }
                }) {
                    success in
                    completion(success)
                }
            }
        }
        
    }
    
}

public class ScrollToZoomEnabledUIAutomation: ZoomCheckboxUIAutomation {
    
    override var checkboxTitle: String! { "Use scroll gesture with modifier keys to zoom:" }
    
}

public class HoverTextEnabledUIAutomation: ZoomCheckboxUIAutomation {
    
    override var checkboxTitle: String! { "Enable Hover Text" }
    
}

public class TouchbarZoomEnabledUIAutomation: ZoomCheckboxUIAutomation {
    
    override var checkboxTitle: String! { "Enable Touch Bar zoom" }
    
}

public class ZoomStyleUIAutomation: ZoomPopupButtonUIAutomation {
    
    override var buttonTitle: String! { "Zoom style:" }
    
    override var optionTitles: [Int : String]! {
        [
            0: "Full screen",
            1: "Picture-in-picture",
            2: "Split screen",
        ]
    }
}
