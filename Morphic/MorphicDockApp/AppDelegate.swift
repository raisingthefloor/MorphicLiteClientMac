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

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // capture the "terminateMorphicDockApp" message (to terminate the dock app when Morphic is shutting down)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.terminateMorphicDockApp), name: .terminateMorphicDockApp, object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if morphicIsRunning() == true {
            // tell the Morphic Client app to show the Morphic bar
            DistributedNotificationCenter.default().postNotificationName(.showMorphicBar, object: nil, userInfo: nil, deliverImmediately: true)
            
            // NOTE: ideally we would only check this if our application was becoming active because it was clicked in the dock (i.e. pinned to the dock)
            // if the dock app shouldn't be running (i.e. dock and cmd+tab entries aren't appropriate), shut down now
            if shouldDockAppBeRunning() == false {
                terminateMorphicDockApp()
            }
        } else {
            // if the application isn't already running, launch it now
            
            // calculate the path to the main application's executable
            let dockAppBundlePath = Bundle.main.bundlePath as NSString
            var pathComponents = dockAppBundlePath.pathComponents
            // remove the last 3 components (.../Contents/Library/ Morphic .app) from the bundle path; the remaining path components will end the path at "Morphic###.app" (our application bundle entry point)
            pathComponents.removeLast(3)
            // NOTE: if we preferred to do so, we could instead remove the last three componeents and then append "MacOS" and "Morphic###" to the end of the path (to launch the application executable directly, vs. via Morphic###.app)
            var morphicClientApplicationPath = NSString.path(withComponents: pathComponents)
            
            // NOTE: for debug time, the specified folder is actually one folder ABOVE Morphic.app (and our application is not embedded), so go ahead and appent the appropriate suffix to our actual application if necessary
            if morphicClientApplicationPath.hasSuffix("/Morphic.app") == false {
                morphicClientApplicationPath += "/Morphic.app"
            }
            
            // launch the main application
            // NOTE: this will behave identically to just starting up Morphic normally (which is our intention since we're covering the scenario that the dock icon was pinned and the intent is just to start up Morphic)
            // NOTE: in the future, we should try to distinguish between "user clicking on dock icon" and "user starting up application" so that clicking on the dock icon ALWAYS shows the MorphicBar
            _ = NSWorkspace.shared.launchApplication(morphicClientApplicationPath)
            
            // if the dock app shouldn't be running (i.e. dock and cmd+tab entries aren't appropriate), shut down now
            if shouldDockAppBeRunning() == false {
                terminateMorphicDockApp()
            }
        }
    }
    
    func morphicIsRunning() -> Bool {
        // determine if Morphic is already running
        let morphicApplications = NSWorkspace.shared.runningApplications.filter({
            application in
            switch application.bundleIdentifier {
            case "org.raisingthefloor.Morphic",
                 "org.raisingthefloor.Morphic-Debug":
                return true
            default:
                return false
            }
        })
        return (morphicApplications.count > 0)
    }
    
    func shouldDockAppBeRunning() -> Bool {
        return (NSWorkspace.shared.isVoiceOverEnabled == true) || (NSApplication.shared.isFullKeyboardAccessEnabled == true)
    }

    @objc
    func terminateMorphicDockApp() {
        NSApplication.shared.terminate(self)
    }
}

extension NSNotification.Name {
    static let showMorphicBar = NSNotification.Name("org.raisingthefloor.showMorphicBar")
    static let terminateMorphicDockApp = NSNotification.Name(rawValue: "org.raisingthefloor.terminateMorphicDockApp")
}
