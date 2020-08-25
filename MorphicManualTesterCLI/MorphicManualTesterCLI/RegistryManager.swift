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

import MorphicCore
import MorphicSettings

public class RegistryManager
{
    public func load(registry: String) -> Bool
    {
        let filepath = URL(fileURLWithPath: registry)
        SettingsManager.shared.populateSolutions(from: filepath)
        return !SettingsManager.shared.solutions.isEmpty
    }
    public func list()
    {
        for solution in SettingsManager.shared.solutions
        {
            print("\(solution.identifier):")
            for setting in solution.settings
            {
                print("\t\(setting.name) [\(setting.type.rawValue)]")
            }
        }
    }
    public func listSolutions()
    {
        for solution in SettingsManager.shared.solutions
        {
            print(solution.identifier)
        }
    }
    public func listSpecific(solution: String)
    {
        for sol in SettingsManager.shared.solutions
        {
            if sol.identifier == solution
            {
                print("\(sol.identifier):")
                for setting in sol.settings
                {
                    print("\t\(setting.name) [\(setting.type.rawValue)]")
                }
                return
            }
        }
        print("[ERROR]: Solution not found. Please provide list command with a solution in the registry or no parameter to list all settings.")
    }
    public func info(solution: String, preference: String)
    {
        let setting = SettingsManager.shared.setting(for: Preferences.Key(solution: solution, preference: preference))
        print(setting.debugDescription)
    }
    public func get(solution: String? = nil)
    {
        let allSolutions = (solution == nil)
        for sol in SettingsManager.shared.solutions
        {
            if(allSolutions || solution == sol.identifier)
            {
                print("\(sol.identifier):")
                for setting in sol.settings
                {
                    print("\t\(setting.name): ", terminator:"")
                    get(solution: sol.identifier, preference: setting.name)
                }
            }
        }
    }
    public func get(solution: String, preference: String)
    {
        SettingsManager.shared.capture(valueFor: Preferences.Key(solution: solution, preference: preference))
        {
            value in
            if(value != nil)
            {
                if let sval = value as? String
                {
                    print("[string] value: \(sval)")
                }
                else if let bval = value as? Bool
                {
                    print("[bool] value: \(bval ? "true" : "false")")
                }
                else if let ival = value as? Int
                {
                    print("[int] value: \(String(ival))")
                }
                else if let dval = value as? Double
                {
                    print("[double] value: \(String(dval))")
                }
            }
        }
    }
    public func set(solution: String, preference: String, value: String)
    {
        let setting = SettingsManager.shared.setting(for: Preferences.Key(solution: solution, preference: preference))
        var data : Interoperable? = nil
        switch setting?.type
        {
        case .boolean:
            if(value.lowercased() == "true" || value.lowercased() == "1")
            {
                data = true
            }
            else if value.lowercased() == "false" || value.lowercased() == "0"
            {
                data = false
            }
            else
            {
                print("[ERROR]: value not a boolean")
                return
            }
            break
        case .double:
            if let dbl = Double(value)
            {
                data = dbl
            }
            else
            {
                print("[ERROR]: value not a double")
                return
            }
            break
        case .integer:
            if let int = Int(value)
            {
                data = int
            }
            else
            {
                print("[ERROR]: value not an integer")
                return
            }
            break
        case .string:
            data = value
            break
        case .none:
            print("[ERROR]: not a valid setting, check parameters")
            return
        }
        if data == nil
        {
            print("[ERROR]: unknown error processing value")
            return
        }
        SettingsManager.shared.apply(data, for: Preferences.Key(solution: solution, preference: preference))
        {
            success in
            if success
            {
                print("Value applied successfully!")
            }
            else
            {
                print("Value application failed")
            }
        }
    }
}
