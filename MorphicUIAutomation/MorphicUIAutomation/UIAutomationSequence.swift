// Copyright 2020-2023 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/raisingthefloor/morphic-macos/blob/master/LICENSE.txt
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

public class UIAutomationSequence {
    private let bundleIdentifier: String
    private var scriptLaunchedApplication = false
    private var isFinished = false

    public init(bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
    }
    
    deinit {
        if isFinished == false {
            let isRunningApplication = UIAutomationApp.isRunningApplication(bundleIdentifier: SystemSettingsApp.bundleIdentifier)
            if self.scriptLaunchedApplication == true && isRunningApplication == true {
                do {
                    try SystemSettingsApp.terminate()
                } catch {
                    // as we are in a deinit sequence, we ignore any errors; if the user would like to catch any termination errors, they should call finish() manually
                }
            }
        }
    }
    
    public func finish() throws {
        // fail gracefully if finish is called a second time
        if isFinished == true {
            return
        }
        
        defer {
            isFinished = true
        }
        
        let isRunningApplication = UIAutomationApp.isRunningApplication(bundleIdentifier: SystemSettingsApp.bundleIdentifier)
        if self.scriptLaunchedApplication == true && isRunningApplication == true {
            try SystemSettingsApp.terminate()
        }
    }
    
    internal func setScriptLaunchedApplicationFlag() {
        self.scriptLaunchedApplication = true
    }
    
    
}
