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
import MorphicCore
import MorphicSettings

public protocol PermissionsWindowController: NSWindowController {
    
    func update(state: PermissionsGuidanceSystem.windowState, bounds: CGRect)
}

public class PermissionsGuidanceSystem {
    
    public enum windowState {
        case inactive
        case notOpen
        case unfocused
        case wrongTab
        case systemPrompt
        case guidanceUp
        case success
    }
    
    var state: windowState
    
    var bounds: CGRect
    
    static let shared = PermissionsGuidanceSystem()
    
    private var currentWindow: PermissionsWindowController?
    
    init() {
        currentWindow = nil
        state = .inactive
        bounds = CGRect()
    }
    
    public func beginLoop() {
        if !MorphicA11yAuthorization.authorizationStatus() && state == .inactive {
            state = .systemPrompt   //most likely first state
            swapWindow()
            updateLoop()
        }
    }
    
    public func swapWindow() {
        currentWindow?.window?.close()
        switch state {
        case .inactive:
            currentWindow = nil
        case .notOpen:
            currentWindow = PermissionsReminderWindowController(windowNibName: "PermissionsReminderWindow")
        case .unfocused:
            currentWindow = PermissionsReminderWindowController(windowNibName: "PermissionsReminderWindow")
        case .wrongTab:
            currentWindow = PermissionsReminderWindowController(windowNibName: "PermissionsReminderWindow")
        case .systemPrompt:
            currentWindow = PermissionsReminderWindowController(windowNibName: "PermissionsReminderWindow")
        case .guidanceUp:
            currentWindow = PermissionsGuidanceWindowController(windowNibName: "PermissionsGuidanceWindow")
        case .success:
            currentWindow = PermissionsSuccessWindowController(windowNibName: "PermissionsSuccessWindow")
        }
        currentWindow?.window?.makeKeyAndOrderFront(nil)
        currentWindow?.window?.delegate = AppDelegate.shared
    }
    
    private func updateLoop() {
        if state == .inactive {
            return
        }
        let prefsWindowHeight: CGFloat = 573 //the correct window is this height on both Mojave and Catalina, will need to be re-checked on future OS versions
        guard var windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: AnyObject]] else {
            return
        }
        windows = windows.filter { (window) -> Bool in
            let windowLayer = window[kCGWindowLayer as String] as? NSNumber
            return windowLayer == 0
        }
        if MorphicA11yAuthorization.authorizationStatus() {
            if state == .guidanceUp || state == .success {
                state = .success
                for window in windows {
                    if window["kCGWindowOwnerName"] != nil && window["kCGWindowOwnerName"] as! String == "System Preferences" {
                        let propdict = window[kCGWindowBounds as String] as! CFDictionary
                        bounds = CGRect.init(dictionaryRepresentation: propdict) ?? CGRect()
                    }
                }
            }
            else {
                state = .inactive
            }
        }
        else {
            let applicationProcessId = Int(getpid())
            state = .notOpen
            var focused = true
            for window in windows {
                guard let windowProcessId = window[kCGWindowOwnerPID as String] as? Int else {
                    continue
                }
                if windowProcessId == applicationProcessId {
                    continue
                }
                if window["kCGWindowOwnerName"] != nil && window["kCGWindowOwnerName"] as! String == "System Preferences" {
                    state = .wrongTab
                    let propdict = window[kCGWindowBounds as String] as! CFDictionary
                    bounds = CGRect.init(dictionaryRepresentation: propdict) ?? CGRect()
                    if bounds.height == prefsWindowHeight {
                        state = .unfocused
                        if focused {
                            state = .guidanceUp
                            focused = false
                        }
                    }
                }
                else if window["kCGWindowOwnerName"] != nil && window["kCGWindowOwnerName"] as! String == "universalAccessAuthWarn" {
                    state = .systemPrompt
                    break
                }
                else {
                    focused = false
                }
            }
        }
        currentWindow?.update(state: state, bounds: bounds)
        AsyncUtils.wait(atMost: 0.03, for: {false}) {_ in
            self.updateLoop()
        }
    }
}
