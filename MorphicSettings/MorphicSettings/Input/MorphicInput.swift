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

import Cocoa
import MorphicCore
import MorphicMacOSNative

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
    
    // NOTE: a list of probably constants was found at: https://stackoverflow.com/questions/866056/how-do-i-programmatically-get-the-shortcut-keys-reserved-by-mac-os-x
    public enum SystemHotKeyId: Int {
        case savePictureOfSelectedAreaAsAFile = 30 // kSHKSavePictureOfSelectedAreaAsAFile
        case copyPictureOfSelectedAreaToTheClipboard = 31 // kSHKCopyPictureOfSelectedAreaToTheClipboard
    }
    
    public static func hotKeyForSystemKeyboardShortcut(_ systemHotKeyId: SystemHotKeyId) -> (keyCode: CGKeyCode, keyOptions: MorphicInput.KeyOptions, enabled: Bool)? {
        guard let symbolicHotKeyDefaults = UserDefaults(suiteName: "com.apple.symbolichotkeys") else {
            NSLog("Could not access defaults domain: \"com.apple.symbolichotkeys\"")
            return nil
        }
        
        // locate the target hot key by id
        guard let appleSymbolicHotKeys = symbolicHotKeyDefaults.value(forKey: "AppleSymbolicHotKeys") as? [String: Any] else {
            return nil
        }
        guard let hotKey = appleSymbolicHotKeys[String(systemHotKeyId.rawValue)] as? [String: Any] else {
            return nil
        }

        // get whether or not the hot key is currently enabled
        guard let hotKeyEnabledAsInt = hotKey["enabled"] as? Int else {
            return nil
        }
        let hotKeyEnabled = hotKeyEnabledAsInt != 0 ? true : false
        
        guard let hotKeyValue = hotKey["value"] as? [String: Any] else {
            return nil
        }

        // make sure the hot key is a "standard" hot key (i.e. not a mouse shortcut, etc.)
        guard let hotKeyType = hotKeyValue["type"] as? String else {
            return nil
        }
        guard hotKeyType.lowercased() == "standard" else {
            return nil
        }

        // get the keycode and modifier keys used for this hot key
        guard let hotKeyParameters = hotKeyValue["parameters"] as? [Any] else {
            return nil
        }
        guard hotKeyParameters.count >= 3 else {
            return nil
        }
//        // NOTE: hotKeyAsciiCode may be Int16.max (if the character isn't an ASCII character)
//        guard let hotKeyAsciiCode: Int = hotKeyParameters[0] as? Int else {
//            return nil
//        }
        guard let hotKeyKeyCode: Int = hotKeyParameters[1] as? Int else {
            return nil
        }
        guard let hotKeyModifiers: Int = hotKeyParameters[2] as? Int else {
            return nil
        }

        // NOTE: this modifier key mapping is specific to the (legacy, from the macOS 'Carbon' days) key mappings
        // NOTE: these should be the same values we could get via CopySymbolicHotKeys (but of course here we can retrieve which key combo goes with which system feature)
        var keyOptionsAsUInt32: UInt32 = 0
        if (hotKeyModifiers & (1 << 17)) != 0 {
            keyOptionsAsUInt32 |= MorphicInput.KeyOptions.withShiftKey.rawValue
        }
        if (hotKeyModifiers & (1 << 18)) != 0 {
            keyOptionsAsUInt32 |= MorphicInput.KeyOptions.withControlKey.rawValue
        }
        if (hotKeyModifiers & (1 << 19)) != 0 {
            keyOptionsAsUInt32 |= MorphicInput.KeyOptions.withAlternateKey.rawValue
        }
        if (hotKeyModifiers & (1 << 20)) != 0 {
            keyOptionsAsUInt32 |= MorphicInput.KeyOptions.withCommandKey.rawValue
        }
        let keyOptions = MorphicInput.KeyOptions(rawValue: keyOptionsAsUInt32)

        return (keyCode: CGKeyCode(hotKeyKeyCode), keyOptions: keyOptions, enabled: hotKeyEnabled)
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
    public static func sendKey(keyCode: CGKeyCode, keyOptions: KeyOptions, inputEventSource: MorphicInputEventSource? = .loginSession) throws {
        try MorphicInput.internalSendKey(keyCode: keyCode, keyOptions: keyOptions, toProcessId: nil, inputEventSource: inputEventSource)
    }

    // NOTE: technically .hidSystem (.hidSystemState) is designed to emulate an HID hardware event; if we experience any problems sending keys to processes via .hdiSystemState, try using .combinedSessionState (which is designed for events posted from within a login session) instead
    // NOTE: a CGEventSource of "nil" seems to work just as well, but we're following established practices here; realistically it will probably work fine either way.
    public static func sendKey(keyCode: CGKeyCode, keyOptions: KeyOptions, toProcessId processId: Int, inputEventSource: MorphicInputEventSource? = .hidSystem) throws {
        try MorphicInput.internalSendKey(keyCode: keyCode, keyOptions: keyOptions, toProcessId: processId, inputEventSource: inputEventSource)
    }

    // NOTE: we have no way to know if the key press was successful: sendKey is "fire and forget"
    // NOTE: technically inputEventSource can be nil, but we may want to remove that option in the future if it proves to be problematic
    private static func internalSendKey(keyCode: CGKeyCode, keyOptions: KeyOptions, toProcessId processId: Int?, inputEventSource: MorphicInputEventSource?) throws {
        // NOTE: this implementation of sendKey sends the key to a process via CGEvents and using its processId; we might also consider using AppleScript in the future to send keystrokes to apps (potentially by name)
        
        // NOTE: events posted to the .combinedSessionState or .hidSystemState stateID are combined with other system signals, so we need to be aware that they could be "mixed" with a user's current keystrokes or other HID/session signals

        // for details about CGEventSource stateID, see: https://developer.apple.com/documentation/coregraphics/cgeventsourcestateid
        let eventSource: CGEventSource!
        switch inputEventSource {
        case .hidSystem:
            guard let eventSourceAsNonOptional = CGEventSource(stateID: .hidSystemState) else {
                NSLog("sendKey failure: Could not set event source to .hidSystemState")
                throw MorphicError.unspecified
            }
            eventSource = eventSourceAsNonOptional
        case .loginSession:
            guard let eventSourceAsNonOptional: CGEventSource = CGEventSource(stateID: .combinedSessionState) else {
                NSLog("sendKey failure: Could not set event source to .combinedSessionState")
                throw MorphicError.unspecified
            }
            eventSource = eventSourceAsNonOptional
        case nil:
            eventSource = nil
        }
        
        guard let keyDownEvent: CGEvent = MorphicInput.createKeyEvent(eventSource: eventSource, keyCode: keyCode, keyOptions: keyOptions, isKeyDown: true),
            let keyUpEvent: CGEvent = MorphicInput.createKeyEvent(eventSource: eventSource, keyCode: keyCode, keyOptions: keyOptions, isKeyDown: false) else {
            //
            NSLog("sendKey failure: Could not create keyUp/keyDown events")
            throw MorphicError.unspecified
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
            
	    // NOTE: CGEventTapLocation.cghidEventTap might be a reasonable alternative CGEventTapLocation (for some or all keyboard events)
            // press the key
            keyDownEvent.post(tap: CGEventTapLocation.cgSessionEventTap)
            // then release the key
            keyUpEvent.post(tap: CGEventTapLocation.cgSessionEventTap)
        }
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
    
    // MARK: - key repeat settings
    
    // NOTE: NSOpenEventStatus, NXCloseEventStatus, NXKeyRepeatThreshold and NXKeyRepeatInterval were officially deprecated in macOS 10.12, but they are still the way that macOS adjusts the key repeat intervals inside System Preferences so we continue to use them.
    // NOTE: behind the scenes, the NXKeyRepeat functions (in IOKit) appear to use IOHIDSetParameter and IOHIDGetParameter; if the higher-level NX functions are ever removed then we can consider moving to the IOHID functions directly instead
    
    // NOTE: if key repeat's threshold is set to 5000 seconds, this is macOS's signal that key repeat is (effectively) turned off
    private static let keyRepeatOffThreshold: Double = 5000.0
    
    private static let defaultKeyRepeatInterval: Double = 6.0 / 60.0 // NOTE: as observed in a clean install of macOS 10.15.7
    public static let slowestKeyRepeatInterval: Double = 2.0
    
    private static let defaultKeyRepeatThreshold: Double = 68.0 / 60.0 // NOTE: as observed in a clean install of macOS 10.15.7
    
    public static var keyRepeatIsEnabled: Bool {
        return (MorphicInput.initialDelayUntilKeyRepeat != nil)
    }
    
    public static func setKeyRepeatIsEnabled(_ value: Bool) {
        // capture the current repeat threshold
        let currentInitialDelayUntilKeyRepeat = MorphicInput.initialDelayUntilKeyRepeat

        if value == true {
            // turn on key repeat
            
            // if the current repeat threshold is the "off" constant, then capture the saved repeat threshold from global defaults (so we can restore it)
            let initialKeyRepeatSavedLevelAsOptional = MorphicInput.savedInitialDelayUntilKeyRepeat
            // NOTE: if we could not retrieve a saved "initial key repeat" value, then use a default value instead
            let initialKeyRepeatSavedLevel = initialKeyRepeatSavedLevelAsOptional ?? MorphicInput.defaultKeyRepeatThreshold
            
            if currentInitialDelayUntilKeyRepeat == nil {
                // restore the saved repeat threshold
                MorphicInput.setInitialDelayUntilKeyRepeat(initialKeyRepeatSavedLevel)
            }
        } else {
            // turn off key repeat
            
            // if the current repeat threshold is not the "off" constant, then save it in defaults (so it can be restored)
            if let currentInitialDelayUntilKeyRepeat = currentInitialDelayUntilKeyRepeat {
                // save the existing threshold to global defaults
                MorphicInput.setSavedInitialDelayUntilKeyRepeat(currentInitialDelayUntilKeyRepeat)
                
                // turn off key repeat (by "disabling" the initial key repeat)
                MorphicInput.setInitialDelayUntilKeyRepeat(nil)
            }
        }
    }
    
    // NOTE: this function is used to determine if "key repeat" is broken in this release of macOS
    public static var isTurnOffKeyRepeatBroken: Bool {
        get {
            let operatingSystemVersion = MorphicProcess.operatingSystemVersion
            // TODO: if key repeat is broken in versions of macOS Catalina before/after 10.15.7, update this logic; the observation that this feature was broken in Catalina was made in macOS Catalina 10.15.7 specifically
            if operatingSystemVersion.majorVersion == 10 && operatingSystemVersion.minorVersion == 15 && operatingSystemVersion.patchVersion >= 7 {
                return true
            }
            
            // otherwise, return false
            return false
        }
    }
    
    // NOTE: if key repeat is turned off, this will return nil
    public static var initialDelayUntilKeyRepeat: Double? {
        get {
            let eventStatus = NXOpenEventStatus()
            defer {
                NXCloseEventStatus(eventStatus)
            }
            
            let resultAsDouble = NXKeyRepeatThreshold(eventStatus)
            if resultAsDouble == MorphicInput.keyRepeatOffThreshold {
                return nil
            } else {
                return resultAsDouble
            }
        }
    }
    
    // NOTE: to turn key repeat off, set this value to nil
    public static func setInitialDelayUntilKeyRepeat(_ value: Double?) {
        let eventStatus = NXOpenEventStatus()
        defer {
            NXCloseEventStatus(eventStatus)
        }

        let newKeyRepeatThreshold = value ?? MorphicInput.keyRepeatOffThreshold
        NXSetKeyRepeatThreshold(eventStatus, newKeyRepeatThreshold)
    }
    
    private static var savedInitialDelayUntilKeyRepeat: Double? {
        guard let rawValue = CFPreferencesCopyValue("InitialKeyRepeat_Level_Saved" as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? Double else {
            return nil
        }

        // NOTE: the value stored in defaults is multiplied by 60 (for an unknown reason)
        return rawValue / 60
    }
    
    private static func setSavedInitialDelayUntilKeyRepeat(_ value: Double) {
        // NOTE: the value stored in defaults is multiplied by 60 (for an unknown reason)
        let rawValue = round(value * 60)
        
        // NOTE: this function sets the property in the global domain (AnyApplication), but only for the current user
        CFPreferencesSetValue("InitialKeyRepeat_Level_Saved" as CFString, rawValue as CFNumber, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        let success = CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        if success == false {
            NSLog("Could not save initial key repeat delay to global defaults")
            assertionFailure("Could not save initial key repeat delay to global defaults")
        }
    }

    public static var keyRepeatInterval: Double {
        get {
            let eventStatus = NXOpenEventStatus()
            defer {
                NXCloseEventStatus(eventStatus)
            }
            
            return NXKeyRepeatInterval(eventStatus)
        }
    }
    
    public static func setKeyRepeatInterval(_ value: Double) {
        let eventStatus = NXOpenEventStatus()
        defer {
            NXCloseEventStatus(eventStatus)
        }

        NXSetKeyRepeatInterval(eventStatus, value)
    }
}
