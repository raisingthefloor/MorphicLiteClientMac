// Copyright 2020-2022 Raising the Floor - International
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
import AudioToolbox
//import CoreAudio

// NOTE: the MorphicAudio class contains the functionality used by Obj-C and Swift applications

public class MorphicAudio {
    // MARK: Custom errors
    public enum MorphicAudioError: Error {
        case propertyUnavailable
        case cannotSetProperty
        case coreAudioError(error: OSStatus)
    }

    // MARK: - Audio device enumeration
    
    // NOTE: this function returns nil if it encounters an error; we do this to distinguish an error condition ( nil ) from an empty set ( [] ).
    // Apple docs: https://developer.apple.com/library/archive/technotes/tn2223/_index.html
    public static func getDefaultAudioDeviceId() -> UInt32? {
        var outputDeviceId: AudioDeviceID = 0
        var sizeOfAudioDeviceID = UInt32(MemoryLayout<AudioDeviceID>.size)

        // option 1: kAudioHardwarePropertyDefaultOutputDevice
        var outputDevicePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
//        // option 2: kAudioHardwarePropertyDefaultSystemOutputDevice
//        var outputDevicePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultSystemOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)

        let getPropertyError = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &outputDevicePropertyAddress, 0, nil, &sizeOfAudioDeviceID, &outputDeviceId)
        if getPropertyError != noErr {
            // if we cannot retrieve the default output device's id, return nil
            return nil
        }
        
