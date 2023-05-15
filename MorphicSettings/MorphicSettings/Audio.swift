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

import Foundation
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "Audio")

public class AudioOutput {
    
    init(id: UInt32) {
        self.id = id
    }
    
    private var id: UInt32
    
    public static var main: AudioOutput? = {
        if let id = MorphicAudio.getDefaultAudioDeviceId() {
            return AudioOutput(id: id)
        }
        return nil
    }()
    
    public var isMuted: Bool{
        get {
            if let muted = MorphicAudio.getMuteState(for: id) {
                return muted
            }
            os_log(.error, log: logger, "Failed to get mute state, assuming false")
            return false
        }
    }
    
    public func setMuted(_ muted: Bool) throws {
        do {
            try MorphicAudio.setMuteState(for: id, muteState: muted)
        } catch {
            os_log(.error, log: logger, "Exception while setting mute state: %{public}s", error.localizedDescription)
            throw MorphicError.unspecified
        }
    }
    
    public var volume: Double {
        get {
            if let value = MorphicAudio.getVolume(for: id) {
                return Double(value)
            }
            os_log(.error, log: logger, "Failed to get volume, assuming 0.0")
            return 0.0
        }
    }
    
    public func setVolume(_ value: Double) throws {
        do {
            try MorphicAudio.setVolume(for: id, volume: Float(value))
        } catch {
            os_log(.error, log: logger, "Exception while setting volume: %{public}s", error.localizedDescription)
            throw MorphicError.unspecified
        }
    }
    
}
