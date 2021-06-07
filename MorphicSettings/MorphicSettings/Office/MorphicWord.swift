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
        _filemanager = FileManager()
        if(_filemanager.fileExists(atPath: path)) {
            do {
                try originalSettings = String(contentsOfFile: path, encoding: .utf8)
            } catch {
                originalSettings = UIFile_EmptyTemplate
            }
        } else {
            originalSettings = UIFile_EmptyTemplate
            do {
                try "".write(toFile: path + ".bak", atomically: false, encoding: .utf8)
            } catch {}
        }
        currentSettings = originalSettings
    }
    
    deinit {
        restoreOriginal()
    }
    
    public func enableBasicsRibbon() {
        if(!currentSettings.contains(UIFile_BasicToolbar)) {
            guard let tabIndex = currentSettings.range(of: "<mso:tabs>")?.upperBound else { return }
            currentSettings.insert(contentsOf: UIFile_BasicToolbar, at: tabIndex)
            savePrefs()
        }
    }
    
    public func disableBasicsRibbon() {
        if(currentSettings.contains(UIFile_BasicToolbar)) {
            guard let range = currentSettings.range(of: UIFile_BasicToolbar) else { return }
            currentSettings.removeSubrange(range)
            savePrefs()
        }
    }
    
    public func enableEssentialsRibbon() {
        if(!currentSettings.contains(UIFile_EssentialsToolbar)) {
            if(currentSettings.contains(UIFile_BasicToolbar)) {
                guard let basicIndex = currentSettings.range(of: UIFile_BasicToolbar)?.upperBound else { return }
                currentSettings.insert(contentsOf: UIFile_EssentialsToolbar, at: basicIndex)
            }
            else {
                guard let tabIndex = currentSettings.range(of: "<mso:tabs>")?.upperBound else { return }
                currentSettings.insert(contentsOf: UIFile_EssentialsToolbar, at: tabIndex)
            }
            savePrefs()
        }
    }
    
    public func disableEssentialsRibbon() {
        if(currentSettings.contains(UIFile_EssentialsToolbar)) {
            guard let range = currentSettings.range(of: UIFile_EssentialsToolbar) else { return }
            currentSettings.removeSubrange(range)
            savePrefs()
        }
    }
    
    public func savePrefs() {
        do {
            if(_filemanager.fileExists(atPath: path) && !_filemanager.fileExists(atPath: path + ".bak")) {
                try _filemanager.copyItem(atPath: path, toPath: path + ".bak")
            }
            if(_filemanager.fileExists(atPath: path)) {
                try _filemanager.removeItem(atPath: path)
            }
            try currentSettings.write(toFile: path, atomically: false, encoding: .utf8)
            WordRibbonUIAutomation.RefreshRibbon()
        } catch {
            return
        }
    }
    
    public func restoreOriginal() {
        do {
            if(_filemanager.fileExists(atPath: path + ".bak")) {
                if(_filemanager.fileExists(atPath: path)) {
                    try _filemanager.removeItem(atPath: path)
                }
                try _filemanager.copyItem(atPath: path + ".bak", toPath: path)
                try _filemanager.removeItem(atPath: path + ".bak")
            }
            else {
                try _filemanager.removeItem(atPath: path)
                try originalSettings.write(toFile: path, atomically: false, encoding: .utf8)
            }
            WordRibbonUIAutomation.RefreshRibbon()
        } catch {
            return
        }
    }
    
    private let path: String
    private let _filemanager: FileManager
    private var originalSettings: String
    private var currentSettings: String
    private let UIFile_EmptyTemplate: String = "<mso:customUI xmlns:mso=\"http://schemas.microsoft.com/office/2009/07/customui\"><mso:ribbon><mso:qat/><mso:tabs></mso:tabs></mso:ribbon></mso:customUI>"
    private let UIFile_BasicToolbar: String = "<mso:tab id=\"mso_c5.30BBE710\" label=\"Basics (Morphic)\" insertBeforeQ=\"mso:TabOutlining\"><mso:group id=\"mso_c6.30BBE713\" label=\"                           File                                   .\" autoScale=\"true\"><mso:control idQ=\"mso:FileNewBlankDocument\" visible=\"true\"/><mso:control idQ=\"mso:FileSave\" visible=\"true\"/><mso:control idQ=\"mso:MailMergeMergeToPrinter\" visible=\"true\"/><mso:control idQ=\"mso:FilePrintQuick\" visible=\"true\"/></mso:group><mso:group id=\"mso_c7.30C0260D\" label=\" \" autoScale=\"true\"><mso:control idQ=\"mso:Copy\" visible=\"true\"/><mso:control idQ=\"mso:Cut\" visible=\"true\"/><mso:gallery idQ=\"mso:PasteGallery\" showInRibbon=\"false\" visible=\"true\"/></mso:group><mso:group id=\"mso_c8.30C0ACBC\" label=\" \" autoScale=\"true\"><mso:control idQ=\"mso:TableSelectMenu\" visible=\"true\"/><mso:control idQ=\"mso:Font\" visible=\"true\"/><mso:control idQ=\"mso:FontSizeIncreaseWord\" visible=\"true\"/><mso:control idQ=\"mso:FontSizeDecreaseWord\" visible=\"true\"/><mso:control idQ=\"mso:Bold\" visible=\"true\"/><mso:control idQ=\"mso:Italic\" visible=\"true\"/><mso:gallery idQ=\"mso:TextHighlightColorPicker\" showInRibbon=\"false\" visible=\"true\"/></mso:group><mso:group id=\"mso_c15.30C8B6EF\" label=\" \" autoScale=\"true\"><mso:control idQ=\"mso:ZoomDialog\" visible=\"true\"/><mso:control idQ=\"mso:ReadAloud\" visible=\"true\"/><mso:control idQ=\"mso:TranslateMenu\" visible=\"true\"/></mso:group><mso:group id=\"mso_c16.30C994DF\" label=\" \" autoScale=\"true\"><mso:control idQ=\"mso:ToggleLearningTools\" visible=\"true\"/></mso:group></mso:tab>"
    private let UIFile_EssentialsToolbar: String = "<mso:tab id=\"mso_c13.30C490B2\" label=\"Essentials (Morphic)\" insertBeforeQ=\"mso:TabOutlining\"><mso:group id=\"mso_c17.30CB83CB\" label=\"FILE     PRINT     FORMAT\" autoScale=\"true\"><mso:control idQ=\"mso:FileNewBlankDocument\" visible=\"true\"/><mso:gallery idQ=\"mso:PageMarginsGallery\" showInRibbon=\"false\" visible=\"true\"/><mso:gallery idQ=\"mso:PageOrientationGallery\" showInRibbon=\"false\" visible=\"true\"/><mso:control idQ=\"mso:FileSave\" visible=\"true\"/><mso:control idQ=\"mso:FileSaveAs\" visible=\"true\"/><mso:control idQ=\"mso:MailMergeMergeToPrinter\" visible=\"true\"/><mso:control idQ=\"mso:NavigationPaneFind\" visible=\"true\"/><mso:control idQ=\"mso:PasteSpecialDialog\" visible=\"true\"/><mso:control idQ=\"mso:FormatPainter\" visible=\"true\"/></mso:group><mso:group id=\"mso_c18.30D0F612\" label=\"TEXT\" autoScale=\"true\"><mso:control idQ=\"mso:StyleGalleryClassic\" visible=\"true\"/><mso:control idQ=\"mso:Font\" visible=\"true\"/><mso:control idQ=\"mso:FontSize\" visible=\"true\"/><mso:gallery idQ=\"mso:FontColorPicker\" showInRibbon=\"false\" visible=\"true\"/><mso:gallery idQ=\"mso:QuickStylesGallery\" showInRibbon=\"false\" visible=\"true\"/><mso:control idQ=\"mso:Bold\" visible=\"true\"/><mso:control idQ=\"mso:Italic\" visible=\"true\"/><mso:control idQ=\"mso:Underline\" visible=\"true\"/><mso:control idQ=\"mso:Strikethrough\" visible=\"true\"/><mso:control idQ=\"mso:Superscript\" visible=\"true\"/></mso:group><mso:group id=\"mso_c19.30D11D4E\" label=\"PARAGRAPH\" autoScale=\"true\"><mso:control idQ=\"mso:AlignLeft\" visible=\"true\"/><mso:control idQ=\"mso:AlignCenter\" visible=\"true\"/><mso:control idQ=\"mso:AlignRight\" visible=\"true\"/><mso:control idQ=\"mso:AlignJustifyMenu\" visible=\"true\"/><mso:gallery idQ=\"mso:BulletsGalleryWord\" showInRibbon=\"false\" visible=\"true\"/><mso:gallery idQ=\"mso:NumberingGalleryWord\" showInRibbon=\"false\" visible=\"true\"/><mso:control idQ=\"mso:OutdentClassic\" visible=\"true\"/><mso:gallery idQ=\"mso:LineSpacingGallery\" showInRibbon=\"false\" visible=\"true\"/><mso:control idQ=\"mso:IndentIncreaseWord\" visible=\"true\"/><mso:control idQ=\"mso:ParagraphMarks\" visible=\"true\"/><mso:gallery idQ=\"mso:ShadingColorPicker\" showInRibbon=\"false\" visible=\"true\"/><mso:gallery idQ=\"mso:BordersSelectionGallery\" showInRibbon=\"false\" visible=\"true\"/></mso:group><mso:group id=\"mso_c20.30D1230E\" label=\"INSERT\" autoScale=\"true\"><mso:gallery idQ=\"mso:TableInsertGallery\" showInRibbon=\"false\" visible=\"true\"/><mso:gallery idQ=\"mso:HeaderInsertGallery\" showInRibbon=\"false\" visible=\"true\"/><mso:gallery idQ=\"mso:FooterInsertGallery\" showInRibbon=\"false\" visible=\"true\"/><mso:control idQ=\"mso:TextPictureFill\" visible=\"true\"/><mso:gallery idQ=\"mso:ShapesInsertGallery\" showInRibbon=\"false\" visible=\"true\"/><mso:control idQ=\"mso:HyperlinkInsert\" visible=\"true\"/><mso:control idQ=\"mso:SymbolInsert\" visible=\"true\"/><mso:gallery idQ=\"mso:EquationInsertGallery\" showInRibbon=\"false\" visible=\"true\"/></mso:group><mso:group id=\"mso_c21.30D129BA\" label=\"EDITING\" autoScale=\"true\"><mso:control idQ=\"mso:InsertNewComment\" visible=\"true\"/><mso:control idQ=\"mso:ReviewTrackChanges\" visible=\"true\"/><mso:control idQ=\"mso:ReviewAcceptOrRejectChangeDialog\" visible=\"true\"/><mso:control idQ=\"mso:AccessibilityChecker\" visible=\"true\"/><mso:gallery idQ=\"mso:Undo\" showInRibbon=\"false\" visible=\"true\"/><mso:control idQ=\"mso:SpellingAndGrammar\" visible=\"true\"/></mso:group><mso:group id=\"mso_c22.30D13DF5\" label=\"EASIER TO READ\" autoScale=\"true\"><mso:control idQ=\"mso:ToggleLearningTools\" visible=\"true\"/><mso:control idQ=\"mso:ReadAloud\" visible=\"true\"/><mso:control idQ=\"mso:TranslateMenu\" visible=\"true\"/><mso:control idQ=\"mso:ZoomDialog\" visible=\"true\"/></mso:group></mso:tab>"
}
