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
    
    public static func openProcess(at url: URL, arguments: [String], activate: Bool, hide: Bool, completionHandler: ((NSRunningApplication?, Error?) -> Void)? = nil) {
        if #available(macOS 10.15, *) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = activate
            config.hides = hide
            config.arguments = arguments
            
            NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: completionHandler)
        } else {
            // fall-back to now-deprecated functionality for earlier versions of macOS
            var launchOptionsValue: UInt = 0
            if hide == true {
                launchOptionsValue |= NSWorkspace.LaunchOptions.andHide.rawValue
            }
            if activate == false {
                launchOptionsValue |= NSWorkspace.LaunchOptions.withoutActivation.rawValue
            }
            //
            let options = NSWorkspace.LaunchOptions(rawValue: launchOptionsValue)
            
            var configuration: [NSWorkspace.LaunchConfigurationKey : Any] = [:]
            if arguments != [] {
                configuration[.arguments] = arguments as [NSString]
            }

            // NOTE: we use a synchronous function to launch our application, so we need to do this on a background thread (i.e. not the UI thread)
            DispatchQueue.global(qos: .background).async {
                do {
                    // NOTE: the alternate overload of launchApplication (and maybe this one) sends didLaunchApplicationNotification to the NSWorkspace object’s notification center once the application is launched; as an alternative to our current DispatchQueue.async implementation, we could consider using a LaunchOption.async or calling the overload instead.
                    let runningApplication = try NSWorkspace.shared.launchApplication(at: url, options: options, configuration: configuration)
                    completionHandler?(runningApplication, nil)
                } catch let error {
                    completionHandler?(nil, error)
                }
            }
        }
    }
}
