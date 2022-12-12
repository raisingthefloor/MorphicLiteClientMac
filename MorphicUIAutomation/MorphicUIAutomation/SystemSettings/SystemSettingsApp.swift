// Copyright 2020-2022 Raising the Floor - US, Inc.
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
import MorphicMacOSNative

public class SystemSettingsApp {
    // NOTE: prior to macOS 13, the app was named "System Preferences"; the bundle identifier is "com.apple.systempreferences" under all tested versions of macOS (10.14 through 13.0, as of 2022-Dec)
    public static let bundleIdentifier = "com.apple.systempreferences"

    private let uiAutomationApp: UIAutomationApp
    
    private init(uiAutomationApp: UIAutomationApp) {
        self.uiAutomationApp = uiAutomationApp
    }
    
    public static func launchOrAttach(waitUntilFinishedLaunching: TimeInterval = 0.0) async throws -> SystemSettingsApp {
        let uiAutomationApp: UIAutomationApp
        do {
            (uiAutomationApp, _) = try await UIAutomationApp.launchOrAttach(bundleIdentifier: bundleIdentifier, waitUntilFinishedLaunching: waitUntilFinishedLaunching)
        } catch let error {
            throw error // UIAutomationApp.LaunchError
        }
        
        let result = SystemSettingsApp(uiAutomationApp: uiAutomationApp)
        return result
    }
 
    // MARK: - App process status
    
    public func waitUntilFinishedLaunching(_ timeInterval: TimeInterval) async -> Bool {
        let result = await self.uiAutomationApp.waitUntilFinishedLaunching(timeInterval)
        return result
    }

    public var isFinishedLaunching: Bool {
        return self.uiAutomationApp.runningApplication.isFinishedLaunching
    }

    public var isTerminated: Bool {
        return self.uiAutomationApp.runningApplication.isTerminated
    }
}
