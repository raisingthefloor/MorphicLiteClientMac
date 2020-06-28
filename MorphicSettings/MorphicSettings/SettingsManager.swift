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
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "SettingsManager")

/// Manages system settings based on morphic preferences
public class SettingsManager{
    
    /// The singleton object representing this system's settings
    public static var shared: SettingsManager = SettingsManager()
    
    private init(){
        DefaultsReadUIWriteSettingHandler.register(automation: ContrastUIAutomation.self, for: .macosDisplayContrastEnabled)
        DefaultsReadUIWriteSettingHandler.register(automation: VoiceOverUIAutomation.self, for: .macosVoiceOverEnabled)
        DefaultsReadUIWriteSettingHandler.register(automation: ZoomUIAutomation.self, for: .macosZoomEnabled)
    }
    
    /// All known solutions
    public private(set) var solutions = [Solution]()
    
    /// The solutions registered in this manager
    private var solutionsById = [String: Solution]()
    
    /// Add solutions to the settings manager by parsing JSON
    public func populateSolutions(fromResource resource: String, in bundle: Bundle = Bundle.main){
        guard let url = bundle.url(forResource: resource, withExtension: "json") else{
            os_log(.error, log: logger, "Failed to find solutions json resource")
            return
        }
        populateSolutions(from: url)
    }
    
    public func populateSolutions(from url: URL){
        guard let data = FileManager.default.contents(atPath: url.path) else{
            os_log(.error, log: logger, "Failed to read contents of solutions json resource")
            return
        }
        populateSolutions(from: data)
    }
    
    public func populateSolutions(from data: Data){
        let decoder = JSONDecoder()
        guard let solutions = try? decoder.decode([Solution].self, from: data) else{
            os_log(.error, log: logger, "Failed to decode JSON from solutions file")
            return
        }
        self.solutions = solutions
        for solution in solutions{
            solutionsById[solution.identifier] = solution
        }
    }
    
    /// Get the setting for the given key
    ///
    /// - parameter key: The key to use when looking up the setting
    public func setting(for key: Preferences.Key) -> Setting?{
        guard let solution = solutionsById[key.solution] else{
            return nil
        }
        return solution.setting(for: key.preference)
    }
    
    /// Apply a value for Morphic preference in the given solution
    public func apply(_ value: Interoperable?, for key: Preferences.Key, completion: @escaping (_ success: Bool) -> Void){
        apply(values: [key: value]){
            results in
            completion(results[key] ?? false)
        }
    }
    
    /// Apply several values at once
    public func apply(values: [Preferences.Key: Interoperable?], completion: @escaping (_ results: [Preferences.Key: Bool]) -> Void){
        let session = ApplySession(settingsManager: self, valuesByKey: values)
        session.applyDefaultValues = false
        session.run{
            completion(session.results)
        }
    }
    
    /// Capture a value for the given preference
    public func capture(valueFor key: Preferences.Key, completion: @escaping (_ result: Interoperable?) -> Void){
        capture(valuesFor: [key]){
            results in
            completion(results[key] ?? nil)
        }
    }
    
    /// Capture many values at once
    public func capture(valuesFor keys: [Preferences.Key], completion: @escaping(_ results: [Preferences.Key: Interoperable?]) -> Void){
        let prefs = Preferences(identifier: "")
        let session = CaptureSession(settingsManager: self, preferences: prefs)
        session.captureDefaultValues = true
        session.keys = keys
        session.run{
            completion(session.preferences.valuesByKey())
        }
    }
    
}

public extension Preferences.Key{
    static var macosDisplayZoom = Preferences.Key(solution: "com.apple.macos.display", preference: "zoom")
    static var macosDisplayContrastEnabled = Preferences.Key(solution: "com.apple.macos.display", preference: "contrast.enabled")
    static var macosVoiceOverEnabled = Preferences.Key(solution: "com.apple.macos.voiceover", preference: "enabled")
    static var macosZoomEnabled = Preferences.Key(solution: "com.apple.macos.zoom", preference: "enabled")
}
