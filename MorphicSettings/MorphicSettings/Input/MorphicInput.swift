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

import Foundation

// NOTE: the MorphicInput class contains the functionality used by Obj-C and Swift applications

public class MorphicInput {

    // MARK: - KeyOptions struct
    
    public struct KeyOptions: OptionSet {
        public typealias RawValue = UInt32
        public let rawValue: RawValue

        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        public static let withControlKey = KeyOptions(rawValue: 1 << 00)
        public static let withAlternateKey = KeyOptions(rawValue: 1 << 01)
        public static let withCommandKey = KeyOptions(rawValue: 1 << 02)
    }
    
    // MARK: - Keyboard virtualization functions
    
    // NOTE: we have no way to know if the key press was successful: sendKey is "fire and forget"
    public static func sendKey(keyCode: CGKeyCode, keyOptions: KeyOptions, toProcessId processId: Int) -> Bool {
        // NOTE: this implementation of sendKey sends the key to a process via CGEvents and using its processId; we might also consider using AppleScript in the future to send keystrokes to apps (potentially by name)
        
        // NOTE: a CGEventSource of "nil" seems to work just as well, but we're following established practices here; realistically it will probably work fine either way
        guard let eventSource = CGEventSource(stateID: .hidSystemState) else {
            NSLog("Could not set event source to .hidSystemState")
            return false
        }

        guard let keyDownEvent: CGEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: true),
            let keyUpEvent: CGEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: false) else {
            //
            NSLog("Could not create keyUp/keyDown events")
            return false
        }
        // NOTE: Swift manages Core Foundation memory for us; in other languages, be sure to CFRelease
//        defer {
//            CFRelease(keyUpEvent)
//            CFRelease(keyDownEvent)
//        }

        var keyDownEventFlagsRawValue = keyDownEvent.flags.rawValue
        var keyUpEventFlagsRawValue = keyUpEvent.flags.rawValue
        //
        // hold down control key (if applicable)
        if keyOptions.contains(.withControlKey) {
            keyDownEventFlagsRawValue |= CGEventFlags.maskControl.rawValue
            keyUpEventFlagsRawValue |= CGEventFlags.maskControl.rawValue
        }
        //
        // hold down alternate/option key (if applicable)
        if keyOptions.contains(.withAlternateKey) {
           keyDownEventFlagsRawValue |= CGEventFlags.maskAlternate.rawValue
           keyUpEventFlagsRawValue |= CGEventFlags.maskAlternate.rawValue
        }
        //
        // hold down command key (if applicable)
        if keyOptions.contains(.withCommandKey) {
            keyDownEventFlagsRawValue |= CGEventFlags.maskCommand.rawValue
            keyUpEventFlagsRawValue |= CGEventFlags.maskCommand.rawValue
        }
        //
        keyDownEvent.flags = CGEventFlags(rawValue: keyDownEventFlagsRawValue)
        keyUpEvent.flags = CGEventFlags(rawValue: keyUpEventFlagsRawValue)

        let processIdAsPid = pid_t(processId)

        // press the key
        keyDownEvent.postToPid(processIdAsPid)
        // then release the key
        keyUpEvent.postToPid(processIdAsPid)

        return true
    }
}
