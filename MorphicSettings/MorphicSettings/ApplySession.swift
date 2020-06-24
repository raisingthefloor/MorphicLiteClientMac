//
//  ApplySession.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/23/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore

/// Apply many settings in one session
///
/// Apply sessions can take advantage of `SettingFinalizer`s and only perform certain operations once
/// instead of once-per-setting.  This is useful for things like writing files or calling refresh functions
public class ApplySession{
    
    /// Create an apply session for the given settings manager and values
    ///
    /// The settings manager will be used to fetch `Setting` information
    ///
    /// - parameters:
    ///   - settingsManager: The settings manager to use when looking up `Setting`s
    ///   - valuesByKey: The values to apply in this session
    public required init(settingsManager: SettingsManager, valuesByKey: [Preferences.Key: Interoperable?]){
        self.settingsManager = settingsManager
        self.valuesByKey = valuesByKey
    }
    
    /// Create an apply session for the given settings manager and preferences
    ///
    /// Convenience method that extracts values from preferences
    public convenience init(settingsManager: SettingsManager, preferences: Preferences){
        self.init(settingsManager: settingsManager, valuesByKey: preferences.valuesByKey())
    }
    
    /// The values to apply for in session
    public var valuesByKey: [Preferences.Key: Interoperable?]
    
    /// The results for each individual setting
    ///
    /// - note: if a key doesn't have a result, you can assume it failed
    public private(set) var results = [Preferences.Key: Bool]()
    
    /// In addition to `valuesByKeys`, should the apply session also set default values for
    /// every other known setting?
    public var applyDefaultValues = true
       
    /// The settings manager to use to lookup `Setting` objects
    public private(set) var settingsManager: SettingsManager
    
    /// The remaining keys to apply
    private var keyQueue: [Preferences.Key]!
    
    /// The remaining finalizers to run
    private var finalizerQueue: [SettingFinalizerDescription]!
    
    /// Apply each setting and then call the completion handler
    ///
    /// - parameters:
    ///   - completion: Called when all the setting apply calls have completed
    public func run(completion: @escaping () -> Void){
        guard keyQueue == nil else{
            return
        }
        
        // populate valuesByKey with defaults if requested
        if (applyDefaultValues){
            for solution in settingsManager.solutions{
                for setting in solution.settings{
                    let key = Preferences.Key(solution: solution.identifier, preference: setting.name)
                    if valuesByKey[key] == nil{
                        if let defaultValue = setting.defaultValue{
                            valuesByKey[key] = defaultValue
                        }
                    }
                }
            }
        }
        
        // Figure out which unique finalizers need to run
        finalizerQueue = [SettingFinalizerDescription]()
        var seenFinalizers = Set<String>()
        let keys = valuesByKey.keys.reversed()
        for key in keys{
            guard let setting = settingsManager.setting(for: key) else{
                continue
            }
            if let description = setting.finalizerDescription{
                if !seenFinalizers.contains(description.uniqueRepresentation){
                    seenFinalizers.insert(description.uniqueRepresentation)
                    finalizerQueue.append(description)
                }
            }
        }
        
        // Start applying
        keyQueue = keys
        applyNextKey(completion: completion)
    }
    
    /// Apply a single setting
    private func applyNextKey(completion: @escaping () -> Void){
        guard keyQueue.count > 0 else{
            callNextFinalizer(completion: completion)
            return
        }
        let key = keyQueue.removeLast()
        guard let setting = settingsManager.setting(for: key) else{
            applyNextKey(completion: completion)
            return
        }
        guard let handler = setting.createHandler() else{
            applyNextKey(completion: completion)
            return
        }
        handler.apply(valuesByKey[key] ?? nil){
            success in
            self.results[key] = success
            self.applyNextKey(completion: completion)
        }
    }
    
    /// Call a single finalizer
    private func callNextFinalizer(completion: @escaping () -> Void){
        guard finalizerQueue.count > 0 else{
            keyQueue = nil
            finalizerQueue = nil
            completion()
            return
        }
        let description = finalizerQueue.removeLast()
        guard let finalizer = SettingFinalizer.create(from: description) else{
            callNextFinalizer(completion: completion)
            return
        }
        finalizer.run{
            success in
            self.callNextFinalizer(completion: completion)
        }
    }
    
}
