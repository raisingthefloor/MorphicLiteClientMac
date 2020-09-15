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
import OSLog
import MorphicCore
import MorphicService
import MorphicSettings

private let logger = OSLog(subsystem: "app", category: "delegate")

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    static var shared: AppDelegate!
    
    @IBOutlet var menu: NSMenu!
    @IBOutlet weak var showMorphicBarMenuItem: NSMenuItem?
    @IBOutlet weak var hideMorphicBarMenuItem: NSMenuItem?
    @IBOutlet weak var captureMenuItem: NSMenuItem!
    @IBOutlet weak var loginMenuItem: NSMenuItem!
    @IBOutlet weak var logoutMenuItem: NSMenuItem?

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        os_log(.info, log: logger, "applicationDidFinishLaunching")
        AppDelegate.shared = self
        os_log(.info, log: logger, "opening morphic session...")
        populateSolutions()
        createStatusItem()
        loadInitialDefaultPreferences()
        createEmptyDefaultPreferencesIfNotExist {
            Session.shared.open {
                os_log(.info, log: logger, "session open")
                #if EDITION_BASIC
                #else
        //        #elseif EDITION_COMMUNITY
                    if Session.shared.user == nil {
                        self.showMorphicBarMenuItem?.isHidden = true
                    }
                #endif
                #if EDITION_BASIC
                #else
        //        #elseif EDITION_COMMUNITY
                    self.loginMenuItem?.isHidden = (Session.shared.user != nil)
                #endif
                self.logoutMenuItem?.isHidden = (Session.shared.user == nil)
                if Session.shared.user != nil {
                    if Session.shared.bool(for: .morphicBarVisible) ?? true {
                        self.showMorphicBar(nil)
                    }
                    #if EDITION_BASIC
                    #else
//                    #elseif EDITION_COMMUNITY
                        // reload the community bar
                        self.reloadMorphicCommunityBar() {
                            success, error in
                            
                            if error == .userHasNoCommunities {
                                // if the user has no communities, log them back out
                                self.logout(nil)
                            }
                        }
                    #endif
                }
                DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.userDidSignin), name: .morphicSignin, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.sessionUserDidChange(_:)), name: .morphicSessionUserDidChange, object: Session.shared)

                #if EDITION_BASIC
                #else
