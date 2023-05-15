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

import Cocoa

// NOTE: the MorphicProcess class contains the functionality used by Obj-C and Swift applications

public class MorphicProcess {
    // MARK: - Process/service restarting functionality
    
    public static func restartViaLaunchctl(serviceNames: [String]) {
        // get the current user's ID
        // NOTE: in future releases of macOS we may need to consider using SCDynamicStoreCopyConsoleUser or other methods
        let userId = getuid()

        for serviceName in serviceNames {
            let domainTarget = "gui/" + String(userId) + "/" + serviceName
            MorphicProcess.restartViaLaunchctl(domainTarget: domainTarget)
        }
    }
    
    public static func restartViaLaunchctl(domainTarget: String) {
         let launchctlProcess = Process()
         launchctlProcess.launchPath = "/bin/launchctl"
         launchctlProcess.arguments = ["kickstart", "-k", domainTarget]
         launchctlProcess.launch()
    }
    
    public static func logOutUserViaLaunchctl() {
        // get the current user's ID
        // NOTE: in future releases of macOS we may need to consider using SCDynamicStoreCopyConsoleUser or other methods
        let userId = getuid()
        //
        // alternate domainTarget is "gui/$(id -u)
        let domainTarget = "gui/" + String(userId)

        let launchctlProcess = Process()
        launchctlProcess.launchPath = "/bin/launchctl"
        launchctlProcess.arguments = ["bootout", domainTarget]
        launchctlProcess.launch()
    }

    // NOTE: perhaps we should break out a discrete class for all the logout/reset/shutdown functions
    public static func logOutUserViaOsaScriptWithConfirmation() {
        // NOTE: alternative (which requires some permissions): osascript -e 'tell app "System Events" to log out'
        // NOTE: alternative _might_ be to send Shift+Command+Q to the system via emulated key strokes
        // NOTE: the event tags (e.g. aevtlogo) can be found in AERegistry.h
        let launchctlProcess = Process()
        launchctlProcess.launchPath = "/usr/bin/osascript"
        launchctlProcess.arguments = ["-e", "tell application \"loginwindow\" to «event aevtlogo»"]
        launchctlProcess.launch()
    }

    public static func logOutUserViaOsaScriptWithoutConfirmation() {
        let launchctlProcess = Process()
        launchctlProcess.launchPath = "/usr/bin/osascript"
        launchctlProcess.arguments = ["-e", "tell application \"loginwindow\" to «event aevtrlgo»"]
        launchctlProcess.launch()
    }

//    public static func restartSystemViaOsaScriptWithConfirmation() {
//        let launchctlProcess = Process()
//        launchctlProcess.launchPath = "/usr/bin/osascript"
//        launchctlProcess.arguments = ["-e", "tell application \"loginwindow\" to «event aevtrrst»"]
//        launchctlProcess.launch()
//    }
//
//    public static func shutdownSystemViaOsaScriptWithConfirmation() {
//        let launchctlProcess = Process()
//        launchctlProcess.launchPath = "/usr/bin/osascript"
//        launchctlProcess.arguments = ["-e", "tell application \"loginwindow\" to «event aevtrsdn»"]
//        launchctlProcess.launch()
//    }

    // MARK: - Process opening (starting) functions
    
    public enum OpenProcessError: Error {
        case osError(Error)
    }
    public static func openProcess(at url: URL, arguments: [String], activate: Bool, hide: Bool) async throws -> NSRunningApplication {
        //
        let config = NSWorkspace.OpenConfiguration()
        config.activates = activate
        config.hides = hide
        config.arguments = arguments
        
        do {
            let runningApplication = try await NSWorkspace.shared.openApplication(at: url, configuration: config)
            return runningApplication
        } catch let error {
            // NOTE: in the future, we may want to consider
            throw OpenProcessError.osError(error)
        }
    }
    
    public static func openProcess(at url: URL, arguments: [String], activate: Bool, hide: Bool, completionHandler: ((NSRunningApplication?, Error?) -> Void)? = nil) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = activate
            config.hides = hide
            config.arguments = arguments
            
            NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: completionHandler)
    }
    
    //
    
    public static var operatingSystemVersion: OperatingSystemVersion {
        get {
            return ProcessInfo.processInfo.operatingSystemVersion
        }
    }
}
