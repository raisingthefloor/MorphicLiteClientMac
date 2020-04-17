//
//  Audio.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 4/17/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "Audio")

public class AudioOutput{
    
    init(id: UInt32){
        self.id = id
    }
    
    private var id: UInt32
    
    public static var main: AudioOutput? = {
        if let id = MorphicAudio.getDefaultAudioDeviceId(){
            return AudioOutput(id: id)
        }
        return nil
    }()
    
    public var isMuted: Bool{
        get{
            if let muted = MorphicAudio.getMuteState(for: id){
                return muted
            }
            os_log(.error, log: logger, "Failed to get mute state, assuming false")
            return false
        }
    }
    
    public func setMuted(_ muted: Bool) -> Bool{
        do{
            try MorphicAudio.setMuteState(for: id, muteState: muted)
            return true
        }catch{
            os_log(.error, log: logger, "Exception while setting mute state: %{public}s", error.localizedDescription)
            return false
        }
    }
    
    public var volume: Double{
        get{
            if let value = MorphicAudio.getVolume(for: id){
                return Double(value)
            }
            os_log(.error, log: logger, "Failed to get volume, assuming 0.0")
            return 0.0
        }
    }
    
    public func setVolume(_ value: Double) -> Bool{
        do{
            try MorphicAudio.setVolume(for: id, volume: Float(value))
            return true
        }catch{
            os_log(.error, log: logger, "Exception while setting volume: %{public}s", error.localizedDescription)
            return false
        }
    }
    
}

public class AudioVolumeHandler: Handler{
    
    public override func apply(_ value: Interoperable?) throws {
        guard let percentage = value as? Double else{
            throw ApplyError.incorrectValueType
        }
        if !(AudioOutput.main?.setVolume(percentage) ?? false){
            throw ApplyError.failed
        }
    }
    
}

public class AudioMuteHandler: Handler{
    
    public override func apply(_ value: Interoperable?) throws {
        guard let muted = value as? Bool else{
            throw ApplyError.incorrectValueType
        }
        if !(AudioOutput.main?.setMuted(muted) ?? false){
            throw ApplyError.failed
        }
    }
    
}
