//
//  RegistryManager.swift
//  MorphicManualTester
//
//  Created by CatalinaTest on 7/20/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import SwiftUI

enum SettingType
{
    case boolean
    case string
    case integer
    case double
}

class SettingControl: ObservableObject, Identifiable
{
    @Published var name: String
    @Published var type: SettingType
    @Published var val_bool: Bool
    @Published var val_string: String
    @Published var val_int: Int
    @Published var val_double: Double
    var solutionName: String
    init(name: String, solname: String, type: SettingType)
    {
        self.name = name
        self.type = type
        self.solutionName = solname
        val_bool = false
        val_string = ""
        val_double = 0.0
        val_int = 0
    }
    func copy() -> SettingControl
    {
        let copy = SettingControl(name: name, solname: solutionName, type: type)
        return copy;
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
                
                
                
                
                
                
                let solution = SolutionCollection(solutionName: "morphic.solution.name")
                solution.settings.append(SettingControl(name: "FIRST SETTING", solname: "solution", type: SettingType.boolean))
                solution.settings.append(SettingControl(name: "SECOND SETTING", solname: "solution", type: SettingType.integer))
                solution.settings.append(SettingControl(name: "THIRD SETTING", solname: "solution", type: SettingType.double))
                solution.settings.append(SettingControl(name: "FOURTH SETTING", solname: "solution", type: SettingType.string))
                solutions.append(solution)
                
                load = "Loaded file " + solpath
            }
        }
    }
    func ApplyAllSettings()
    {
        
    }
    
    func ApplySetting(solutionName: String, settingName: String)
    {
        
    }
}
