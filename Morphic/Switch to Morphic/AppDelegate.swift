//
//  AppDelegate.swift
//  Switch to Morphic
//
//  Created by Stradetch on 11/22/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import Cocoa
import OSLog

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    //static var topApplication: NSRunningApplication?
    
    static var topApplication: String = ""

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.setTopApplication(_:)), name: NSWorkspace.didDeactivateApplicationNotification, object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        let topApp = NSRunningApplication.runningApplications(withBundleIdentifier: AppDelegate.topApplication).first
        if topApp != nil {
            topApp?.activate(options: .activateIgnoringOtherApps)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            var morphicApp = NSRunningApplication.runningApplications(withBundleIdentifier: "org.raisingthefloor.Morphic").first
            if morphicApp == nil {
                morphicApp = NSRunningApplication.runningApplications(withBundleIdentifier: "org.raisingthefloor.Morphic-Debug").first
            }
            if morphicApp == nil {
                print("COULDN'T FIND MORPHIC")
                return
            }
            morphicApp!.activate(options: .activateIgnoringOtherApps)
            print("FOUND MORPHIC")
        }
    }
    
    @objc
    func setTopApplication(_ aNotification: NSNotification) {
        let app = aNotification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        print(app?.bundleIdentifier ?? "NOT FOUND")
        AppDelegate.topApplication = app?.bundleIdentifier ?? AppDelegate.topApplication
    }
}
