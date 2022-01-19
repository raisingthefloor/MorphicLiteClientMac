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

import ApplicationServices

public enum MorphicA11yAuthorizationError: Error {
    case notAuthorized
}

public struct MorphicA11yAuthorization {
    public static func authorizationStatus() -> Bool {
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
        
        // if we are not authorized (yet we just requested the pop-up to say we are not authorized), let our appdelegate know so we can show our a11y permissions helper overlay
        if response == false /* not authorized */ && promptIfNotAuthorized == true {
            NotificationCenter.default.post(name: .morphicPermissionsPopup, object: nil)
        }

	return response
    }
    
    public static func promptUserToGrantAuthorization() {
        _ = authorizationStatus(promptIfNotAuthorized: true)
    }
    
    // NOTE: in the future, we may want to consider watching for authorization state changes
    // NOTE: this code is just conceptual code; it would need to be thought through and vetted, and ideally the caller would also call DistributedNotificationCenter.default().removeObserver(...) once the watch was no longer desired
    // NOTE: the callback (which might also be better accomplished via a selector) would likely be called for permission changes in any application, so adding a filter for our current application (which would then call a function with a Boolean authorized/unauthorized value) would be useful.
    // NOTE: our code might need to wait a small delay after the callback is called, as the permissions state could potentially lag the callback by milliseconds (or even hundreds of milliseconds)
//    public static func watchForAuthorizationStatusChange(callback: @escaping (Bool) -> ()) {
//        let accessibilityApiNotificationName = NSNotification.Name("com.apple.accessibility.api")
//        DistributedNotificationCenter.default().addObserver(forName: accessibilityApiNotificationName, object: nil, queue: nil) { notification in
//            callback(/* true or false */)
//        }
//    }
}

public extension NSNotification.Name {
    static let morphicPermissionsPopup = NSNotification.Name("org.raisingthefloor.morphicPermissionsPopup")
}
