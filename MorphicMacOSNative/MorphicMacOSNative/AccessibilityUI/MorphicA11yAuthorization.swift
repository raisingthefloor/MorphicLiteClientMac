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

import ApplicationServices

public enum MorphicA11yAuthorizationError: Error {
    case notAuthorized
}

public struct MorphicA11yAuthorization {
    // NOTE: this function does not prompt the computer's user if authorization status is not already approved
    public static func authorizationStatus() -> Bool {
        // NOTE: this function call also adds Morphic to the list of possible applications to authorize in the accessibility section
        return AXIsProcessTrusted()
    }

    public static func authorizationStatus(promptIfNotAuthorized: Bool) -> Bool {
        // NOTE: kAXTrustedCheckOptionPrompt is a global variable (CFStringRef), so we need to capture an unretained copy
        let axTrustedCheckOptionPromptAsCFString = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        
        let optionsAsNSDictionary: NSDictionary = [
            axTrustedCheckOptionPromptAsCFString: promptIfNotAuthorized
        ]
        let optionsAsCFDictionary = optionsAsNSDictionary as CFDictionary
        
        // NOTE: this function call also adds Morphic to the list of possible applications to authorize in the accessibility section
        let response = AXIsProcessTrustedWithOptions(optionsAsCFDictionary)
        
        return response
    }
    
    public static func promptUserToGrantAuthorization() {
        _ = authorizationStatus(promptIfNotAuthorized: true)
    }    
}
