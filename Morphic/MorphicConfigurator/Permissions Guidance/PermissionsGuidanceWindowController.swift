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
import CoreGraphics

class PermissionsGuidanceWindowController: NSWindowController {
    
    @IBOutlet weak var guideBox: NSBox!
    @IBOutlet weak var remindBox: NSBox!
    @IBOutlet weak var remindText: NSTextFieldCell!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.isOpaque = false
        window?.backgroundColor = NSColor.clear
        guideBox.fillColor = NSColor.windowBackgroundColor
        remindBox.fillColor = NSColor.windowBackgroundColor
        guideBox.isHidden = false
        remindBox.isHidden = true
        window?.level = .floating
        self.updateLoop()
    }
    
    func updateLoop()
    {
        //MorphicA11yAuthorization
        guard var windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: AnyObject]] else {
            return
        }
        windows = windows.filter { (window) -> Bool in
            let windowLayer = window[kCGWindowLayer as String] as? NSNumber
            return windowLayer == 0
        }
        let applicationProcessId = Int(getpid())
        enum prefsState{
            case notOpen
            case notFocused
            case wrongTab
            case correct
        }
        var state: prefsState = prefsState.notOpen
        var focused = true
        var ayy = 12341234
        var bounds: CGRect = CGRect()
        for window in windows {
            guard let windowProcessId = window[kCGWindowOwnerPID as String] as? Int else {
                continue
            }
            if windowProcessId == applicationProcessId {
                continue
            }
            if(window["kCGWindowOwnerName"] != nil && window["kCGWindowOwnerName"] as! String == "System Preferences") {
                state = prefsState.wrongTab
                let propdict = window[kCGWindowBounds as String] as! CFDictionary
                bounds = CGRect.init(dictionaryRepresentation: propdict) ?? CGRect()
                ayy = Int(bounds.height)
                if bounds.height == 573 as CGFloat {
                    state = prefsState.notFocused
                    if focused {
                        state = prefsState.correct
                    }
                }
                break
            }
            focused = false
        }
        
        
        
        var xval: CGFloat = (window?.screen?.frame.maxX ?? 0.0) - (window?.frame.width ?? 0)
        var yval: CGFloat = (window?.screen?.frame.maxY ?? 0.0)
        switch state {
        case .notOpen:
            remindBox.isHidden = false
            guideBox.isHidden = true
            remindText.title = "OPEN THE WINDOW"
        case .notFocused:
            remindBox.isHidden = false
            guideBox.isHidden = true
            remindText.title = "FOCUS THE WINDOW"
        case .wrongTab:
            remindBox.isHidden = false
            guideBox.isHidden = true
            remindText.title = "GO TO THE PERMISSIONS TAB"
        case .correct:
            remindBox.isHidden = true
            guideBox.isHidden = false
            xval = bounds.minX
            yval = (window?.screen?.frame.maxY ?? 0.0) - bounds.minY
        }
        window?.setFrameTopLeftPoint(NSPoint(x: xval, y: yval))
        
        let output = String(ayy) + windows.debugDescription
        let file = "debugoutput.txt"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
            do {
                try output.write(to:fileURL, atomically:false, encoding:.utf8)
            } catch {}
        }
        //return;
        AsyncUtils.wait(atMost: 0.03, for: {false}) {_ in
            self.updateLoop()
        }
    }
}
