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
        // hold down control key (if applicable)
        if keyOptions.contains(.withControlKey) {
            keyEventFlagsRawValue |= CGEventFlags.maskControl.rawValue
        }
        //
        // hold down alternate/option key (if applicable)
        if keyOptions.contains(.withAlternateKey) {
           keyEventFlagsRawValue |= CGEventFlags.maskAlternate.rawValue
        }
        //
        // hold down command key (if applicable)
        if keyOptions.contains(.withCommandKey) {
            keyEventFlagsRawValue |= CGEventFlags.maskCommand.rawValue
        }
        //
        keyEvent.flags = CGEventFlags(rawValue: keyEventFlagsRawValue)

        return keyEvent
    }
}
