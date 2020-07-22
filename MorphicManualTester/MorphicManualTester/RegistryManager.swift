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
                //TODO: apply setting
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
        if isStart
        {
            return
        }
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
            Apply()
        }
    }
    func Apply()
    {
        //TODO: apply settings
        Capture()
    }
    func Capture()
    {
        //TODO: capture settings
        switch(type)
        {
        case .string:
            displayVal = val_string
            break
        case .boolean:
            break
        case .integer:
            displayVal = String(format: "%i", val_int)
            break
        case .double:
            displayVal = String(format: "%f", val_double)
            break
        }
        changed = false
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
