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
        
        // NOTE: these mask values are designed to match macOS's "HotKeyCombo" flags (e.g. SpokenUIUseSpeakingHotKeyCombo default)
        public static let withCommandKey = KeyOptions(rawValue: 1 << 8)
        public static let withShiftKey = KeyOptions(rawValue: 1 << 9)
        public static let withCapsLockKey = KeyOptions(rawValue: 1 << 10)
        public static let withAlternateKey = KeyOptions(rawValue: 1 << 11)
        public static let withControlKey = KeyOptions(rawValue: 1 << 12)
        
        public static let allValues: [KeyOptions] = [
            .withCommandKey,
            .withShiftKey,
            .withCapsLockKey,
            .withAlternateKey,
            .withControlKey
        ]
    }
    
    public static func parseDefaultsKeyCombo(_ value: Int) -> (keyCode: CGKeyCode, keyOptions: KeyOptions)? {
        guard var valueAsUInt32 = UInt32(exactly: value) else {
            return nil
        }

        // extract key code from the HotKeyCombo value
        // NOTE: while there are no known core key codes greater than 7 bits, we are using an 8-bit flag (0xFF) as Apple may have reserved the extra bit for future expansion (e.g. custom keys)
        let keyCode = CGKeyCode(CGKeyCode(valueAsUInt32 & 0xFF))
        valueAsUInt32 &= ~0xFF

        // create a mask of all key options (modifier keys) which we support
        var keyOptionsMaskAsUInt32: UInt32 = 0
        for keyOption in KeyOptions.allValues {
            keyOptionsMaskAsUInt32 |= keyOption.rawValue
        }
        //
        // extract options mask from the HotKeyCombo value
        let keyOptionsAsUInt32 = valueAsUInt32 & keyOptionsMaskAsUInt32
        let keyOptions = KeyOptions(rawValue: keyOptionsAsUInt32)
        valueAsUInt32 &= ~keyOptionsAsUInt32
        
        // verify that there is no remaining content in the HotKeyCombo value which we didn't understand (as we don't want to parse incorrectly)
        if valueAsUInt32 != 0 {
            // if we have any component remaining which we do not know how to support, return nil (failure) now
            return nil
        }

        return (keyCode: keyCode, keyOptions: keyOptions)
    }
    
    // MARK: - Keyboard virtualization functions
    
    public enum MorphicInputEventSource {
        case hidSystem
        case loginSession
    }
    
    // NOTE: since we are generating a keystore within the user session, we use the .loginSession inputSource (stateID of .combinedSessionState); if we experience any problems with the OS recognizing sent keys, we may want to try using .hidSystemState (which is designed for events posted from user-mode drivers which are interpreting hardware signals) instead.
    public static func sendKey(keyCode: CGKeyCode, keyOptions: KeyOptions, inputEventSource: MorphicInputEventSource? = .loginSession) -> Bool {
        return MorphicInput.internalSendKey(keyCode: keyCode, keyOptions: keyOptions, toProcessId: nil, inputEventSource: inputEventSource)
    }

    // NOTE: technically .hidSystem (.hidSystemState) is designed to emulate an HID hardware event; if we experience any problems sending keys to processes via .hdiSystemState, try using .combinedSessionState (which is designed for events posted from within a login session) instead
    // NOTE: a CGEventSource of "nil" seems to work just as well, but we're following established practices here; realistically it will probably work fine either way.
    public static func sendKey(keyCode: CGKeyCode, keyOptions: KeyOptions, toProcessId processId: Int, inputEventSource: MorphicInputEventSource? = .hidSystem) -> Bool {
        return MorphicInput.internalSendKey(keyCode: keyCode, keyOptions: keyOptions, toProcessId: processId, inputEventSource: inputEventSource)
    }

    // NOTE: we have no way to know if the key press was successful: sendKey is "fire and forget"
    // NOTE: technically inputEventSource can be nil, but we may want to remove that option in the future if it proves to be problematic
    private static func internalSendKey(keyCode: CGKeyCode, keyOptions: KeyOptions, toProcessId processId: Int?, inputEventSource: MorphicInputEventSource?) -> Bool {
        // NOTE: this implementation of sendKey sends the key to a process via CGEvents and using its processId; we might also consider using AppleScript in the future to send keystrokes to apps (potentially by name)
        
        // NOTE: events posted to the .combinedSessionState or .hidSystemState stateID are combined with other system signals, so we need to be aware that they could be "mixed" with a user's current keystrokes or other HID/session signals

        // for details about CGEventSource stateID, see: https://developer.apple.com/documentation/coregraphics/cgeventsourcestateid
        let eventSource: CGEventSource!
        switch inputEventSource {
        case .hidSystem:
            guard let eventSourceAsNonOptional = CGEventSource(stateID: .hidSystemState) else {
                NSLog("sendKey failure: Could not set event source to .hidSystemState")
                return false
            }
            eventSource = eventSourceAsNonOptional
        case .loginSession:
            guard let eventSourceAsNonOptional: CGEventSource = CGEventSource(stateID: .combinedSessionState) else {
                NSLog("sendKey failure: Could not set event source to .combinedSessionState")
                return false
            }
            eventSource = eventSourceAsNonOptional
        case nil:
            eventSource = nil
        }
        
        guard let keyDownEvent: CGEvent = MorphicInput.createKeyEvent(eventSource: eventSource, keyCode: keyCode, keyOptions: keyOptions, isKeyDown: true), let keyUpEvent: CGEvent = MorphicInput.createKeyEvent(eventSource: eventSource, keyCode: keyCode, keyOptions: keyOptions, isKeyDown: false) else {
            //
            NSLog("sendKey failure: Could not create keyUp/keyDown events")
            return false
        }
        // NOTE: Swift manages Core Foundation memory for us; in other languages, be sure to CFRelease
//        defer {
//            CFRelease(keyUpEvent)
//            CFRelease(keyDownEvent)
//        }
        
        if let processId = processId {
            // send the key to a specific process
            
            let processIdAsPid = pid_t(processId)

            // press the key
            keyDownEvent.postToPid(processIdAsPid)
            // then release the key
            keyUpEvent.postToPid(processIdAsPid)
        } else {
            // send the key to the system itself
            
            // press the key
            keyDownEvent.post(tap: CGEventTapLocation.cgSessionEventTap)
            // then release the key
            keyUpEvent.post(tap: CGEventTapLocation.cgSessionEventTap)
        }
        
        return true
    }

    private static func createKeyEvent(eventSource: CGEventSource, keyCode: CGKeyCode, keyOptions: KeyOptions, isKeyDown: Bool) -> CGEvent? {
        guard let keyEvent: CGEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: isKeyDown) else {
            return nil
        }

        var keyEventFlagsRawValue = keyEvent.flags.rawValue
        //
        // hold down command key (if applicable)
        if keyOptions.contains(.withCommandKey) {
            keyEventFlagsRawValue |= CGEventFlags.maskCommand.rawValue
        }
        //
        // hold down shift key (if applicable)
        if keyOptions.contains(.withShiftKey) {
            keyEventFlagsRawValue |= CGEventFlags.maskShift.rawValue
        }
        //
        // hold down caps lock key (if applicable)
        if keyOptions.contains(.withCapsLockKey) {
            keyEventFlagsRawValue |= CGEventFlags.maskAlphaShift.rawValue
        }
        //
        // hold down alternate/option key (if applicable)
        if keyOptions.contains(.withAlternateKey) {
           keyEventFlagsRawValue |= CGEventFlags.maskAlternate.rawValue
        }
        //
        // hold down control key (if applicable)
        if keyOptions.contains(.withControlKey) {
            keyEventFlagsRawValue |= CGEventFlags.maskControl.rawValue
        }
        //
        keyEvent.flags = CGEventFlags(rawValue: keyEventFlagsRawValue)

        return keyEvent
    }
}
