//
//  AppDelegate.swift
//  MorphicMenuBar
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import OSLog
import MorphicCore
import MorphicService

private let logger = OSLog(subsystem: "app", category: "delegate")

// MARK: - Custom Application

/// Has the responsibility of creating an `AppDelegate` since we aren't using a Main storyboard to create the delegate
class Application: NSApplication{
    
    /// The application delegate
    ///
    /// Created at application launch and retained with a strong reference so it never gets destroyed.
    /// Since we aren't using a Main storyboard, we have to create the delegate manually.
    var strongDelegate = AppDelegate()
    
    override init() {
        super.init()
        delegate = strongDelegate
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createStatusItem()
        if Morphic.shared.currentUserIdentifier == nil{
            Morphic.shared.launchConfigurator()
            UserDefaults.morphic.addObserver(self, forKeyPath: .morphicDefaultsKeyUserIdentifier, options: .new, context: nil)
        }else{
            Morphic.shared.fetchUserPreferences()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    // MARK: - Status Bar Item

    /// The item that shows in the macOS menu bar
    var statusItem: NSStatusItem!
    
    /// Create our `statusItem` for the macOS menu bar
    ///
    /// Should be called during application launch
    func createStatusItem(){
        statusItem = NSStatusBar.system.statusItem(withLength: -1)
        guard let button = statusItem.button else {
            return
        }
        button.image = NSImage(named: "MenuIcon")
        button.alternateImage = NSImage(named: "MenuIconAlternate")
        button.target = self
        button.action = #selector(toggleQuickStrip(_:))
    }
    
    // MARK: - Quick Strip
    
    /// The window controller for the morphic quick strip that is shown by clicking on the `statusItem`
    var quickStripController: NSWindowController?
    
    /// Show or hide the morphic quick strip
    ///
    /// - parameter sender: The UI element that caused this action to be invoked
    @objc
    func toggleQuickStrip(_ sender: Any){
        guard let button = sender as? NSButton else{
            return
        }
        if let controller = quickStripController{
            controller.close()
        }else{
            NSApplication.shared.activate(ignoringOtherApps: true)
            let location = button.window!.convertPoint(toScreen: button.convert(NSPoint(x: 0, y: button.bounds.size.height), to: nil))
            let storyboard = NSStoryboard(name: "QuickStrip", bundle: nil)
            guard let controller = storyboard.instantiateInitialController() as? NSWindowController else{
                return
            }
            quickStripController = controller
            controller.window?.level = .floating
            controller.window?.delegate = self
            controller.window?.setFrameOrigin(location)
            controller.showWindow(button)
        }
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        os_log(.info, log: logger, "didBecomeKey")
    }
    
    func windowDidResignKey(_ notification: Notification) {
        os_log(.info, log: logger, "didResignKey")
        quickStripController?.close()
    }
    
    func windowWillClose(_ notification: Notification) {
        os_log(.info, log: logger, "willClose")
        quickStripController = nil
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        toggleQuickStrip(statusItem.button!)
        UserDefaults.morphic.removeObserver(self, forKeyPath: .morphicDefaultsKeyUserIdentifier)
        Morphic.shared.fetchUserPreferences()
    }

}