//                #elseif EDITION_COMMUNITY
                    // if no user is logged in, launch the login window at startup of Morphic Community
                    // NOTE: in the future we may want to consider only auto-launching the login window on first-run (perhaps as part of an animated sequence introducing Morphic to the user).
                    if (Session.shared.user == nil) {
                        self.launchConfigurator(argument: "login")
                    }
                #endif
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    // MARK: - Notifications
    
    @objc
    func userDidSignin(_ notification: NSNotification) {
        os_log(.info, log: logger, "Got signin notification from configurator")
        Session.shared.open {
            NotificationCenter.default.post(name: .morphicSessionUserDidChange, object: Session.shared)
            #if EDITION_BASIC
                let userInfo = notification.userInfo ?? [:]
                if !(userInfo["isRegister"] as? Bool ?? false) {
                    os_log(.info, log: logger, "Is not a registration signin, applying all preferences")
                    Session.shared.applyAllPreferences {
                    }
                }
            #endif
        }
    }
    
    @objc
    func sessionUserDidChange(_ notification: NSNotification) {
        guard let session = notification.object as? Session else {
            return
        }
        #if EDITION_BASIC
        #else
//        #elseif EDITION_COMMUNITY
            self.loginMenuItem?.isHidden = (session.user != nil)
        #endif
        self.logoutMenuItem?.isHidden = (session.user == nil)
        
        #if EDITION_BASIC
        #else
//        #elseif EDITION_COMMUNITY
            if session.user != nil {
                // reload the community bar
                reloadMorphicCommunityBar() {
                    success, error in
                    if success == true {
                        self.showMorphicBar(nil)
                    } else {
                        /* NOTE: logging in but then not being able to get a community bar typically comes down to one of three things:
                         * 1. User is not a Morphic Community user
                         * 2. User does not have any community bars
                         * 3. Intermittent server failure
                         */
                        self.logout(nil)
                    }
                }
            }
        #endif
    }
    
    enum ReloadMorphicCommunityBarError : Error {
        case noUserSpecified
        case userHasNoCommunities
        case networkOrAuthorizationOrSaveToDiskFailure
    }
    //
    func reloadMorphicCommunityBar(completion: @escaping (_ success: Bool, _ error: ReloadMorphicCommunityBarError?) -> Void) {
        guard let user = Session.shared.user else {
            completion(false, .noUserSpecified)
            return
        }

        // capture a list of the user's communities
        Session.shared.downloadAndSaveMorphicUserCommunities(user: user) {
            success in
            
            if success == false {
                completion(false, .networkOrAuthorizationOrSaveToDiskFailure)
                return
            }
            
            // capture our list of now-saved morphic user communities
            guard let communityBarsAsJson = Session.shared.dictionary(for: .morphicBarCommunityBarsAsJson) else {
                completion(false, .networkOrAuthorizationOrSaveToDiskFailure)
                return
            }
            
            // if the user has no communities, return that error as a failure
            if communityBarsAsJson.count == 0 {
                completion(false, .userHasNoCommunities)
                return
            }
 
            // determine if the user's previously-selected community still exists; if not, choose another community
            var userSelectedCommunityId = UserDefaults.morphic.selectedUserCommunityId(for: user.identifier)

            if userSelectedCommunityId == nil || communityBarsAsJson[userSelectedCommunityId!] == nil {
                // the user has left the previous community; choose the first community bar instead (and save our change)
                userSelectedCommunityId = communityBarsAsJson.keys.first!
                UserDefaults.morphic.set(selectedUserCommunityIdentifier: userSelectedCommunityId, for: user.identifier)
            }

            // now it's time to update the morphic bar
            self.morphicBarWindow?.updateMorphicBar()
            
            completion(true, nil)
        }
    }

        
    // MARK: - Actions
    
    @IBAction
    func logout(_ sender: Any?) {
        Session.shared.signout {
            #if EDITION_BASIC
            #else
//            #elseif EDITION_COMMUNITY
                Session.shared.set([], for: .morphicBarItems)
                Session.shared.savePreferencesToDisk() {
                    success in
                    if success == true {
                        // now it's time to update/show the morphic bar
                        self.morphicBarWindow?.updateMorphicBar()
                        self.hideMorphicBar(nil)
                    }
                }
            #endif
            
            #if EDITION_BASIC
            #else
//            #elseif EDITION_COMMUNITY
                self.loginMenuItem?.isHidden = false
            #endif
            self.logoutMenuItem?.isHidden = true
        }
    }
    
    @IBAction
    func reapplyAllSettings(_ sender: Any) {
        Session.shared.open {
            os_log(.info, "Re-applying all settings")
            Session.shared.applyAllPreferences {
                
            }
        }
    }
    
    @IBAction
    func captureAllSettings(_ sender: Any) {
        let prefs = Preferences(identifier: "")
        let capture = CaptureSession(settingsManager: Session.shared.settings, preferences: prefs)
        capture.captureDefaultValues = true
        capture.addAllSolutions()
        capture.run {
            for pair in capture.preferences.keyValueTuples(){
                print(pair.0, pair.1 ?? "<nil>")
            }
        }
    }
    
    @IBAction func showAboutBox(_ sender: NSMenuItem) {
        let aboutBoxWindowController = AboutBoxWindowController.single
        if aboutBoxWindowController.window?.isVisible == false {
            aboutBoxWindowController.centerOnScreen()
        }
        
        aboutBoxWindowController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Default Preferences
    
    func createEmptyDefaultPreferencesIfNotExist(completion: @escaping () -> Void) {
        let prefs = Preferences(identifier: "__default__")
        guard !Session.shared.storage.contains(identifier: prefs.identifier, type: Preferences.self) else {
            completion()
            return
        }
        Session.shared.storage.save(record: prefs) {
            success in
            if !success {
                os_log(.error, log: logger, "Failed to save default preferences")
            }
            completion()
        }
    }
     
    func loadInitialDefaultPreferences() {
        // load our initial default preferences
        var initialPrefs = Preferences(identifier: "__initial__")
        
        guard let url = Bundle.main.url(forResource: "DefaultPreferences", withExtension: "json") else {
            os_log(.error, log: logger, "Failed to find default preferences")
            return
        }
        guard let json = FileManager.default.contents(atPath: url.path) else {
            os_log(.error, log: logger, "Failed to read default preferences")
            return
        }
        do {
            let decoder = JSONDecoder()
            initialPrefs.defaults = try decoder.decode(Preferences.PreferencesSet.self, from: json)
        } catch {
            os_log(.error, log: logger, "Failed to decode default preferences")
            return
        }
        
        Session.initialPreferences = initialPrefs
    }
   
    // MARK: - Solutions
    
    func populateSolutions() {
        Session.shared.settings.populateSolutions(fromResource: "macos.solutions")
    }
     
    // MARK: - Status Bar Item

    /// The item that shows in the macOS menu bar
    var statusItem: NSStatusItem!
     
    /// Create our `statusItem` for the macOS menu bar
    ///
    /// Should be called during application launch
    func createStatusItem() {
        os_log(.info, log: logger, "Creating status item")
        statusItem = NSStatusBar.system.statusItem(withLength: -1)
        statusItem.menu = menu
        
        // update the menu to match the proper edition of Morphic
        updateMenu()
        
        let buttonImage = NSImage(named: "MenuIconBlack")
        buttonImage?.isTemplate = true
        statusItem.button?.image = buttonImage
    }
    
    private func updateMenu() {
        #if EDITION_BASIC
            // NOTE: the default menu items are already configured for Morphic Basic
        #else
//        #elseif EDITION_COMMUNITY
            // configure menu items to match the Morphic Community scheme
            captureMenuItem?.isHidden = true
            loginMenuItem?.title = "Sign In..."
            logoutMenuItem?.title = "Sign Out"
        #endif
    }
     
    // MARK: - MorphicBar
     
    /// The window controller for the MorphicBar that is shown by clicking on the `statusItem`
    var morphicBarWindow: MorphicBarWindow?
     
    /// Show or hide the MorphicBar
    ///
    /// - parameter sender: The UI element that caused this action to be invoked
    @IBAction
    func toggleMorphicBar(_ sender: Any?) {
        if morphicBarWindow != nil {
            hideMorphicBar(nil)
        } else {
            showMorphicBar(nil)
        }
    }
    
    @IBAction
    func showMorphicBar(_ sender: Any?) {
        if morphicBarWindow == nil {
            morphicBarWindow = MorphicBarWindow()
        #if EDITION_BASIC
            morphicBarWindow?.orientation = .horizontal
        #else
//        #elseif EDITION_COMMUNITY
            morphicBarWindow?.orientation = .vertical
        #endif
            morphicBarWindow?.delegate = self
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        morphicBarWindow?.makeKeyAndOrderFront(nil)
        showMorphicBarMenuItem?.isHidden = true
        hideMorphicBarMenuItem?.isHidden = false
        if sender != nil {
            Session.shared.set(true, for: .morphicBarVisible)
        }
    }
    
    @IBAction
    func hideMorphicBar(_ sender: Any?) {
        morphicBarWindow?.close()
        #if EDITION_BASIC
            showMorphicBarMenuItem?.isHidden = false
        #else
//        #elseif EDITION_COMMUNITY
            if Session.shared.user != nil {
                showMorphicBarMenuItem?.isHidden = false
            } else {
                showMorphicBarMenuItem?.isHidden = true
            }
        #endif
        hideMorphicBarMenuItem?.isHidden = true
        QuickHelpWindow.hide()
        if sender != nil {
            Session.shared.set(false, for: .morphicBarVisible)
        }
    }
     
    func windowDidBecomeKey(_ notification: Notification) {
    }
     
    func windowDidResignKey(_ notification: Notification) {
    }
     
    func windowWillClose(_ notification: Notification) {
        morphicBarWindow = nil
    }
    
    func windowDidChangeScreen(_ notification: Notification) {
        morphicBarWindow?.reposition(animated: false)
    }
     
    // MARK: - Configurator App
    
    @IBAction
    func launchCapture(_ sender: Any?) {
        launchConfigurator(argument: "capture")
    }
    
    @IBAction
    func launchLogin(_ sender: Any?) {
        launchConfigurator(argument: "login")
    }
    
    func launchConfigurator(argument: String) {
//        let url = URL(string: "morphicconfig:\(argument)")!
//        NSWorkspace.shared.open(url)
        os_log(.info, log: logger, "launching configurator")
        guard let url = Bundle.main.resourceURL?.deletingLastPathComponent().appendingPathComponent("Library").appendingPathComponent("MorphicConfigurator.app") else {
            os_log(.error, log: logger, "Failed to construct bundled configurator app URL")
            return
        }
        MorphicProcess.openProcess(at: url, arguments: [argument], activate: true, hide: false) {
            (app, error) in
            guard error == nil else {
                os_log(.error, log: logger, "Failed to launch configurator: %{public}s", error!.localizedDescription)
                return
            }
        }
    }

}
