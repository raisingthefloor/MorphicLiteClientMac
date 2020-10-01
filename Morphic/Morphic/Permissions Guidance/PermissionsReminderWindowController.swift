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


import Cocoa
import Foundation

class PermissionsReminderWindowController: NSWindowController, PermissionsWindowController {
    
    @IBOutlet var label: NSTextFieldCell!
    @IBOutlet var prefsButton: NSButton!
    @IBOutlet var cancelButton: NSButton!
    
    let DisplayInCenter = true
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.level = .floating
    }
    
    @IBAction
    func openPrefs(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    
    @IBAction
    func closeWindow(_ sender: Any) {
        PermissionsGuidanceSystem.shared.state = .inactive
        PermissionsGuidanceSystem.shared.swapWindow()
    }
    
    func update(state: PermissionsGuidanceSystem.windowState, bounds: CGRect) {
        if state != .notOpen && state != .systemPrompt && state != .unfocused && state != .wrongTab {
            PermissionsGuidanceSystem.shared.swapWindow()
        }
        else {
            prefsButton.isHidden = false
            cancelButton.isHidden = false
            window?.alphaValue = 1.0
            switch state {
            case .inactive:
                break
            case .notOpen:
                label.title = "Please open the Security menu in System Preferences.\n\nMorphic requires Accessibility permissions in Security in order to be able to change settings when you ask."
            case .unfocused:
                label.title = "Please open the Security menu in System Preferences.\n\nMorphic requires Accessibility permissions in Security in order to be able to change settings when you ask."
            case .wrongTab:
                label.title = "Please click on the \"Security and Privacy\" icon.\n\nMorphic requires Accessibility permissions in Security in order to be able to change settings when you ask."
            case .systemPrompt:
                if DisplayInCenter {
                    window?.alphaValue = 0.0
                }
                prefsButton.isHidden = true
                cancelButton.isHidden = true
                label.title = "Please open the Security menu in System Preferences.\n\nMorphic requires Accessibility permissions in Security in order to be able to change settings when you ask."
            case .guidanceUp:
                break
            case .success:
                break
            }
            var xval: CGFloat = (window?.screen?.frame.maxX ?? 0.0) - (window?.frame.width ?? 0.0)
            var yval: CGFloat = (window?.screen?.frame.maxY ?? 0.0)
            if DisplayInCenter {
                xval = ((window?.screen?.frame.maxX ?? 0.0) - (window?.frame.width ?? 0.0)) / 2.0
                yval = (window?.screen?.frame.maxY ?? 0.0) / 2.0 + (window?.frame.height ?? 0.0)
            }
            window?.setFrameTopLeftPoint(NSPoint(x: xval, y: yval))
        }
    }
    
    
}
