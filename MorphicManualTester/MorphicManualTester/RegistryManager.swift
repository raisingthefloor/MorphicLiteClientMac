//
//  RegistryManager.swift
//  MorphicManualTester
//
//  Created by CatalinaTest on 7/20/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore
import MorphicSettings
import SwiftUI

let registry = RegistryManager()

class SettingControl: ObservableObject, Identifiable
{
    @Published var name: String
    @Published var type: Setting.ValueType
    @Published var changed: Bool
    @Published var val_bool: Bool
        {
        didSet
        {
            changed = true
            if(registry.autoApply)
            {
                Apply()
            }
        }
    }
    @Published var displayVal: String
    var val_string: String
    var val_int: Int
    var val_double: Double
    var solutionName: String
    init(name: String, solname: String, type: Setting.ValueType, val_string: String = "", val_bool: Bool = false, val_double: Double = 0.0, val_int: Int = 0)
    {
        self.name = name
        self.type = type
        self.changed = false
        self.solutionName = solname
        self.val_bool = val_bool
        self.val_double = val_double
        self.val_string = val_string
        self.val_int = val_int
        self.displayVal = ""
    }
    func copy() -> SettingControl
    {
        let copy = SettingControl(name: name, solname: solutionName, type: type)
        copy.val_bool = val_bool
        copy.val_int = val_int
        copy.val_string = val_string
        copy.val_double = val_double
        return copy;
    }
    func CheckVal(isStart: Bool)
    {
        changed = true
        if isStart {return}
        switch(type)
        {
        case .string:
            val_string = displayVal
            break
        case .integer:
            let ival: Int? = Int(displayVal)
            if ival == nil
            {
                Capture()
                return
            }
            val_int = ival!
            break
        case .double:
            let dval: Double? = Double(displayVal)
            if dval == nil
            {
                Capture()
                return
            }
            val_double = dval!
            break
        case .boolean:
            return
        }
        if(registry.autoApply)
        {
            Apply(alreadyChecked: true)
        }
    }
    func Apply(alreadyChecked: Bool = false)
    {
        if !changed
        {
            return
        }
        if !alreadyChecked
        {
            CheckVal(isStart: false)
        }
        var val: Interoperable?
        switch(type)
        {
        case .string:
            val = val_string
            break
        case .integer:
            val = val_int
            break
        case .double:
            val = val_double
            break
        case .boolean:
            val = val_bool
            break
        }
        let sname = String(name)
        SettingsManager.shared.apply(val, for: Preferences.Key(solution: solutionName, preference: sname))
        { success in
            if(!success)
            {
            self.Capture()
            }
        }
    }
    func Capture()
    {
        let sname = String(name)
        SettingsManager.shared.capture(valueFor: Preferences.Key(solution: solutionName, preference: sname))
        { value in
            switch(self.type)
            {
            case .string:
                let v_string: String? = value as? String
                if v_string == nil {return}
                self.val_string = v_string!
                self.displayVal = self.val_string
                break
            case .boolean:
                let v_bool: Bool? = value as? Bool
                if v_bool == nil {return}
                self.val_bool = v_bool!
                break
            case .integer:
                let v_int: Int? = value as? Int
                if v_int == nil {return}
                self.val_int = v_int!
                self.displayVal = String(format: "%i", self.val_int)
                break
            case .double:
                let v_double: Double? = value as? Double
                if v_double == nil {return}
                self.val_double = v_double!
                self.displayVal = String(format: "%f", self.val_double)
                break
            }
            self.changed = false
        }
    }
}

class SolutionCollection: ObservableObject, Identifiable
{
    @Published var name: String
    @Published var settings: [SettingControl]
    init(solutionName: String)
    {
        self.name = solutionName
        self.settings = [SettingControl]()
    }
    func copy() -> SolutionCollection
    {
        let copy = SolutionCollection(solutionName: name)
        for setting in settings
        {
            copy.settings.append(setting.copy())
        }
        return copy;
    }
}

class RegistryManager: ObservableObject
{
    @Published var solutions: [SolutionCollection]
    @Published var load: String
    @Published var autoApply: Bool
    init()
    {
        load = "NO REGISTRY LOADED"
        autoApply = false
        solutions = [SolutionCollection]()
    }
    func LoadSolution()
    {
        let filedialog = NSOpenPanel()
        filedialog.title = "Open Solution File"
        filedialog.showsResizeIndicator = true
        filedialog.showsHiddenFiles = false
        filedialog.allowsMultipleSelection = false
        filedialog.canChooseDirectories = false
        if(filedialog.runModal() == NSApplication.ModalResponse.OK)
        {
            let solurl = filedialog.url
            if(solurl != nil)
            {
                let solpath: String = solurl!.path
                SettingsManager.shared.populateSolutions(from: solurl!)
                if(SettingsManager.shared.solutions.isEmpty)
                {
                    load = "ERROR, INVALID SOLUTION FILE. PLEASE TRY AGAIN."
                    return
                }
                for solution in SettingsManager.shared.solutions
                {
                    let collection = SolutionCollection(solutionName: solution.identifier)
                    for setting in solution.settings
                    {
                        collection.settings.append(SettingControl(name: setting.name, solname: solution.identifier, type: setting.type))
                    }
                    solutions.append(collection)
                }
                CaptureAllSettings()
                load = "Loaded file " + solpath
            }
        }
    }
    func ApplyAllSettings()
    {
        for solution in self.solutions
        {
            for setting in solution.settings
            {
                if setting.changed
                {
                    setting.Apply()
                }
            }
        }
    }
    func CaptureAllSettings()
    {
        for solution in self.solutions
        {
            for setting in solution.settings
            {
                setting.Capture()
            }
        }
    }
}