        return outputDeviceId as UInt32
    }
    
    // MARK: - Get/set volume (and mute state)
    
    public static func getVolume(for audioDeviceId: UInt32) -> Float? {
        var volume: Float = 0
        var sizeOfFloat = UInt32(MemoryLayout<Float>.size)

        var volumePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)

        // verify that the output device has a volume property to get
        if AudioObjectHasProperty(AudioObjectID(audioDeviceId), &volumePropertyAddress) == false {
            // if there is no volume property to get, return nil
            return nil
        }
        
        let getPropertyError = AudioObjectGetPropertyData(AudioObjectID(audioDeviceId), &volumePropertyAddress, 0, nil, &sizeOfFloat, &volume)
        if getPropertyError != noErr {
            // if we cannot retrieve the volume, return nil
            return nil
        }
        
        // sanity-check: force the volume into the range 0.0 through 1.0
        if volume < 0.0 {
            volume = 0.0
        } else if volume > 1.0 {
            volume = 1.0
        }
        
        return volume
    }
    
    public static func setVolume(for audioDeviceId: UInt32, volume: Float) throws {
        var newVolume = volume
        let sizeOfFloat = UInt32(MemoryLayout<Float>.size)
        
        var volumePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)

        // verify that the output device has a volume property
        if AudioObjectHasProperty(AudioObjectID(audioDeviceId), &volumePropertyAddress) == false {
            // if there is no volume property, throw an error
            throw MorphicAudioError.propertyUnavailable
        }
        
        // verify that we can set the volume property
        var canSetVolume: DarwinBoolean = true
        let checkSettableError = AudioObjectIsPropertySettable(AudioObjectID(audioDeviceId), &volumePropertyAddress, &canSetVolume)
        if checkSettableError != noErr {
            // if we cannot determine if volume is settable, throw an error
            throw MorphicAudioError.coreAudioError(error: checkSettableError)
        }
        
        if canSetVolume == false {
            // if we cannot set the volume, throw an error
            throw MorphicAudioError.cannotSetProperty
        }
        
        let setPropertyError = AudioObjectSetPropertyData(audioDeviceId, &volumePropertyAddress, 0, nil, sizeOfFloat, &newVolume)
        //
        if setPropertyError != noErr {
            // if we cannot set the volume, throw an error
            throw MorphicAudioError.coreAudioError(error: setPropertyError)
        }
    }
    
    public static func enableVolumeChangeNotifications(for audioDeviceId: UInt32) throws {
        var volumePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)

        // verify that the output device has a volume property to watch
        if AudioObjectHasProperty(AudioObjectID(audioDeviceId), &volumePropertyAddress) == false {
            // if there is no volume property, throw an error
            throw MorphicAudioError.propertyUnavailable
        }

        let addPropertyListenerError = AudioObjectAddPropertyListener(AudioObjectID(audioDeviceId), &volumePropertyAddress, {
            (audioDeviceId: AudioObjectID, arg1: UInt32, _: UnsafePointer<AudioObjectPropertyAddress>, _: UnsafeMutableRawPointer?) -> OSStatus in
            if let volume = MorphicAudio.getVolume(for: audioDeviceId) {
                NotificationCenter.default.post(name: .morphicAudioVolumeChanged, object: nil, userInfo: ["volume" : volume])
            }
            return noErr
        }, nil)
        if addPropertyListenerError != noErr {
            // if we cannot subscribe to volume property changes, throw an error
            throw MorphicAudioError.coreAudioError(error: addPropertyListenerError)
        }
    }
    
    public static func getMuteState(for audioDeviceId: UInt32) -> Bool? {
        var muteState: UInt32 = 0
        var sizeOfUInt32 = UInt32(MemoryLayout<UInt32>.size)
        
        var mutePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)
        
        // verify that the output device has a mute state to get
        if AudioObjectHasProperty(AudioObjectID(audioDeviceId), &mutePropertyAddress) == false {
            // if there is no mute state to get, return nil
            return nil
        }
        
        let getPropertyError = AudioObjectGetPropertyData(AudioObjectID(audioDeviceId), &mutePropertyAddress, 0, nil, &sizeOfUInt32, &muteState)
        if getPropertyError != noErr {
            // if we cannot retrieve the mute state, return nil
            return nil
        }
        
        return (muteState != 0) ? true : false
    }
    
    // NOTE: to mute, set value to true; to unmute, set value to false.
    public static func setMuteState(for audioDeviceId: UInt32, muteState: Bool) throws {
        var newValue = muteState ? UInt32(1) : UInt32(0)
        let sizeOfUInt32 = UInt32(MemoryLayout<UInt32>.size)
        
        var mutePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)
        
        // verify that the output device has a mute property
        if AudioObjectHasProperty(AudioObjectID(audioDeviceId), &mutePropertyAddress) == false {
            // if there is no mute state property, throw an error
            throw MorphicAudioError.propertyUnavailable
        }
        
        // verify that we can set the mute property
        var canMute: DarwinBoolean = true
        let checkSettableError = AudioObjectIsPropertySettable(AudioObjectID(audioDeviceId), &mutePropertyAddress, &canMute)
        if checkSettableError != noErr {
            // if we cannot determine if mute is settable, throw an error
            throw MorphicAudioError.coreAudioError(error: checkSettableError)
        }
        
        if canMute == false {
            // if we cannot mute/unmute the audio output device, throw an error
            throw MorphicAudioError.cannotSetProperty
        }
        
        let setPropertyError = AudioObjectSetPropertyData(audioDeviceId, &mutePropertyAddress, 0, nil, sizeOfUInt32, &newValue)
        //
        if setPropertyError != noErr {
            // if we cannot set the mute state, throw an error
            throw MorphicAudioError.coreAudioError(error: setPropertyError)
        }
    }

    private static var enableMuteStateChangeNotifications_Enabled: Bool = false
    public static func enableMuteStateChangeNotifications(for audioDeviceId: UInt32) throws {
        if MorphicAudio.enableMuteStateChangeNotifications_Enabled == true {
            return
        }
        
        var mutePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)

        // verify that the output device has a mute state to watch
        if AudioObjectHasProperty(AudioObjectID(audioDeviceId), &mutePropertyAddress) == false {
            // if there is no mute state property, throw an error
            throw MorphicAudioError.propertyUnavailable
        }

        let addPropertyListenerError = AudioObjectAddPropertyListener(AudioObjectID(audioDeviceId), &mutePropertyAddress, {
            (audioDeviceId: AudioObjectID, arg1: UInt32, _: UnsafePointer<AudioObjectPropertyAddress>, _: UnsafeMutableRawPointer?) -> OSStatus in
            if let muteState = MorphicAudio.getMuteState(for: audioDeviceId) {
                NotificationCenter.default.post(name: .morphicAudioMuteStateChanged, object: nil, userInfo: ["muteState" : muteState])
            }
            return noErr
        }, nil)
        if addPropertyListenerError != noErr {
            // if we cannot subscribe to mute state changes, throw an error
            throw MorphicAudioError.coreAudioError(error: addPropertyListenerError)
        }
        
        MorphicAudio.enableMuteStateChangeNotifications_Enabled = true
    }
}

public extension NSNotification.Name {
    static let morphicAudioVolumeChanged = NSNotification.Name("org.raisingthefloor.morphicAudioVolumeChanged")
    static let morphicAudioMuteStateChanged = NSNotification.Name("org.raisingthefloor.morphicAudioMuteStateChanged")
}
