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

public class MorphicWord {
    public init() {
        path = (NSSearchPathForDirectoriesInDomains(.allLibrariesDirectory, .userDomainMask, true).first ?? "") + "/Containers/com.microsoft.Word/Data/Library/Preferences/Word.officeUI"
        backupPath = path + ".bak"
        _filemanager = FileManager()
        originalString = ""
        currentSettings = XMLDocument()
        CapturePrefs(original: true)
        
    }
    
    public func CapturePrefs(original: Bool = false) {
        var capture: String = ""
        do {
            if _filemanager.fileExists(atPath: path) {
                try capture = String(contentsOfFile: path, encoding: .utf8)
                if capture == "" {
                    throw NSError()
                }
            } else {
                if !_filemanager.fileExists(atPath: backupPath) {
                    try "".write(toFile: backupPath, atomically: false, encoding: .utf8)    //writes an empty backup file to stop the backup on the write phase
                }
                currentSettings = LoadEmptyTemplate()
                return
            }
            if original {   //takes the captured string down as a secondary backup
                originalString = capture
            }
            currentSettings = try XMLDocument(xmlString: capture, options: .nodePreserveNamespaceOrder)
            let tabs: XMLElement? = currentSettings.rootElement()?.elements(forName: "mso:ribbon").first?.elements(forName: "mso:tabs").first
            if tabs == nil {    //anything missing the tabs element will break all functionality
                throw NSError()
            }
        } catch {   //responds to any error by just going forward with no customizations and backing up whatever is currently there
            currentSettings = LoadEmptyTemplate()
            do {
                if _filemanager.fileExists(atPath: backupPath) {
                    try _filemanager.copyItem(atPath: path, toPath: backupPath)
                }
            } catch {}
        }
    }
    
    public func enableBasicsTab() {
        CapturePrefs()
        let template = LoadComponentTemplate()
        let tabparent: XMLElement? = (currentSettings.rootElement()?.elements(forName: "mso:ribbon").first?.elements(forName: "mso:tabs").first)
        if tabparent != nil {
            let cstabs = tabparent!.elements(forName: "mso:tab")
            let tptabs = template.rootElement()?.elements(forName: "mso:ribbon").first?.elements(forName: "mso:tabs").first?.elements(forName: "mso:tab")
            if tptabs != nil {
                for tab in cstabs {
                    if tab.attribute(forName: "id")?.stringValue == "mso_c5.30BBE710" {
                        tab.detach()
                    }
                }
                for tab in tptabs! {
                    if tab.attribute(forName: "id")?.stringValue == "mso_c5.30BBE710" {
                        tab.detach()
                        tabparent!.insertChild(tab, at: 0)
                        savePrefs()
                        return
                    }
                }
            }
        }
    }
    
    public func disableBasicsTab() {
        CapturePrefs()
        let cstabs = currentSettings.rootElement()?.elements(forName: "mso:ribbon").first?.elements(forName: "mso:tabs").first?.elements(forName: "mso:tab")
        if cstabs != nil {
            for tab in cstabs! {
                if tab.attribute(forName: "id")?.stringValue == "mso_c5.30BBE710" {
                    tab.detach()
                    savePrefs()
                    return
                }
            }
        }
    }
    
    public func enableEssentialsTab() {
        CapturePrefs()
        let template = LoadComponentTemplate()
        let tabparent: XMLElement? = (currentSettings.rootElement()?.elements(forName: "mso:ribbon").first?.elements(forName: "mso:tabs").first)
        if tabparent != nil {
            let cstabs = tabparent!.elements(forName: "mso:tab")
            let tptabs = template.rootElement()?.elements(forName: "mso:ribbon").first?.elements(forName: "mso:tabs").first?.elements(forName: "mso:tab")
            if tptabs != nil {
                for tab in cstabs {
                    if tab.attribute(forName: "id")?.stringValue == "mso_c13.30C490B2" {
                        tab.detach()
                    }
                }
                for tab in tptabs! {
                    if tab.attribute(forName: "id")?.stringValue == "mso_c13.30C490B2" {
                        tab.detach()
                        var index = 0
                        for tab2 in cstabs {    //inserts first unless it sees morphic basics, then it goes immediately after it
                            if tab2.attribute(forName: "id")?.stringValue == "mso_c5.30BBE710" {
                                index = tab2.index + 1
                                break
                            }
                        }
                        tabparent!.insertChild(tab, at: index)
                        savePrefs()
                        return
                    }
                }
            }
        }
    }
    
    public func disableEssentialsTab() {
        CapturePrefs()
        let cstabs = currentSettings.rootElement()?.elements(forName: "mso:ribbon").first?.elements(forName: "mso:tabs").first?.elements(forName: "mso:tab")
        if cstabs != nil {
            for tab in cstabs! {
                if(tab.attribute(forName: "id")?.stringValue == "mso_c13.30C490B2") {
                    tab.detach()
                    savePrefs()
                    return
                }
            }
        }
    }
    
    public func savePrefs() {
        do {
            if _filemanager.fileExists(atPath: path) && !_filemanager.fileExists(atPath: backupPath) {
                try _filemanager.copyItem(atPath: path, toPath: backupPath)
            }
            if _filemanager.fileExists(atPath: path) {
                try _filemanager.removeItem(atPath: path)
            }
            try currentSettings.xmlString.write(toFile: path, atomically: false, encoding: .utf8)
            WordRibbonUIAutomation.RefreshRibbon()
        } catch {
            return
        }
    }
    
    public func restoreOriginal() {
        do {
            if _filemanager.fileExists(atPath: backupPath) {
                if _filemanager.fileExists(atPath: path) {
                    try _filemanager.removeItem(atPath: path)
                }
                try _filemanager.copyItem(atPath: backupPath, toPath: path)
                try _filemanager.removeItem(atPath: backupPath)
            }
            else {
                try _filemanager.removeItem(atPath: path)
                try originalString.write(toFile: path, atomically: false, encoding: .utf8)
            }
            WordRibbonUIAutomation.RefreshRibbon()
        } catch {
            return
        }
    }
    
    private func LoadEmptyTemplate() -> XMLDocument {
        var reply: XMLDocument = XMLDocument()
        do {
            reply = try XMLDocument(contentsOf: Bundle(for: type(of: self)).url(forResource: "EmptyTemplate", withExtension: "xml")!, options: .nodePreserveNamespaceOrder)
        } catch {}
        return reply
    }
    
    private func LoadComponentTemplate() -> XMLDocument {
        var reply: XMLDocument = XMLDocument()
        do {
            reply = try XMLDocument(contentsOf: Bundle(for: type(of: self)).url(forResource: "ComponentTemplate", withExtension: "xml")!, options: .nodePreserveNamespaceOrder)
        } catch {}
        return reply
    }
    
    private let path: String
    private let backupPath: String
    private let _filemanager: FileManager
    private var originalString: String
    private var currentSettings: XMLDocument
}
