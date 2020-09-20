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
    @IBOutlet weak var selectCommunityMenuItem: NSMenuItem!
    
    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        os_log(.info, log: logger, "applicationDidFinishLaunching")
        AppDelegate.shared = self
        
        // before we open any storage or use UserDefaults, set up our ApplicationSupport path and UserDefaults suiteName
        #if EDITION_BASIC
            Storage.setApplicationSupportDirectoryName("org.raisingthefloor.MorphicBasic")
            UserDefaults.setMorphicSuiteName("org.raisingthefloor.MorphicBasic")
        #elseif EDITION_COMMUNITY
            Storage.setApplicationSupportDirectoryName("org.raisingthefloor.MorphicCommunity")
            UserDefaults.setMorphicSuiteName("org.raisingthefloor.MorphicCommunity")
        #endif

        // set up options for the current edition of Morphic
        #if EDITION_BASIC
            Session.shared.isCaptureAndApplyEnabled = true
            Session.shared.isServerPreferencesSyncEnabled = true
        #elseif EDITION_COMMUNITY
            Session.shared.isCaptureAndApplyEnabled = false
            Session.shared.isServerPreferencesSyncEnabled = false
        #endif

        os_log(.info, log: logger, "opening morphic session...")
        populateSolutions()
        createStatusItem()
        loadInitialDefaultPreferences()
        createEmptyDefaultPreferencesIfNotExist {
            Session.shared.open {
                os_log(.info, log: logger, "session open")
                #if EDITION_BASIC
                #elseif EDITION_COMMUNITY
                    if Session.shared.user == nil {
                        self.showMorphicBarMenuItem?.isHidden = true
                    }
                #endif
                #if EDITION_BASIC
                #elseif EDITION_COMMUNITY
                    self.loginMenuItem?.isHidden = (Session.shared.user != nil)
                #endif
                self.logoutMenuItem?.isHidden = (Session.shared.user == nil)
                #if EDITION_BASIC
                    if Session.shared.bool(for: .morphicBarVisible) ?? true {
                        self.showMorphicBar(nil)
                    }
                #elseif EDITION_COMMUNITY
                    if Session.shared.user != nil && Session.shared.bool(for: .morphicBarVisible) ?? true {
                        self.showMorphicBar(nil)
                    }
                #endif
                if Session.shared.user != nil {
                    #if EDITION_BASIC
                    #elseif EDITION_COMMUNITY
                        // reload the community bar
                        self.reloadMorphicCommunityBar() {
                            success, error in
                            
                            if error == .userHasNoCommunities {
                                // if the user has no communities, log them back out
                                self.logout(nil)
                            }
                        }
                        // schedule daily refreshes of the Morphic community bars
                        self.scheduleNextDailyMorphicCommunityBarRefresh()
                    #endif
                }
                DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.userDidSignin), name: .morphicSignin, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.sessionUserDidChange(_:)), name: .morphicSessionUserDidChange, object: Session.shared)

                #if EDITION_BASIC
                #elseif EDITION_COMMUNITY
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
            #elseif EDITION_COMMUNITY
            #endif
        }
    }
    
    @objc
    func sessionUserDidChange(_ notification: NSNotification) {
        guard let session = notification.object as? Session else {
            return
        }
        #if EDITION_BASIC
        #elseif EDITION_COMMUNITY
            self.loginMenuItem?.isHidden = (session.user != nil)
        #endif
        self.logoutMenuItem?.isHidden = (session.user == nil)
        
        #if EDITION_BASIC
        #elseif EDITION_COMMUNITY
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
    
    // NOTE: we maintain a reference to the timer so that we can cancel (invalidate) it, reschedule it, etc.
    var dailyCommunityBarRefreshTimer: Timer? = nil
    func scheduleNextDailyMorphicCommunityBarRefresh() {
        // NOTE: we schedule a community bar reload for 3am every morning local time (+ random 0..<3600 second offset to minimize server peak loads) so that the user gets the latest community bar updates; if their computer is sleeping at 3am then Swift should execute the timer when their computer wakes up
        
        let secondsInOneDay = 24 * 60 * 60
        
        let randomOffsetInSeconds = Int.random(in: 0..<3600)
        // create a date which represents today at our requested reload time
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .second], from: Date())
        dateComponents.hour = 3
        dateComponents.minute = 0
        dateComponents.second = 0
        // convert these date components to a date
        let todayReloadDate = Calendar.current.date(from: dateComponents)!
        // add our random number of seconds
        let todayReloadDateWithRandomOffset = Date(timeInterval: TimeInterval(randomOffsetInSeconds), since: todayReloadDate)
        // add one day to our date (to reflect tomorrow morning)
        let nextRefreshDate: Date
        if todayReloadDateWithRandomOffset > Date(timeInterval: TimeInterval(0), since: Date()) {
            // if the reload date is in the future today (i.e. if the current time is before the firing time), then fire today
            nextRefreshDate = todayReloadDateWithRandomOffset
        } else {
            // if the reload date was earlier today, then fire tomorrow instead
            nextRefreshDate = Date(timeInterval: TimeInterval(secondsInOneDay), since: todayReloadDateWithRandomOffset)
        }
        
        // NOTE: in our initial testing, macOS does _not_ reliably fire timers after the user's computer wakes up from sleep mode (if the timer was supposed to go off while the computer was sleeping).  So as a workaround we ask the timer to fire every 15 seconds AFTER that time as well; when the timer is fired we disable and reconfigure it to fire again the following day.
        dailyCommunityBarRefreshTimer = Timer(fire: nextRefreshDate, interval: TimeInterval(15), repeats: true) { (timer) in
            // deactivate our timer
            self.dailyCommunityBarRefreshTimer?.invalidate()
            
            // reload the Morphic bar
            self.reloadMorphicCommunityBar { (success, error) in
                // ignore results
            }

            // reschedule our timer for the next day as well
            self.scheduleNextDailyMorphicCommunityBarRefresh()
        }
        RunLoop.main.add(dailyCommunityBarRefreshTimer!, forMode: .common)
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

            // capture our list of now-cached morphic user communities
            guard let communityBarsAsJson = Session.shared.dictionary(for: .morphicBarCommunityBarsAsJson) else {
                completion(false, .networkOrAuthorizationOrSaveToDiskFailure)
                return
            }
            
            // if the user has no communities, return that error as a failure
            if communityBarsAsJson.count == 0 {
                // NOTE: we do not clear out any previous "selected community" the user had specified; this preserves their "last chosen community"; if desired we could erase the default here
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

            // update our list of communities (after any community re-selection has been done)
            self.updateSelectCommunityMenuItem(selectCommunityMenuItem: self.selectCommunityMenuItem)
            if let morphicBarWindow = self.morphicBarWindow {
                self.updateSelectCommunityMenuItem(selectCommunityMenuItem: morphicBarWindow.morphicBarViewController.selectCommunityMenuItem)
            }

            // now it's time to update the morphic bar
            self.morphicBarWindow?.updateMorphicBar()
            
            completion(true, nil)
        }
    }
    
    func updateSelectCommunityMenuItem(selectCommunityMenuItem: NSMenuItem) {
        guard let user = Session.shared.user else {
            selectCommunityMenuItem.isHidden = true
            return
        }
        selectCommunityMenuItem.isHidden = false
        
        // capture our current-selected community id
        let userSelectedCommunityId = UserDefaults.morphic.selectedUserCommunityId(for: user.identifier)
        
        // get a sorted array of our community ids and names (sorted by name first, then by id)
        guard let userCommunityIdsAndNames = createSortedArrayOfCommunityIdsAndNames() else {
            return
        }
        
        // now populate the menu with the community names...and highlight the currently-selected community (9)with a checkmark)
        selectCommunityMenuItem.submenu?.removeAllItems()
        for userCommunityIdAndName in userCommunityIdsAndNames {
            let communityMenuItem = NSMenuItem(title: userCommunityIdAndName.name, action: #selector(AppDelegate.communitySelected), keyEquivalent: "")
            if userCommunityIdAndName.id == userSelectedCommunityId {
                communityMenuItem.state = .on
            }
            // NOTE: we tag each menu item with its id's hashValue (which is only stable during the same run of the program); we do this to help disambiguate multiple communities with the same name
            communityMenuItem.tag = userCommunityIdAndName.id.hashValue
            selectCommunityMenuItem.submenu?.addItem(communityMenuItem)
        }
    }
    
    func createSortedArrayOfCommunityIdsAndNames() -> [(id: String, name: String)]? {
        // capture our list of cached morphic user communities
        guard let communityBarsAsJson = Session.shared.dictionary(for: .morphicBarCommunityBarsAsJson) as? [String: String] else {
            return nil
        }
        
        // populate a dictionary of community ids and names
        var userCommunityIdsAndNames: [(id: String, name: String)] = []
        for (communityId, communityBarAsJsonString) in communityBarsAsJson {
            let communityBarAsJsonData = communityBarAsJsonString.data(using: .utf8)!
            let communityBar = try! JSONDecoder().decode(Service.UserCommunityDetails.self, from: communityBarAsJsonData)
            
            let communityName = communityBar.name
            userCommunityIdsAndNames.append((communityId, communityName))
        }
        
        // sort the communities by name (and then secondarily by id, in case two have the same name)
        userCommunityIdsAndNames.sort { (arg0: (id: String, name: String), arg1: (id: String, name: String)) -> Bool in
            if arg0.name.lowercased() < arg1.name.lowercased() {
                return true
            } else if arg0.name.lowercased() == arg1.name.lowercased() {
                if arg0.id.lowercased() < arg1.id.lowercased() {
                    return true
                }
            }
            
            return false
        }

        return userCommunityIdsAndNames
    }
    
    @objc
    func communitySelected(_ sender: NSMenuItem) {
        guard let user = Session.shared.user else {
            return
        }
        
        // save the newly-selected community id
        
        let communityName = sender.title
        let communityIdHashValue = sender.tag
        
        // get a sorted array of our community ids and names (sorted by name first, then by id)
        guard let userCommunityIdsAndNames = createSortedArrayOfCommunityIdsAndNames() else {
            return
        }

        // calculate the community id of the selected community
        var selectedCommunityIdAndName = userCommunityIdsAndNames.first { (arg0) -> Bool in
            if arg0.id.hashValue == communityIdHashValue {
                return true
            } else {
                return false
            }
        }
        
        // if the selected community's tag doesn't match the name (i.e. there are multiple entries with the same name)
        if selectedCommunityIdAndName == nil || (selectedCommunityIdAndName!.name != communityName) {
            // if the hash value didn't work (which shouldn't be possible), gracefully degrade by finding the first entry with this name
            selectedCommunityIdAndName = userCommunityIdsAndNames.first { (arg0) -> Bool in
                if arg0.name == communityName {
                    return true
                } else {
                    return false
                }
            }
        }
        
        // if we still didn't get an entry, then fail
        guard selectedCommunityIdAndName != nil else {
            NSLog("User selected a community which cannot be found")
            return
        }

        // save the newly-selected community id
        UserDefaults.morphic.set(selectedUserCommunityIdentifier: selectedCommunityIdAndName!.id, for: user.identifier)

        // update our list of communities (so that we move the checkbox to the appropriate entry)
        self.updateSelectCommunityMenuItem(selectCommunityMenuItem: self.selectCommunityMenuItem)
        if let morphicBarWindow = morphicBarWindow {
            self.updateSelectCommunityMenuItem(selectCommunityMenuItem: morphicBarWindow.morphicBarViewController.selectCommunityMenuItem)
        }
        
        // now that the user has selected a new community bar, we switch to it using our cached data
        self.morphicBarWindow?.updateMorphicBar()

        // optionally, we can reload the data (asynchronously)
        reloadMorphicCommunityBar { (success, error) in
            // ignore callback
        }
        
        // finally, for good user experience, show the MorphicBar if it's not already shown
        if morphicBarWindow == nil || morphicBarWindow!.isVisible == false {
            // NOTE: we pass in showMorphicBarMenuItem as the parameter to emulate that it was pressed (so the setting is captured)
            self.showMorphicBar(showMorphicBarMenuItem)
        }
    }
    
    // MARK: - Actions
    
    @IBAction
    func logout(_ sender: Any?) {
        Session.shared.signout {
            #if EDITION_BASIC
            #elseif EDITION_COMMUNITY
                // flush out any preferences changes that may have taken effect because of logout
                Session.shared.savePreferences(waitFiveSecondsBeforeSave: false) {
                    success in
                    if success == true {
                        // now it's time to update and hide the morphic bar
                        self.morphicBarWindow?.updateMorphicBar()
                        self.hideMorphicBar(nil)
                    } else {
                        // NOTE: we may want to consider letting the user know that we could not save
                    }
                }
            #endif
            
            #if EDITION_BASIC
            #elseif EDITION_COMMUNITY
                self.loginMenuItem?.isHidden = false
                self.selectCommunityMenuItem.isHidden = true
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
    
    @IBAction func quitApplication(_ sender: Any) {
        // immediately hide our MorphicBar window
        morphicBarWindow?.setIsVisible(false)
        
        if Session.shared.preferencesSaveIsQueued == true {
            var saveIsComplete = false
            Session.shared.savePreferences(waitFiveSecondsBeforeSave: false) {
                _ in
                
                saveIsComplete = true
            }
            // wait up to 5 seconds for save of our preferences to complete, then shut down
            AsyncUtils.wait(atMost: TimeInterval(5), for: { saveIsComplete == true }) {
                _ in
                
                // shut down regardless of whether the save completed in two seconds or not; it should have saved within milliseconds...and we don't have any guards around apps terminating mid-save in any scenarios
                NSApplication.shared.terminate(self)
            }
        } else {
            // shut down immediately
            NSApplication.shared.terminate(self)
        }
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
        #elseif EDITION_COMMUNITY
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
        #elseif EDITION_COMMUNITY
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
        #elseif EDITION_COMMUNITY
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
    
    //
    
    @IBAction
    func learnAboutMorphicClicked(_ sender: NSMenuItem?) {
        let url = URL(string: "https://morphic.org")!
        NSWorkspace.shared.open(url)
    }

    @IBAction
    func quickDemoMoviesClicked(_ sender: NSMenuItem?) {
        let url = URL(string: "https://morphic.org/movies/main")!
        NSWorkspace.shared.open(url)
    }

    @IBAction
    func otherHelpfulThingsClicked(_ sender: NSMenuItem?) {
        let url = URL(string: "https://morphic.org/helpful")!
        NSWorkspace.shared.open(url)
    }

    //

    @IBAction
    func launchAllAccessibilityOptionsSettings(_ sender: Any?) {
        SettingsLinkActions.openSystemPreferencesPane(.accessibilityOverview)
    }
    
    @IBAction
    func launchColorVisionSettings(_ sender: Any?) {
        SettingsLinkActions.openSystemPreferencesPane(.accessibilityDisplayColorFilters)
    }
    
    @IBAction
    func launchContrastSettings(_ sender: Any?) {
        SettingsLinkActions.openSystemPreferencesPane(.accessibilityDisplayDisplay)
    }
    
    @IBAction
    func launchDarkModeSettings(_ sender: Any?) {
        SettingsLinkActions.openSystemPreferencesPane(.general)
    }

    @IBAction
    func launchMagnifierSettings(_ sender: Any?) {
        SettingsLinkActions.openSystemPreferencesPane(.accessibilityZoom)
    }

    @IBAction
    func launchNightModeSettings(_ sender: Any?) {
        SettingsLinkActions.openSystemPreferencesPane(.displaysNightShift)
    }
    
    @IBAction
    func launchReadAloudSettings(_ sender: Any?) {
        SettingsLinkActions.openSystemPreferencesPane(.accessibilitySpeech)
    }

    // TODO: this is a temporary function assigned to unimplemented menu buttons (so that they don't appear in gray); remove it once items are implemented
    @IBAction
    func handleUnimplementedMenuItem(_ sender: Any?) {
        // do nothing
    }
    
    // TODO: this is a temporary function assigned to unimplemented checkbox menu buttons (so that they don't appear in gray); remove it once items are implemented
    @IBAction
    func handleUnimplementedCheckboxMenuItem(_ sender: NSMenuItem) {
        // for now, just toggle the checkbox
        sender.state = (sender.state == .on) ? .off : .on
    }
    
    //

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
        
        #if EDITION_BASIC
            let morphicConfiguratorAppName = "MorphicConfigurator.app"
        #elseif EDITION_COMMUNITY
            let morphicConfiguratorAppName = "MorphicCommunityConfigurator.app"
        #endif
        guard let url = Bundle.main.resourceURL?.deletingLastPathComponent().appendingPathComponent("Library").appendingPathComponent(morphicConfiguratorAppName) else {
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
