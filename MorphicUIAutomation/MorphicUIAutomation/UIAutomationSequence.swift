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
    private var launchedBundleIdentifiers: Set<String>
    private var isFinished = false

    public init() {
        launchedBundleIdentifiers = Set<String>()
    }

    deinit {
        if isFinished == false {
            do {
                try self.terminateAllLaunchedApplications()
            } catch {
                // as we are in a deinit sequence, we ignore any errors; if the user would like to catch any termination errors, they should call finish() manually
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
        
        try self.terminateAllLaunchedApplications()
    }
    
    // NOTE: this function only throws the first exception it receives from an application while trying to terminate (even if multiple apps threw an exception); it intentinoally waits until all terminations are attempted before rethrowing the error
    private func terminateAllLaunchedApplications() throws {
        var caughtError: Error? = nil

        while self.launchedBundleIdentifiers.count > 0 {
            // NOTE: we remove the launched bundle identifiers as we terminate them (since this function is only called when the operation is being finished or deinit'ed)
            let launchedBundleIdentifier = self.launchedBundleIdentifiers.removeFirst()

            if UIAutomationApp.isRunningApplication(bundleIdentifier: launchedBundleIdentifier) == true {
                do {
                    try UIAutomationApp.terminate(bundleIdentifier: launchedBundleIdentifier)
                } catch let error {
                    // catch the first error (if any)
                    if caughtError == nil {
                        caughtError = error
                    }
                }
            }
        }
        
        // if terminating application(s) threw error(s), rethrow the first error we caught
        if let caughtError = caughtError {
            throw caughtError
        }
    }

    internal func setScriptLaunchedApplicationFlag(bundleIdentifier: String) {
        self.launchedBundleIdentifiers.insert(bundleIdentifier)
    }
}
