// Copyright 2020-2021 Raising the Floor - International
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
import Countly
import OSLog
import MorphicCore
import MorphicService
import MorphicSettings
import ServiceManagement

private let logger = OSLog(subsystem: "app", category: "delegate")

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    
    static var shared: AppDelegate!
    
    @IBOutlet var mainMenu: NSMenu!
    @IBOutlet weak var showMorphicBarMenuItem: NSMenuItem?
    @IBOutlet weak var hideMorphicBarMenuItem: NSMenuItem?
    @IBOutlet weak var copySettingsBetweenComputersMenuItem: NSMenuItem!
    @IBOutlet weak var loginMenuItem: NSMenuItem!
    @IBOutlet weak var logoutMenuItem: NSMenuItem?
    @IBOutlet weak var selectMorphicBarMenuItem: NSMenuItem!
    
    @IBOutlet weak var automaticallyStartMorphicAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var showMorphicBarAtStartMenuItem: NSMenuItem!
    @IBOutlet weak var hideQuickHelpMenuItem: NSMenuItem!

    @IBOutlet weak var turnOffKeyRepeatMenuItem: NSMenuItem!
    
    @IBOutlet weak var selectBasicMorphicBarMenuItem: NSMenuItem!
    
    private var voiceOverEnabledObservation: NSKeyValueObservation?
    private var appleKeyboardUIModeObservation: NSKeyValueObservation?

    private let appCastUrl: URL = {
        guard let frontEndUrlAsString = Bundle.main.infoDictionary?["FrontEndURL"] as? String else {
            fatalError("FRONT_END_URL (mandatory) not set in .xcconfig")
        }
        guard let autoupdateXmlFilename = Bundle.main.infoDictionary?["AutoupdateXmlFilename"] as? String else {
            fatalError("AUTOUPDATE_XML_FILENAME (mandatory) not set in .xcconfig")
        }
        return URL(string: frontEndUrlAsString)!.appendingPathComponent("autoupdate").appendingPathComponent(autoupdateXmlFilename)
    }()

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        os_log(.info, log: logger, "applicationDidFinishLaunching")
        AppDelegate.shared = self

        // watch for notifications that the user attempted to relaunch Morphic
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.showMorphicBarDueToApplicationRelaunch(_:)), name: .showMorphicBarDueToUserRelaunch, object: nil)

        // NOTE: if desired, we could call morphicLauncherIsRunning() to detect if we were auto-started by our launch item (and capture that on startup); this would (generally) confirm that "autostart Morphic on login" is enabled without having to use deprecated SMJob functions
        //
        // terminate Morphic Launcher if it is already running
        terminateMorphicLauncherIfRunning()

        // before we open any storage or use UserDefaults, set up our ApplicationSupport path and UserDefaults suiteName
        Storage.setApplicationSupportDirectoryName("org.raisingthefloor.MorphicBasic")
        UserDefaults.setMorphicSuiteName("org.raisingthefloor.MorphicBasic")

        // determine if telemetry should be enabled
        let telemetryShouldBeDisabled = self.shouldTelemetryBeDisabled()
        let telemetryIsEnabled = (telemetryShouldBeDisabled == false)
        
        // capture the common configuration (if one is present)
        let commonConfiguration = self.getCommonConfiguration()
        ConfigurableFeatures.shared.morphicBarVisibilityAfterLogin = commonConfiguration.morphicBarVisibilityAfterLogin
        ConfigurableFeatures.shared.morphicBarExtraItems = commonConfiguration.extraMorphicBarItems
        ConfigurableFeatures.shared.autorunConfig = commonConfiguration.autorunConfig
        ConfigurableFeatures.shared.checkForUpdatesIsEnabled = commonConfiguration.checkForUpdatesIsEnabled
        ConfigurableFeatures.shared.resetSettingsIsEnabled = commonConfiguration.resetSettingsIsEnabled
        ConfigurableFeatures.shared.telemetryIsEnabled = telemetryIsEnabled
        Session.shared.isCaptureAndApplyEnabled = commonConfiguration.cloudSettingsTransferIsEnabled
        Session.shared.isServerPreferencesSyncEnabled = true
        ConfigurableFeatures.shared.telemetrySiteId = commonConfiguration.telemetrySiteId

        if ConfigurableFeatures.shared.telemetryIsEnabled == true {
            self.configureCountly()
        }
        
        #if DEBUG
            // do not run the auto-updater checks in debug mode
        #else
            if ConfigurableFeatures.shared.checkForUpdatesIsEnabled == true {
                Autoupdater.startCheckingForUpdates(url: self.appCastUrl)
            }
        #endif

        os_log(.info, log: logger, "opening morphic session...")
        populateSolutions()
        createStatusItem()
        loadInitialDefaultPreferences()
        createEmptyDefaultPreferencesIfNotExist {
            Session.shared.open {
                os_log(.info, log: logger, "session open")
                
                if ConfigurableFeatures.shared.resetSettingsIsEnabled == true {
                    self.resetSettings()
                }

                self.copySettingsBetweenComputersMenuItem?.isHidden = (Session.shared.isCaptureAndApplyEnabled == false)
                
                self.loginMenuItem?.isHidden = (Session.shared.user != nil)
                self.logoutMenuItem?.isHidden = (Session.shared.user == nil)

                self.mainMenu?.delegate = self
                
                // update our list of custom MorphicBars
                self.updateSelectMorphicBarMenuItem()

                // show the Morphic Bar (if we have a bar to show and it's (a) our first startup or (b) the user had the bar showing when the app was last exited or (c) the user has "show MorphicBar at start" set to true
                var showMorphicBar: Bool = false
                switch ConfigurableFeatures.shared.morphicBarVisibilityAfterLogin {
                case .show:
                    showMorphicBar = true
                case .hide:
                    showMorphicBar = false
                case .restore,
                     nil: // restore is the default setting
                    // capture the user's preference as to whether or not to show the Morphic Bar at startup
                    // showMorphicBarAtStart: true if we should always try to show the MorphicBar at application startup
                    let showMorphicBarAtStart = Session.shared.bool(for: .showMorphicBarAtStart) ?? false
                    if showMorphicBarAtStart == true {
                        showMorphicBar = true
                    } else {
                        // if the bar has not been shown before, show it now; if it has been shown/hidden before, use the last known visibility state
                        // NOTE: morphicBarVisible is true if the MorphicBar was visible when we last exited the application
                        showMorphicBar = Session.shared.bool(for: .morphicBarVisible) ?? true
                    }
                }
                //
                if showMorphicBar == true {
                    self.showMorphicBar(nil)
                }
                
                // update the "hide quickhelp menu" menu item's state
                self.updateHideQuickHelpMenuItems()
                
                // update the "show MorphicBar at start" menu items' states
                self.updateShowMorphicBarAtStartMenuItems()
                
                // update the "turn off key repeat" menu items' states
                self.updateTurnOffKeyRepeatMenuItems()

                // capture the current state of our launch items (in the corresponding menu items)
                // NOTE: we must not do this until after we have set up UserDefaults.morphic (if we use UserDefaults.morphic to store/capture this state); we may also consider using the running state of MorphicLauncher (when we first start up) as a heuristic to know that autostart is enabled for our application (or we may consider passing in an argument via the launcher which indicates that we were auto-started)
                self.updateMorphicAutostartAtLoginMenuItems()

                // if we receive the "show MorphicBar" notification (from the dock app) then call our showMorphicBarNotify function
                DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.showMorphicBarDueToDockAppActivation), name: .showMorphicBarDueToDockAppActivation, object: nil)
                //
                // if the dock icon is closed by the user, that should shut down the rest of Morphic too
                DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.terminateMorphicClientDueToDockAppTermination), name: .terminateMorphicClientDueToDockAppTermination, object: nil)
                //
                // if keyboard navigation or voiceover is enabled, start up our dock app now
                if self.shouldDockAppBeRunning() == true {
                    self.launchDockAppIfNotRunning()
                }
                //
                // wire up our events to start up and shut down the dock app when VoiceOver or FullKeyboardAccess are enabled/disabled
                // NOTE: possibly due to the "agent" status of our application, the voiceover disabled and keyboard navigation enabled/disabled events are not always provided to us in real time (i.e. we may need to re-receive focus to receive the events); in the future we may want to consider polling for these or otherwise determining what is keeping us from capturing these events (with that something possibly being a "can hibernate app in background" kind of macOS app setting)
                self.voiceOverEnabledObservation = NSWorkspace.shared.observe(\.isVoiceOverEnabled, options: [.new], changeHandler: self.voiceOverEnabledChangeHandler)
                self.appleKeyboardUIModeObservation = UserDefaults.standard.observe(\.AppleKeyboardUIMode, options: [.new], changeHandler: self.appleKeyboardUIModeChangeHandler)

                if Session.shared.user != nil {
                    // reload custom MorphicBars
                    self.reloadCustomMorphicBars() {
                        success, error in
                    }
                    // schedule daily refreshes of the Morphic community bars
                    self.scheduleNextDailyMorphicCustomMorphicBarsRefresh()
                }
                DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.userDidSignin), name: .morphicSignin, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.sessionUserDidChange(_:)), name: .morphicSessionUserDidChange, object: Session.shared)
                NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.permissionsPopupFired(_:)), name: .morphicPermissionsPopup, object: nil)

                // TODO: if this is the first launch of Morphic, show the welcome screen (offering to sign the user into their Morphic account!)

                switch ConfigurableFeatures.shared.autorunConfig {
                case nil:
                    // if this is our first run and autorunAfterLogin is not configured via config.json, configure the system to autorun Morphic after login
                    // NOTE: consider moving this logic to the first time that a bar is shown (so that we don't re-prompt users to log in when their computer turns on if they're logged out...unless they've already logged in at least once)
                    let didSetInitialAutorunAfterLoginEnabled = Session.shared.bool(for: .morphicDidSetInitialAutorunAfterLoginEnabled) ?? false
                    if didSetInitialAutorunAfterLoginEnabled == false {
                        self.setInitialAutorunAfterLoginEnabled()
                    }
                case .currentUser:
                    _ = self.setMorphicAutostartAtLogin(true)
                case .allLocalUsers,
                     .disabled:
                    // if autorunAfterLogin is set to "disabled" or to "allLocalUsers", we should _not_ launch Morphic via MorphicLauncher (i.e. not using SMLoginItemSetEnabled); if the administrator wants to run Morphic automatically after login system-wide (all users), they should configure Morphic as a global Launch Item.
                    _ = self.setMorphicAutostartAtLogin(false)
                }
                
                // if the user has already configured settings which we set defaults for, make sure we don't change those settings
                self.markUserConfiguredSettingsAsAlreadySet()
            }
        }
    }
    
    internal func countly_RecordEvent(_ key: String) {
        if ConfigurableFeatures.shared.telemetryIsEnabled == true {
            Countly.sharedInstance().recordEvent(key)
        }
    }
    
    internal func countly_RecordEvent(_ key: String, segmentation: [String: String]?) {
        if ConfigurableFeatures.shared.telemetryIsEnabled == true {
            Countly.sharedInstance().recordEvent(key, segmentation: segmentation)
        }
    }
    
    func configureCountly() {
        guard let appKey = Bundle.main.infoDictionary?["CountlyAppKey"] as? String else {
            assertionFailure("Missing Countly app key.  Check build config files")
            os_log(.fault, log: logger, "Missing Countly app key.  Check build config files")
            return
        }
        guard let serverUrl = Bundle.main.infoDictionary?["CountlyServerUrl"] as? String else {
            assertionFailure("Missing Countly server url.  Check build config files")
            os_log(.fault, log: logger, "Missing Countly server url.  Check build config files")
            return
        }
        
        // retrieve the telemetry device ID for this device; if it doesn't exist then create a new one
        var telemetryDeviceUuid: String
        var telemetryDeviceUuidAsOptional = UserDefaults.morphic.telemetryDeviceUuid()
        if telemetryDeviceUuidAsOptional == "" {
            // if the telemetry device uuid is empty (which it should _not_ be), it's invalid...so ignore it
            telemetryDeviceUuidAsOptional = nil
        }
        //
        if let telemetryDeviceUuidAsOptional = telemetryDeviceUuidAsOptional {
            // use the existing telemetry device uuid
            telemetryDeviceUuid = telemetryDeviceUuidAsOptional
        } else {
            // create a new device uuid for purposes of telemetry
            // NOTE: GUIDs should be lowercase; macOS outputs UUIDs as uppercase; therefore we manually lowercase them
            telemetryDeviceUuid = "D_" + NSUUID().uuidString.lowercased()
            UserDefaults.morphic.set(telemetryDeviceUuid: telemetryDeviceUuid)
        }
        
        // if a site id is (or is not) configured, modify the telemetry device uuid accordingly
        // NOTE: we handle cases of site ids changing, site IDs being added post-deployment, and site IDs being removed post-deployment
        let unmodifiedTelemetryDeviceUuid = telemetryDeviceUuid
        var telemetrySiteIdAsOptional = ConfigurableFeatures.shared.telemetrySiteId
        if telemetrySiteIdAsOptional == "" {
            // if the telemetry site id is empty (white it should _not_ be), it's invalid...so ignore it
            telemetrySiteIdAsOptional = nil
        }
        //
        if let telemetrySiteId = telemetrySiteIdAsOptional {
            // NOTE: in the future, consider reporting or throwing an error if the site id required sanitization (i.e. wasn't valid)
            let sanitizedTelemetrySiteId = self.sanitizeSiteId(telemetrySiteId)
            if sanitizedTelemetrySiteId != "" {
                // we have a telemetry site id; prepend it
                telemetryDeviceUuid = self.prependSiteIdToTelemetryUuid(telemetryDeviceUuid, telemetrySiteId: telemetrySiteId)
            } else {
                // the supplied site id isn't valid; strip off the site id; In the future consider logging/reporting an error
                telemetryDeviceUuid = self.removeSiteIdFromTelemetryUuid(telemetryDeviceUuid)
            }
        } else {
            // no telemetry site id is configured; strip off any site id which might have already been part of our telemetry id
            telemetryDeviceUuid = self.removeSiteIdFromTelemetryUuid(telemetryDeviceUuid)
        }
        // if the telemetry uuid has changed (because of the site id), update our stored telemetry uuid now
        if telemetryDeviceUuid != unmodifiedTelemetryDeviceUuid {
            UserDefaults.morphic.set(telemetryDeviceUuid: telemetryDeviceUuid)
        }
        
        // TODO: there is a potential scenario that our telemetry device uuid could be (incorrectly) saved as a blank entry; we should consider
        //       how we'd want to deal with that scenario
        
        let config: CountlyConfig = CountlyConfig()
        config.appKey = appKey
        config.host = serverUrl
        if let compositeVersion = VersionUtils.compositeVersion() {
            // TODO: figure out where we pass in the appVersion on macOS
            config.customMetrics[CLYMetricKey.appVersion.rawValue] = compositeVersion
        }
        config.features = [CLYFeature.crashReporting]
        //
        #if DEBUG
        config.enableDebug = true
        #endif
        //
        // if Countly is using another telemetry ID, reset the stored device ID and specify the new telemetry ID
        // NOTE: There is also a 'setNewDeviceID' method on Countly.sharedInstance() which would let us change the session ID _after_ starting up the session...which has additional features like being able to update older records to the new telemetry ID...but this method is simpler and less error-prone for our current needs (and we can supplement our use with the function call method if needed in the future)
        if Countly.sharedInstance().deviceID() != telemetryDeviceUuid {
            // NOTE: changing the deviceID via config takes no effect if an existing "deviceID" is already in use; therefore we reset it here out of an abundance of caution (and to handle situations where we might change the "deviceID" to another telemetry ID instead)
            config.resetStoredDeviceID = true
            config.deviceID = telemetryDeviceUuid
        }
        //
        Countly.sharedInstance().start(with: config)
        Countly.sharedInstance().beginSession()
    }
    
    func prependSiteIdToTelemetryUuid(_ value: String, telemetrySiteId: String) -> String {
        var telemetryDeviceUuid = value
        
        if telemetryDeviceUuid.starts(with: "S_") {
            // if the telemetry device uuid already starts with a site id, strip it off now
            telemetryDeviceUuid.removeFirst(2)
            if let indexOfForwardSlash = telemetryDeviceUuid.firstIndex(of: "/") {
                // strip the site id off the front
                telemetryDeviceUuid = String(telemetryDeviceUuid[telemetryDeviceUuid.index(after: indexOfForwardSlash)...])
            } else {
                // the site ID was the only contents; return nil
                telemetryDeviceUuid = ""
            }
        }
        
        // prepend the site id to the telemetry device uuid
        telemetryDeviceUuid = "S_" + telemetrySiteId + "/" + telemetryDeviceUuid
        return telemetryDeviceUuid
    }
    
    func removeSiteIdFromTelemetryUuid(_ value: String) -> String {
        var telemetryDeviceUuid = value
        
        if telemetryDeviceUuid.starts(with: "S_") {
            // if the telemetry device uuid starts with a site id, strip it off now
            telemetryDeviceUuid.removeFirst(2)
            if let indexOfForwardSlash = telemetryDeviceUuid.firstIndex(of: "/") {
                // strip the site id off the front
                telemetryDeviceUuid = String(telemetryDeviceUuid[telemetryDeviceUuid.index(after: indexOfForwardSlash)...])
            } else {
                // the site ID is the only contents
                telemetryDeviceUuid = ""
            }
        }

        return telemetryDeviceUuid
    }
    
    func sanitizeSiteId(_ siteId: String) -> String {
        return siteId.filter { (character) -> Bool in
            switch character {
            case "a"..."z",
                 "A"..."Z",
                 "0"..."9":
//                 "_":
                return true
            default:
                return false
            }
        }
    }
    
    func markUserConfiguredSettingsAsAlreadySet() {
        // if the user is already using features which Morphic does one-time setup for (such as default magnifier zoom style or color filter type), make sure we don't change those settings later.  In other words: mark the settings as "already set"
        //
        // color filter
        SettingsManager.shared.capture(valueFor: .macosColorFilterEnabled) {
            value in
            if let valueAsBoolean = value as? Bool {
                // if color filters are enabled, check to see if the initial color filter type has already been set
                if valueAsBoolean == true {
                    let didSetInitialColorFilterType = Session.shared.bool(for: .morphicDidSetInitialColorFilterType) ?? false
                    if didSetInitialColorFilterType == false {
                        // since the user is already using color filters (i.e. the feature is enabled), assume that they are using the filter type they want to use and mark the initial setting as complete.
                        Session.shared.set(true, for: .morphicDidSetInitialColorFilterType)
                    }
                }
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        if ConfigurableFeatures.shared.telemetryIsEnabled == true {
            Countly.sharedInstance().endSession()
        }
    }
    
    // NOTE: this function will send our primary instance a notification request to show the Morphic Bar if the user tried to relaunch Morphic (by double-clicking the application in Finder or clicking on our icon in the dock)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NotificationCenter.default.post(name: .showMorphicBarDueToUserRelaunch, object: nil)
        return false
    }
    //
    // NOTE: this function will show the Morphic Bar if we receive a notification that the user tried to relaunch Morphic (by double-clicking the application in Finder or clicking on our icon in the dock)
    @objc
    func showMorphicBarDueToApplicationRelaunch(_ sender: Any?) {
        AppDelegate.shared.showMorphicBar(sender)
    }    

    // MARK: - Notifications
    
    @objc
    func userDidSignin(_ notification: NSNotification) {
        os_log(.info, log: logger, "Got signin notification from configurator")
        Session.shared.open {
            NotificationCenter.default.post(name: .morphicSessionUserDidChange, object: Session.shared)
            
            // TODO: previously in Morphic Basic for macOS, a user's cloud preferences were applied when they logged in; this behavior may need to be split (based on whether they're logging in to get their morphicbars...or logging in to get their preferences)
            let userInfo = notification.userInfo ?? [:]
            if !(userInfo["isRegister"] as? Bool ?? false) {
                os_log(.info, log: logger, "Is not a registration signin, applying all preferences")
                Session.shared.applyAllPreferences {
                }
            }
        }
    }
    
    func morphicDockAppIsRunning() -> Bool {
        let morphicDockAppApplications = NSWorkspace.shared.runningApplications.filter({
            application in
            switch application.bundleIdentifier {
            case "org.raisingthefloor.MorphicDockApp",
                 "org.raisingthefloor.MorphicDockApp-Debug":
                return true
            default:
                return false
            }
        })
        return (morphicDockAppApplications.count > 0)
    }
    
    func terminateDockAppIfRunning() {
        if morphicDockAppIsRunning() == true {
            DistributedNotificationCenter.default().postNotificationName(.terminateMorphicDockApp, object: nil, userInfo: nil, deliverImmediately: true)
        }
    }

    func morphicLauncherIsRunning() -> Bool {
        // if we were launched by MorphicLauncher (i.e. at startup/login), terminate MorphicLauncher if it's still running
        let morphicLauncherApplications = NSWorkspace.shared.runningApplications.filter({
            application in
            
            switch application.bundleIdentifier {
            case "org.raisingthefloor.MorphicLauncher",
                 "org.raisingthefloor.MorphicLauncher-Debug":
                return true
            default:
                return false
            }
        })
        return (morphicLauncherApplications.count > 0)
    }
    
    func terminateMorphicLauncherIfRunning() {
        if morphicLauncherIsRunning() == true {
            DistributedNotificationCenter.default().postNotificationName(.terminateMorphicLauncher, object: nil, userInfo: nil, deliverImmediately: true)
        }
    }

    func shouldDockAppBeRunning() -> Bool {
        return (NSWorkspace.shared.isVoiceOverEnabled == true) || (NSApplication.shared.isFullKeyboardAccessEnabled == true)
    }
    
    func voiceOverEnabledChangeHandler(workspace: NSWorkspace, change: NSKeyValueObservedChange<Bool>) {
        if change.newValue == true {
            launchDockAppIfNotRunning()
        } else {
            if shouldDockAppBeRunning() == false {
                terminateDockAppIfRunning()
            }
        }
    }

    func appleKeyboardUIModeChangeHandler(userDefaults: UserDefaults, change: NSKeyValueObservedChange<Int>) {
        guard let newValue = change.newValue else {
            // could not capture new value; don't change anything
            os_log(.info, log: logger, "received appleKeyboardUIMode change event, but new value was nil")
            return
        }
        
        if newValue & 2 == 2 {
            // full keyboard access was enabled
            launchDockAppIfNotRunning()
        } else {
            if shouldDockAppBeRunning() == false {
                terminateDockAppIfRunning()
            }
        }
    }

    @objc
    func sessionUserDidChange(_ notification: NSNotification) {
        guard let session = notification.object as? Session else {
            return
        }
        self.loginMenuItem?.isHidden = (session.user != nil)
        self.logoutMenuItem?.isHidden = (session.user == nil)
        
        if session.user != nil {
            // reload the community bar
            reloadCustomMorphicBars() {
                success, error in
                // NOTE: we may want to consider telling the user of the error if we can't reload the bars

                // determine if the user has a bar selected; if not, then select the first custom bar (if one is available)
                if self.currentlySelectedMorphicBarCommunityId() == nil {
                    self.selectFirstCustomBarIfAvailable()
                }
                
                // update the morphic bar (and the selected MorphicBar entry)
                self.morphicBarWindow?.updateMorphicBar()
                self.updateSelectMorphicBarMenuItem()
            }
        } else {
            // update the MorphicBar
            self.morphicBarWindow?.updateMorphicBar()
            self.updateSelectMorphicBarMenuItem()
        }
    }
    
    func currentlySelectedMorphicBarCommunityId() -> String? {
        guard let user = Session.shared.user else {
            return nil
        }
        return UserDefaults.morphic.selectedUserCommunityId(for: user.identifier)
    }

    func currentlySelectedMorphicbarId() -> String? {
        guard let user = Session.shared.user else {
            return nil
        }
        return UserDefaults.morphic.selectedMorphicbarId(for: user.identifier)
    }
    
    //
    
    internal struct MorphicBarExtraItem: Decodable {
        public let type: String?
        public let label: String?
        public let tooltipHeader: String?
        public let tooltipText: String?
        // for type: link
        public let url: String?
        // for type: action
        public let function: String?
        // for type: control
        public let feature: String?
    }
    //
    internal struct TelemetryConfigSection: Decodable {
        public let siteId: String?
    }
    internal struct ConfigFileContents: Decodable
    {
        internal struct FeaturesConfigSection: Decodable
        {
            internal struct EnabledFeature: Decodable
            {
                public let enabled: Bool?
                public let scope: String?
            }
            //
            internal let autorunAfterLogin: EnabledFeature?
            internal let checkForUpdates: EnabledFeature?
            internal let cloudSettingsTransfer: EnabledFeature?
            internal let resetSettings: EnabledFeature?
        }
        internal struct MorphicBarConfigSection: Decodable
        {
            public let visibilityAfterLogin: String?
            public let extraItems: [MorphicBarExtraItem]?
        }
        //
        public let version: Int?
        public let features: FeaturesConfigSection?
        public let morphicBar: MorphicBarConfigSection?
        public let telemetry: TelemetryConfigSection?
    }

    func shouldTelemetryBeDisabled() -> Bool {
        guard let applicationSupportPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .localDomainMask, true).first else {
            // if the application support path doesn't exist, there's definitely no file
            return false
        }
        let morphicCommonConfigPath = NSString.path(withComponents: [applicationSupportPath, "Morphic"])
        let disableTelemetryFilePath = NSString.path(withComponents: [morphicCommonConfigPath, "disable_telemetry.txt"])
        
        // if disable_telemetry.txt exists, disable telemetry
        let disableTelemetryFileExists = FileManager.default.fileExists(atPath: disableTelemetryFilePath)
        return disableTelemetryFileExists
    }
    
    struct CommonConfigurationContents {
        public var autorunConfig: ConfigurableFeatures.AutorunConfigOption? = nil
        //
        public var checkForUpdatesIsEnabled: Bool = false
        public var cloudSettingsTransferIsEnabled: Bool = false
        public var resetSettingsIsEnabled: Bool = false
        //
        public var morphicBarVisibilityAfterLogin: ConfigurableFeatures.MorphicBarVisibilityAfterLoginOption? = nil
        public var extraMorphicBarItems: [MorphicBarExtraItem] = []
        //
        public var telemetrySiteId: String? = nil
    }
    func getCommonConfiguration() -> CommonConfigurationContents {
        // set up default configuration
        var result = CommonConfigurationContents()
        //
        // autorun
        result.autorunConfig = nil
        //
        // check for updates
        result.checkForUpdatesIsEnabled = true
        //
        // copy settings to/from cloud
        result.cloudSettingsTransferIsEnabled = true
        //
        // reset settings (to standard)
        result.resetSettingsIsEnabled = false
        //
        // morphic bar (visibility and extra items)
        result.morphicBarVisibilityAfterLogin = nil
        result.extraMorphicBarItems = []
        
        guard let applicationSupportPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .localDomainMask, true).first else {
            os_log(.error, log: logger, "Could not locate system application support directory")
            assertionFailure("Could not locate system application support directory")
            return result
        }
        let morphicCommonConfigPath = NSString.path(withComponents: [applicationSupportPath, "Morphic"])
        let morphicConfigFilePath = NSString.path(withComponents: [morphicCommonConfigPath, "config.json"])
        
        if FileManager.default.fileExists(atPath: morphicConfigFilePath) == false {
            // no config file; return defaults
            return result
        }
        
        guard let json = FileManager.default.contents(atPath: morphicConfigFilePath) else {
            return result
        }

        var decodedConfigFile: ConfigFileContents
        do {
            let decoder = JSONDecoder()
            decodedConfigFile = try decoder.decode(ConfigFileContents.self, from: json)
        } catch {
            os_log(.error, log: logger, "Could not decode config.json")
            return result
        }

        guard let configFileVersion = decodedConfigFile.version else {
            // could not find a version in this file
            // NOTE: consider refusing to start up (for security reasons) if the configuration file cannot be read
            os_log(.error, log: logger, "Could not decode version from config file")
            return result
        }
        if (configFileVersion < 0) || (configFileVersion > 0) {
            // sorry, we don't understand this version of the file
            // NOTE: consider refusing to start up (for security reasons) if the configuration file cannot be read
            os_log(.error, log: logger, "Unknown config file version")
            return result
        }
        
        // capture the autorun setting
        if let configFileAutorunAfterLoginIsEnabled = decodedConfigFile.features?.autorunAfterLogin?.enabled {
            if configFileAutorunAfterLoginIsEnabled == false {
                result.autorunConfig = ConfigurableFeatures.AutorunConfigOption.disabled
            } else {
                switch decodedConfigFile.features?.autorunAfterLogin?.scope {
                case "allLocalUsers":
                    result.autorunConfig = .allLocalUsers
                    break
                case "currentUser":
                    result.autorunConfig = .currentUser
                    break
                case nil:
                    // no scope present; use the default scope
                    break
                default:
                    // sorry, we don't understand this scope setting
                    // NOTE: consider refusing to start up (for security reasons) if the configuration file cannot be read
                    os_log(.error, log: logger, "Unknown autorunAfterLogin scope")
                    return result
                }
            }
        }
        
        // capture the check for updates "is enabled" setting
        if let configFileCheckForUpdatesIsEnabled = decodedConfigFile.features?.checkForUpdates?.enabled {
            result.checkForUpdatesIsEnabled = configFileCheckForUpdatesIsEnabled
        }

        // capture the cloud settings transfer "is enabled" setting
        if let configFileCloudSettingsTransferIsEnabled = decodedConfigFile.features?.cloudSettingsTransfer?.enabled {
            result.cloudSettingsTransferIsEnabled = configFileCloudSettingsTransferIsEnabled
        }
        
        // capture the reset settings (to standard) "is enabled" setting
        if let configFileResetSettingsIsEnabled = decodedConfigFile.features?.resetSettings?.enabled {
            result.resetSettingsIsEnabled = configFileResetSettingsIsEnabled
        }

        // capture the desired after-login (autorun) visibility of the MorphicBar
        switch decodedConfigFile.morphicBar?.visibilityAfterLogin
        {
            case "restore":
                result.morphicBarVisibilityAfterLogin = .restore
            case "show":
                result.morphicBarVisibilityAfterLogin = .show
            case "hide":
                result.morphicBarVisibilityAfterLogin = .hide
            case nil:
                // no setting present; use the default setting
                break;
            default:
                // sorry, we don't understand this visibility setting
                // NOTE: consider refusing to start up (for security reasons) if the configuration file cannot be read
                os_log(.error, log: logger, "Unknown morphicBar.visibilityAfterLogin setting")
                return result
        }
        
        // capture any extra items (up to 3)
        if let configFileMorphicBarExtraItems = decodedConfigFile.morphicBar?.extraItems {
            for extraItem in configFileMorphicBarExtraItems {
                // if we already captured 3 extra items, skip this one
                if (result.extraMorphicBarItems.count >= 3)
                {
                    continue
                }

                // if the item is invalid, log the error and skip this item
                if (extraItem.type == nil) {
                    // NOTE: consider refusing to start up (for security reasons) if the configuration file cannot be read
                    os_log(.error, log: logger, "Invalid MorphicBar item")
                    continue
                }
                if (extraItem.type != "control") && ((extraItem.label == nil) || (extraItem.tooltipHeader == nil)) {
                    // NOTE: consider refusing to start up (for security reasons) if the configuration file cannot be read
                    os_log(.error, log: logger, "Invalid MorphicBar item")
                    continue
                }

                // if the "link" is missing its url, log the error and skip this item
                if (extraItem.type == "link") && (extraItem.url == nil) {
                    // NOTE: consider refusing to start up (for security reasons) if the configuration file cannot be read
                    os_log(.error, log: logger, "Invalid MorphicBar item")
                    continue
                }

                // if the "action" is missing its function, log the error and skip this item
                if (extraItem.type == "action") && (extraItem.function == nil || extraItem.function == "") {
                    // NOTE: consider refusing to start up (for security reasons) if the configuration file cannot be read
                    os_log(.error, log: logger, "Invalid MorphicBar item")
                    continue
                }
                
                // if the "control" is missing its feature, log the error and skip this item
                if (extraItem.type == "control") && (extraItem.feature == nil || extraItem.feature == "") {
                    // NOTE: consider refusing to start up (for security reasons) if the configuration file cannot be read
                    os_log(.error, log: logger, "Invalid MorphicBar item")
                    continue
                }

                let extraMorphicBarItem = MorphicBarExtraItem(
                    type: extraItem.type,
                    label: extraItem.label,
                    tooltipHeader: extraItem.tooltipHeader,
                    tooltipText: extraItem.tooltipText,
                    url: extraItem.url,
                    function: extraItem.function,
                    feature: extraItem.feature)
                result.extraMorphicBarItems.append(extraMorphicBarItem)
            }
        }
        
        // capture telemetry site id
        result.telemetrySiteId = decodedConfigFile.telemetry?.siteId
        
        return result
    }
    
    //
    
    internal func resetSettings(skipResetsWithUIAutomation: Bool = false) {
        // NOTE: we want to move these defaults to config.json, and we want to modify the solutions registry to allow _all_ settings to be specified, with defaults, in config.json.

        // default values
        let defaultColorFiltersIsEnabled = false
        let defaultDarkModeIsEnabled = false
        let defaultHighContrastIsEnabled = false
        //
        // NOTE: in the future, we should add logic to adjust by a relative %
        let defaultDisplayZoomPercentage = 1.0
        //
        let defaultNightModeIsEnabled = false

        // verify that settings are reset to their default values; if they are not, then set them now
        // NOTE: we do these in an order that makes sense during logout (i.e. we try to do as much as we can before Windows wants to close us, so we push settings like screen scaling, dark mode and high contrast to the end since they take much longer to change)

        // NOTE: ideally we should move capture and apply functions to an async/await-, promises- or Dispatch-based design.  The current design presents some risks of lockup and blocks the main thread.
        
        // NOTE: we should research why we use SettingsManager.shared for capture but Session.shared for apply.
        
        let waitTimeForSettingCompletion = TimeInterval(10) // 10 seconds max per setting
        
        // color filters
        if #available(macOS 10.15, *) {
            // we do not currently have a mechanism to report success/failure
            let currentColorFiltersIsEnabled = MorphicDisplayAccessibilitySettings.colorFiltersEnabled
            if currentColorFiltersIsEnabled != defaultColorFiltersIsEnabled {
                MorphicDisplayAccessibilitySettings.setColorFiltersEnabled(defaultColorFiltersIsEnabled)
            }
        }
        //
        // night mode
        //
        let currentNightModeIsEnabled = MorphicNightShift.getEnabled()
        if currentNightModeIsEnabled != defaultNightModeIsEnabled {
            MorphicNightShift.setEnabled(defaultNightModeIsEnabled)
        }
        //
        // screen scaling
        // NOTE: this zooms to 100% of the RECOMMENDED value, not 100% of native resolution
        if let displayCurrentPercentage = Display.main?.currentPercentage {
            if displayCurrentPercentage != defaultDisplayZoomPercentage {
                _ = try? Display.main?.zoom(to: defaultDisplayZoomPercentage)
            }
        }
        //
        // high contrast
        if skipResetsWithUIAutomation == false {
            var highContrastReset = false
            SettingsManager.shared.capture(valueFor: .macosDisplayContrastEnabled) {
                currentHighContrastIsEnabledAsInteroperable in
                guard let currentHighContrastIsEnabled = currentHighContrastIsEnabledAsInteroperable as? Bool else {
                    // could not get current setting
                    fatalError()
                }
                //
                if currentHighContrastIsEnabled != defaultHighContrastIsEnabled {
                    Session.shared.apply(defaultHighContrastIsEnabled, for: .macosDisplayContrastEnabled) {
                        success in

                        highContrastReset = true
                        
                        if success == false {
                            // we do not currently have a mechanism to report success/failure
                            NSLog("Could not set high contrast enabled state to default")
                            assertionFailure("Could not set high contrast enabled state to default")
                        }
                    }
                } else {
                    highContrastReset = true
                }
            }
            // NOTE: as there's no good way to get the get/set functions for .macosDisplayContrastEnabled onto their own background thread, and as locking up the main thread is also not ideal, and as we are not fully capturing the success/failure of set for this setting...we are just letting highContrastReset run asynchronously for now (and not blocking this thread until it completes).
//            AsyncUtils.syncWait(atMost: waitTimeForSettingCompletion, for: { highContrastReset == true })
        }
        //
        // dark mode
        let currrentAppearanceTheme = MorphicDisplayAppearance.currentAppearanceTheme
        let defaultAppearanceTheme: MorphicDisplayAppearance.AppearanceTheme = defaultDarkModeIsEnabled ? .dark : .light
        if currrentAppearanceTheme != defaultAppearanceTheme {
            MorphicDisplayAppearance.setCurrentAppearanceTheme(defaultAppearanceTheme)
        }
    }
    
    //
    
    @objc
    func permissionsPopupFired(_ notification: NSNotification) {
        PermissionsGuidanceSystem.startNew()
    }
    
    //
    
    // NOTE: we maintain a reference to the timer so that we can cancel (invalidate) it, reschedule it, etc.
    var dailyCustomMorphicBarsRefreshTimer: Timer? = nil
    func scheduleNextDailyMorphicCustomMorphicBarsRefresh() {
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
        dailyCustomMorphicBarsRefreshTimer = Timer(fire: nextRefreshDate, interval: TimeInterval(15), repeats: true) { (timer) in
            // deactivate our timer
            self.dailyCustomMorphicBarsRefreshTimer?.invalidate()
            
            // reload the Morphic bar
            self.reloadCustomMorphicBars { (success, error) in
                // ignore results
            }

            // reschedule our timer for the next day as well
            self.scheduleNextDailyMorphicCustomMorphicBarsRefresh()
        }
        RunLoop.main.add(dailyCustomMorphicBarsRefreshTimer!, forMode: .common)
    }
    
    enum ReloadCustomMorphicBarsError : Error {
        case noUserSpecified
        case networkOrAuthorizationOrSaveToDiskFailure
    }
    //
    func reloadCustomMorphicBars(completion: @escaping (_ success: Bool, _ error: ReloadCustomMorphicBarsError?) -> Void) {
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
            guard let customMorphicBarsAsJson = Session.shared.dictionary(for: .morphicCustomMorphicBarsAsJson) as? [String: String] else {
                completion(false, .networkOrAuthorizationOrSaveToDiskFailure)
                return
            }
            
            // determine if the user's previously-selected community still exists; if not, choose another community
            var userSelectedCommunityId = UserDefaults.morphic.selectedUserCommunityId(for: user.identifier)
            var userSelectedMorphicbarId = UserDefaults.morphic.selectedMorphicbarId(for: user.identifier)

            if userSelectedCommunityId != nil && customMorphicBarsAsJson[userSelectedCommunityId!] == nil {
                // the user has left the previous community; choose the first custom bar instead [or basic, if no custom bars exist]...and then save our change
                let userSelectedIds = self.firstCustomMorphicBarIdIfAvailable()
                userSelectedCommunityId = userSelectedIds?.communityId
                userSelectedMorphicbarId = userSelectedIds?.morphicbarId
                
                UserDefaults.morphic.set(selectedUserCommunityIdentifier: userSelectedCommunityId, for: user.identifier)
                UserDefaults.morphic.set(selectedMorphicbarIdentifier: userSelectedMorphicbarId, for: user.identifier)
            }

            // update our list of custom MorphicBars (after any 'current bar' re-selection has been done)
            self.updateSelectMorphicBarMenuItem()

            // now it's time to update the morphic bar
            self.morphicBarWindow?.updateMorphicBar()
            
            completion(true, nil)
        }
    }
    
    func firstCustomMorphicBarIdIfAvailable() -> (communityId: String, morphicbarId: String)? {
        // capture our list of cached morphic user communities
        guard let customMorphicBarsAsJson = Session.shared.dictionary(for: .morphicCustomMorphicBarsAsJson) as? [String: String] else {
            return nil
        }
        
        // find the first custom bar
        for (_ /* communityId */, communityDetailsAsJsonString) in customMorphicBarsAsJson {
            let communityDetailsAsJsonData = communityDetailsAsJsonString.data(using: .utf8)!
            let communityDetails = try! JSONDecoder().decode(Service.UserCommunityDetails.self, from: communityDetailsAsJsonData)
            
            let communityId = communityDetails.id
            if communityDetails.bars != nil && communityDetails.bars!.count > 0 {
                return (communityId, communityDetails.bars!.first!.id)
            } else {
                return (communityId, communityDetails.bar.id)
            }
        }
        
        // if no custom bar was available, return nil
        return nil
    }
    
    func selectFirstCustomBarIfAvailable() {
        guard let user = Session.shared.user else {
            return
        }

        // select the first custom bar
        let newUserSelectedIds = self.firstCustomMorphicBarIdIfAvailable()
        if newUserSelectedIds != nil {
            let newUserSelectedCommunityId = newUserSelectedIds?.communityId
            let newUserSelectedMorphicbarId = newUserSelectedIds?.morphicbarId

            // select the first custom bar in the list
            UserDefaults.morphic.set(selectedUserCommunityIdentifier: newUserSelectedCommunityId, for: user.identifier)
            UserDefaults.morphic.set(selectedMorphicbarIdentifier: newUserSelectedMorphicbarId, for: user.identifier)
            
            // update our list of custom MorphicBars (after any 'current bar' re-selection has been done)
            self.updateSelectMorphicBarMenuItem()

            // now it's time to update the morphic bar
            self.morphicBarWindow?.updateMorphicBar()
        }
    }
    
    @IBAction func selectBasicMorphicBar(_ sender: NSMenuItem) {
        if let user = Session.shared.user {
            UserDefaults.morphic.set(selectedUserCommunityIdentifier: nil, for: user.identifier)
            UserDefaults.morphic.set(selectedMorphicbarIdentifier: nil, for: user.identifier)
        }

        // update our list of custom MorphicBars (after any 'current bar' re-selection has been done)
        self.updateSelectMorphicBarMenuItem()

        // now it's time to update the morphic bar
        self.morphicBarWindow?.updateMorphicBar()
    }
    
    func updateSelectMorphicBarMenuItem() {
        self.selectMorphicBarMenuItem.isHidden = false

        // TODO: we should determine if the user has a subscription; if so we should display the "Edit my MorphicBars..." item in the menu as well

        // remove all the menu items before the 'Basic MorphicBar' menu item
        for _ in 0..<indexOfBasicMorphicBarSubmenuItem() {
            self.selectMorphicBarMenuItem.submenu?.removeItem(at: 0)
        }
        
        if let user = Session.shared.user {
            // capture our current-selected community id
            let userSelectedCommunityId = UserDefaults.morphic.selectedUserCommunityId(for: user.identifier)
            let userSelectedMorphicbarId = UserDefaults.morphic.selectedMorphicbarId(for: user.identifier)

            // get a sorted array of our community/morphicbar ids and names (sorted by name first, then by id)
            guard let morphicbarIdsAndNames = createSortedArrayOfMorphicBarIdAndCommunityIdsAndNames() else {
                return
            }
            
            // set the checked state on the basic morphic bar menu item
            if userSelectedCommunityId != nil {
                self.selectBasicMorphicBarMenuItem.state = .off
            } else {
                self.selectBasicMorphicBarMenuItem.state = .on
            }

            // now populate the menu with the community names...and highlight the currently-selected community (9)with a checkmark)
            //
            // add in all the custom bar names
            var menuItemChecked = false
            for morphicbarIdAndName in morphicbarIdsAndNames {
                let communityMenuItem = NSMenuItem(title: morphicbarIdAndName.compositeName, action: #selector(AppDelegate.customMorphicBarSelected), keyEquivalent: "")
                if morphicbarIdAndName.communityId == userSelectedCommunityId && morphicbarIdAndName.morphicbarId == userSelectedMorphicbarId {
                    communityMenuItem.state = .on
                    menuItemChecked = true
                } else if morphicbarIdAndName.communityId == userSelectedCommunityId && userSelectedMorphicbarId == nil && menuItemChecked == false {
                    communityMenuItem.state = .on
                    menuItemChecked = true
                }

                // NOTE: we tag each menu item with its morphicbarId's hashValue (which is only stable during the same run of the program); we do this to help disambiguate multiple communities with the same name
                // NOTE: ideally we can find another manner to match these up, to deal with the edge case of a hash collision
                communityMenuItem.tag = morphicbarIdAndName.morphicbarId.hashValue
                let indexOfBasicMorphicBarSubmenuItem = self.indexOfBasicMorphicBarSubmenuItem()
                self.selectMorphicBarMenuItem.submenu?.insertItem(communityMenuItem, at: indexOfBasicMorphicBarSubmenuItem)
            }
        } else {
            self.selectBasicMorphicBarMenuItem.state = .on
        }
    }
    
    func indexOfBasicMorphicBarSubmenuItem() -> Int {
        guard let submenu = self.selectMorphicBarMenuItem.submenu else {
            fatalError("Mandatory 'Select MorphicBar' submenu is missing")
        }
        
        // calculate the position (index) of the "Basic MorphicBar" menu item
        var indexOfBasicMorphicBarMenuItem: Int?
        for index in 0..<submenu.items.count {
            if submenu.item(at: index)!.title == "Basic MorphicBar" {
                indexOfBasicMorphicBarMenuItem = index
            }
        }
        guard let _ = indexOfBasicMorphicBarMenuItem else {
            fatalError("Mandatory 'Basic MorphicBar' menu bar item is missing")
        }
        
        return indexOfBasicMorphicBarMenuItem!
    }
    
    func combineCommunityNameAndMorphicbarName(communityName: String, morphicbarName: String) -> String {
        return morphicbarName + " (from " + communityName + ")"
    }
    
    typealias MorphicbarIdsAndNames = (communityId: String, communityName: String, morphicbarId: String, morphicbarName: String, compositeName: String)

    func createSortedArrayOfMorphicBarIdAndCommunityIdsAndNames() -> [MorphicbarIdsAndNames]? {
        // capture our list of cached morphic user communities
        guard let communityBarsAsJson = Session.shared.dictionary(for: .morphicCustomMorphicBarsAsJson) as? [String: String] else {
            return nil
        }
                
        // populate a dictionary of community ids and names (with morphicbar ids and names)
        var userCommunityIdsAndNames: [MorphicbarIdsAndNames] = []
        for (communityId, communityBarAsJsonString) in communityBarsAsJson {
            let communityDetailsAsJsonData = communityBarAsJsonString.data(using: .utf8)!
            let communityDetails = try! JSONDecoder().decode(Service.UserCommunityDetails.self, from: communityDetailsAsJsonData)
            
            let communityName = communityDetails.name
            
            if let communityBars = communityDetails.bars {
                for legacyBar in communityBars {
                    userCommunityIdsAndNames.append((communityId, communityName, legacyBar.id, legacyBar.name, combineCommunityNameAndMorphicbarName(communityName: communityName, morphicbarName: legacyBar.name)))
                }
            } else {
                // for backwards-compatibility with stored JSON, we fallback to the ".bar" property if ".bars" is not populated
                let legacyBar = communityDetails.bar
                userCommunityIdsAndNames.append((communityId, communityName, legacyBar.id, legacyBar.name, combineCommunityNameAndMorphicbarName(communityName: communityName, morphicbarName: legacyBar.name)))
            }
        }
        
        // sort the communities by name (and then secondarily by id, in case two have the same name)
        userCommunityIdsAndNames.sort { (arg0: MorphicbarIdsAndNames, arg1: MorphicbarIdsAndNames) -> Bool in
            if arg0.compositeName.lowercased() < arg1.compositeName.lowercased() {
                return true
            } else if arg0.compositeName.lowercased() == arg1.compositeName.lowercased() {
                if arg0.morphicbarId.lowercased() < arg1.morphicbarId.lowercased() {
                    return true
                }
            }
            
            return false
        }

        return userCommunityIdsAndNames
    }

    @objc
    func customMorphicBarSelected(_ sender: NSMenuItem) {
        guard let user = Session.shared.user else {
            return
        }
        
        // save the newly-selected community+morphicbar id
        
        let morphicbarCompositeName = sender.title
        let morphicbarIdHashValue = sender.tag
        
        // get a sorted array of our community/morphicbar ids and names (sorted by name first, then by id)
        guard let morphicbarIdsAndNames = createSortedArrayOfMorphicBarIdAndCommunityIdsAndNames() else {
            return
        }

        // calculate the community id of the selected community
        var selectedCommunityIdAndName = morphicbarIdsAndNames.first { (arg0) -> Bool in
            if arg0.morphicbarId.hashValue == morphicbarIdHashValue {
                return true
            } else {
                return false
            }
        }
        
        // if the selected community's tag doesn't match the name (i.e. there are multiple entries with the same name)
        if selectedCommunityIdAndName == nil || (selectedCommunityIdAndName!.compositeName != morphicbarCompositeName) {
            // if the hash value didn't work (which shouldn't be possible), gracefully degrade by finding the first entry with this name
            selectedCommunityIdAndName = morphicbarIdsAndNames.first { (arg0) -> Bool in
                if arg0.compositeName == morphicbarCompositeName {
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
        UserDefaults.morphic.set(selectedUserCommunityIdentifier: selectedCommunityIdAndName!.communityId, for: user.identifier)
        UserDefaults.morphic.set(selectedMorphicbarIdentifier: selectedCommunityIdAndName!.morphicbarId, for: user.identifier)

        // update our list of communities (so that we move the checkbox to the appropriate entry)
        self.updateSelectMorphicBarMenuItem()
        
        // now that the user has selected a new community bar, we switch to it using our cached data
        self.morphicBarWindow?.updateMorphicBar()

        // optionally, we can reload the data (asynchronously)
        reloadCustomMorphicBars { (success, error) in
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
            // flush out any preferences changes that may have taken effect because of logout
            Session.shared.savePreferences(waitFiveSecondsBeforeSave: false) {
                success in
                // NOTE: if success == false, we may want to consider letting the user know that we could not save

                // now it's time to update the morphic bar (and the selected MorphicBar entry)
                self.morphicBarWindow?.updateMorphicBar()
                self.updateSelectMorphicBarMenuItem()
            }
            
            self.loginMenuItem?.isHidden = false
            self.logoutMenuItem?.isHidden = true
        }
    }
    
    var copySettingsWindowController: NSWindowController? = nil

//    @IBAction
//    func showCopySettingsWindow(_ sender: Any?) {
//        if copySettingsWindowController == nil {
//            copySettingsWindowController = CopySettingsWindowController(windowNibName: "CopySettingsWindow")
//        }
//        copySettingsWindowController?.window?.makeKeyAndOrderFront(sender)
//        copySettingsWindowController?.window?.delegate = self
//    }

    @IBAction
    func showApplySettingsWindow(_ sender: Any?) {
        self.launchApplyFromCloudVault(sender)
    }

    @IBAction
    func showCaptureSettingsWindow(_ sender: Any?) {
        self.launchCaptureToCloudVault(sender)
    }

//    @IBAction
//    func reapplyAllSettings(_ sender: Any) {
//        Session.shared.open {
//            os_log(.info, "Re-applying all settings")
//            Session.shared.applyAllPreferences {
//
//            }
//        }
//    }
    
//    @IBAction
//    func captureAllSettings(_ sender: Any) {
//        let prefs = Preferences(identifier: "")
//        let capture = CaptureSession(settingsManager: Session.shared.settings, preferences: prefs)
//        capture.captureDefaultValues = true
//        capture.addAllSolutions()
//        capture.run {
//            for pair in capture.preferences.keyValueTuples(){
//                print(pair.0, pair.1 ?? "<nil>")
//            }
//        }
//    }
    
    @IBAction func menuBarExtraAboutMorphicMenuItemClicked(_ sender: NSMenuItem) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
            self.countly_RecordEvent("aboutMorphic", segmentation: segmentation)
        }
        showAboutBox()
    }

    @IBAction func morphicBarIconAboutMorphicMenuItemClicked(_ sender: NSMenuItem) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
            self.countly_RecordEvent("aboutMorphic", segmentation: segmentation)
        }
        showAboutBox()
    }

    func showAboutBox() {
        let aboutBoxWindowController = AboutBoxWindowController.single
        if aboutBoxWindowController.window?.isVisible == false {
            aboutBoxWindowController.centerOnScreen()
        }
        
        aboutBoxWindowController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc
    func terminateMorphicClientDueToDockAppTermination() {
        quitApplication()
    }
    
    func terminateMorphicClientDueToCmdQ() {
        let segmentation = ["eventSource": "keyboardShortcut"]
        self.countly_RecordEvent("quit", segmentation: segmentation)

        quitApplication()
    }
    
    @IBAction func menuBarExtraQuitApplicationMenuItemClicked(_ sender: NSMenuItem) {
        let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
        self.countly_RecordEvent("quit", segmentation: segmentation)

        quitApplication()
    }

    @IBAction func morphicBarIconQuitApplicationMenuItemClicked(_ sender: NSMenuItem) {
        let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
        self.countly_RecordEvent("quit", segmentation: segmentation)

        quitApplication()
    }

    func quitApplication() {
        // immediately hide our MorphicBar window
        morphicBarWindow?.setIsVisible(false)
        
        // terminate our dock app (if it's running)
        terminateDockAppIfRunning()

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
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        var computerIsLoggingOutOrShuttingDown = false
        
        if let currentAppleEvent = NSAppleEventManager.shared().currentAppleEvent {
            if let quitReason = currentAppleEvent.attributeDescriptor(forKeyword: kAEQuitReason)?.typeCodeValue {
                switch quitReason {
                case kAELogOut,
                     kAEReallyLogOut,
                     kAEShowRestartDialog,
                     kAERestart,
                     kAEShowShutdownDialog,
                     kAEShutDown:
                    // the system is logging out or shutting down
                    computerIsLoggingOutOrShuttingDown = true
                default:
                    // the user has quit the application
                    computerIsLoggingOutOrShuttingDown = false
                }
            }
        }
        
        // NOTE: if the login session is closing, consider any special precautions/procedures we need here
        if ConfigurableFeatures.shared.resetSettingsIsEnabled == true {
            self.resetSettings(skipResetsWithUIAutomation: computerIsLoggingOutOrShuttingDown)
        }
        
        // let the system know it's okay to terminate now
        return .terminateNow
    }
    
    //
    
    @IBAction func automaticallyStartMorphicAtLoginClicked(_ sender: NSMenuItem) {
        switch sender.state {
        case .on:
            defer {
                self.countly_RecordEvent("autorunAfterLoginDisabled")
            }
            _ = setMorphicAutostartAtLogin(false)
        case .off:
            defer {
                self.countly_RecordEvent("autorunAfterLoginEnabled")
            }
            _ = setMorphicAutostartAtLogin(true)
        default:
            fatalError("invalid code path")
        }
    }
    
    func updateMorphicAutostartAtLoginMenuItems() {
        let autostartAtLogin = self.morphicAutostartAtLogin()
        automaticallyStartMorphicAtLoginMenuItem?.state = (autostartAtLogin ? .on : .off)
    }
    
    func morphicAutostartAtLogin() -> Bool {
        // NOTE: in the future, we may want to save the autostart state in UserDefaults (although perhaps not in "UserDefaults.morphic"); we'd need to store in the UserDefaults area which was specific to _this_ user and _this_ application (including differentiating between Morphic and Morphic Community if there are two apps for that
        // If we do switch to UserDefaults in the future, we will effectively capture its "autostart enabled" state when we set it and then trust that the user hasn't used launchctl at the command-line to reverse our state; the worst-case scenario with this approach should be that our corresponding menu item checkbox is out of sync with system reality, and a poweruser who uses launchctl could simply uncheck and then recheck the menu item (or use launchctl) to reenable autostart-at-login for Morphic
        
        // NOTE: SMCopyAllJobDictionaries (the API typically used to get the list of login items) was deprecated in macOS 10.10 but has not been replaced.  It is technically still available as of macOS 10.15.
        guard let userLaunchedApps = SMCopyAllJobDictionaries(kSMDomainUserLaunchd)?.takeRetainedValue() as? [[String: Any]] else {
            return false
        }
        for userLaunchedApp in userLaunchedApps {
            switch userLaunchedApp["Program"] as? String {
            case "org.raisingthefloor.MorphicLauncher",
                 "org.raisingthefloor.MorphicLauncher-Debug":
                return true
            default:
                break
            }
        }

        // if we did not find an entry for Morphic in the list (either because autostart was never enabled OR because autostart was disabled), return false
        return false
    }
    
    // NOTE: LSSharedFileList.h functions (LSRegisterURL, LSSharedFileListInsertItemURL, etc.) are not allowed in sandboxed apps; therefore we have used Apple's recommended "login items" approach in our implementation.  If we ever need our application to appear in "System Preferences > Users & Groups > [User] > Login Items" then we can evaluate a revision to our approach...but the current approach is more future-proof.
    // see: https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/DesigningYourSandbox/DesigningYourSandbox.html
    // see: https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLoginItems.html#//apple_ref/doc/uid/10000172i-SW5-SW1
    func setMorphicAutostartAtLogin(_ autostartAtLogin: Bool) -> Bool {
        let success: Bool
        #if DEBUG
            success = SMLoginItemSetEnabled("org.raisingthefloor.MorphicLauncher-Debug" as CFString, autostartAtLogin)
        #else
            success = SMLoginItemSetEnabled("org.raisingthefloor.MorphicLauncher" as CFString, autostartAtLogin)
        #endif
        
        // NOTE: in the future, we may want to save the autostart state in UserDefaults (although perhaps not in "UserDefaults.morphic"); we'd need to store in the UserDefaults area which was specific to _this_ user and _this_ application (including differentiating between Morphic and Morphic Community if there are two apps for that
        
        // update the appropriate menu items to match
        if success == true {
            automaticallyStartMorphicAtLoginMenuItem?.state = (autostartAtLogin ? .on : .off)
        }
        
        return success
    }
    
    //
    
    enum MenuOpenedSource: String {
        case trayIcon
        case morphicBarIcon
    }
    
    func createMenuOpenedSourceSegmentation(menuOpenedSource: MenuOpenedSource?) -> [String: String] {
        var result: [String: String] = [:]
        if let menuOpenedSource = menuOpenedSource {
            result["eventSource"] = menuOpenedSource.rawValue + "Menu"
        }
        return result
    }
    
    //
    
    @IBAction func turnOffKeyRepeat(_ sender: NSMenuItem) {
        let newKeyRepeatEnabledState: Bool
        
        switch sender.state {
        case .on:
            newKeyRepeatEnabledState = true
        case .off:
            newKeyRepeatEnabledState = false
        default:
            fatalError("invalid code path")
        }
        
        defer {
            switch newKeyRepeatEnabledState {
            case true:
                self.countly_RecordEvent("stopKeyRepeatOff")
            case false:
                self.countly_RecordEvent("stopKeyRepeatOn")
            }
        }

        if MorphicInput.isTurnOffKeyRepeatBroken == true {
            if newKeyRepeatEnabledState == true {
                let alert = NSAlert()
                alert.messageText = "Cannot enable Key Repeat."
                alert.informativeText = "The current version of macOS cannot enable Key Repeat reliably due to a bug in the operating system.\n\nYou may adjust the Key Repeat speed via the \"Keyboard\" pane in System Preferences."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                _ = alert.runModal()
            } else {
                // if key repeat is broken, set the repeat interval to the slowest speed instead
                MorphicInput.setKeyRepeatInterval(MorphicInput.slowestKeyRepeatInterval)
            }
        } else {
            MorphicInput.setKeyRepeatIsEnabled(newKeyRepeatEnabledState)
        }

        self.updateTurnOffKeyRepeatMenuItems()
    }

    func updateTurnOffKeyRepeatMenuItems() {
        let keyRepeatIsEnabled: Bool

        if MorphicInput.isTurnOffKeyRepeatBroken == true {
            let keyRepeatInterval = MorphicInput.keyRepeatInterval
            if keyRepeatInterval == MorphicInput.slowestKeyRepeatInterval {
                keyRepeatIsEnabled = false
            } else {
                keyRepeatIsEnabled = true
            }
        } else {
            keyRepeatIsEnabled = MorphicInput.keyRepeatIsEnabled
        }

        turnOffKeyRepeatMenuItem?.state = keyRepeatIsEnabled ? .off : .on
    }

    //
    
    func setInitialColorFilterType() {
//        // NOTE: color-filter types (as their enumerated int values)
//        1: "Grayscale",
//        2: "Red/Green filter (Protanopia)",
//        4: "Green/Red filter (Deuteranopia)",
//        8: "Blue/Yellow filter (Tritanopia)",
//        16: "Color Tint"
        // TODO: convert this int into an enumeration (using the values from the above list)
        let colorFilterTypeAsInt: Int = 2 // Red/Green filter (Protanopia)
        
        Session.shared.apply(colorFilterTypeAsInt, for: .macosColorFilterType) {
            success in
            
            // we do not currently have a mechanism to report success/failure
            SettingsManager.shared.capture(valueFor: .macosColorFilterType) {
                verifyColorFilterType in
                guard let verifyColorFilterTypeAsInt = verifyColorFilterType as? Int else {
                    // could not get current setting
                    return
                }
                //
                if verifyColorFilterTypeAsInt != colorFilterTypeAsInt {
                    NSLog("Could not set color filter type to Red/Green filter (Protanopia)")
                    assertionFailure("Could not set color filter type to Red/Green filter (Protanopia)")
                }
            }
        }
        
        Session.shared.set(true, for: .morphicDidSetInitialColorFilterType)
    }
    
    func setInitialMagnifierZoomStyle(completion: @escaping (_ success: Bool) -> Void) {
//        // NOTE: zoom styles (as their enumerated int values)
//        0: "Full screen",
//        1: "Picture-in-picture",
//        2: "Split screen",
        // TODO: convert this int into an enumeration (using the values from the above list)
        let zoomStyleAsInt: Int = 1 // Picture-in-picture (aka "lens")

        Session.shared.apply(zoomStyleAsInt, for: .macosZoomStyle) {
            success in
         
            guard success == true else {
                completion(false)
                return
            }
            
            Session.shared.set(true, for: .morphicDidSetInitialMagnifierZoomStyle)

            // we do not currently have a mechanism to report success/failure
            SettingsManager.shared.capture(valueFor: .macosZoomStyle) {
                verifyZoomStyle in

                guard let verifyZoomStyleAsInt = verifyZoomStyle as? Int else {
                    // could not get current setting
                    completion(false)
                    return
                }
                //
                if verifyZoomStyleAsInt != verifyZoomStyleAsInt {
                    NSLog("Could not set magnifier zoom style to Picture-in-picture")
                    assertionFailure("Could not set magnifier zoom style to Picture-in-picture")

                    completion(false)
                    return
                }
                
                completion(true)
            }
        }
    }
    
    func setInitialAutorunAfterLoginEnabled() {
        _ = setMorphicAutostartAtLogin(true)
        
        Session.shared.set(true, for: .morphicDidSetInitialAutorunAfterLoginEnabled)
    }

    //
    
    private var menuModifierKeyObserver: CFRunLoopObserver? = nil
    
    private func createMenuKeyMonitorRunLoopObserver() -> CFRunLoopObserver? {
        let observer = CFRunLoopObserverCreateWithHandler(nil /* kCFAllocatorDefault */, CFRunLoopActivity.beforeWaiting.rawValue, true /* repeats */, 0 /* order */) { (
            observer, activity) in
            //
            self.updateMenuItemsBasedOnModifierKeys()
        }
        
        return observer
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        // wire up a modifier key observer (so we can show/hide the "Hide QuickHelp" item when the Option key is pressed/released)
        
        // setup the menu using the initial modifier key state
        self.updateMenuItemsBasedOnModifierKeys()

        // wire up the observer (to watch for all common mode events including keystrokes)
        guard let menuModifierKeyObserver = createMenuKeyMonitorRunLoopObserver() else {
            assertionFailure("Could not create keyboard modifier observer")
            return
        }
        CFRunLoopAddObserver(RunLoop.current.getCFRunLoop(), menuModifierKeyObserver, CFRunLoopMode.commonModes)
        self.menuModifierKeyObserver = menuModifierKeyObserver
    }

    public func menuDidClose(_ menu: NSMenu) {
        // disconnect our modifier key observer
        if let menuModifierKeyObserver = self.menuModifierKeyObserver {
            CFRunLoopRemoveObserver(RunLoop.current.getCFRunLoop(), menuModifierKeyObserver, CFRunLoopMode.commonModes)
            CFRunLoopObserverInvalidate(menuModifierKeyObserver)
            self.menuModifierKeyObserver = nil
        }
    }
    
    private func updateMenuItemsBasedOnModifierKeys() {
        // get the currently-pressed modifier keys
        let currentModifierKeys = NSEvent.modifierFlags

        if currentModifierKeys.rawValue & NSEvent.ModifierFlags.option.rawValue != 0 {
            self.hideQuickHelpMenuItem.isHidden = false
        } else {
            self.hideQuickHelpMenuItem.isHidden = true
        }
    }
    
    @IBAction func hideQuickHelpClicked(_ sender: NSMenuItem) {
        switch sender.state {
        case .on:
            setHideQuickHelpState(false)
        case .off:
            setHideQuickHelpState(true)
        default:
            fatalError("invalid code path")
        }
        updateHideQuickHelpMenuItems()
    }
    
    func updateHideQuickHelpMenuItems() {
        let hideQuickHelpAtLogin = self.hideQuickHelpState()
        hideQuickHelpMenuItem?.state = (hideQuickHelpAtLogin ? .on : .off)
    }

    func hideQuickHelpState() -> Bool {
        let morphicBarShowsHelp = Session.shared.bool(for: .morphicBarShowsHelp) ?? true
        return !morphicBarShowsHelp
    }
    
    func setHideQuickHelpState(_ state: Bool) {
        let newShowsHelpState = !state
        Session.shared.set(newShowsHelpState, for: .morphicBarShowsHelp)
                
        morphicBarWindow?.updateShowsHelp()
        
        if newShowsHelpState == false {
            QuickHelpWindow.hide()
        }
    }

    //
    
    @IBAction func showMorphicBarAtStartClicked(_ sender: NSMenuItem) {
        let showMorphicBarAtStart: Bool
        switch sender.state {
        case .on:
            defer {
                self.countly_RecordEvent("showMorphicBarAfterLoginDisabled")
            }
            showMorphicBarAtStart = false
        case .off:
            defer {
                self.countly_RecordEvent("showMorphicBarAfterLoginEnabled")
            }
            showMorphicBarAtStart = true
        default:
            fatalError("invalid code path")
        }
        
        Session.shared.set(showMorphicBarAtStart, for: .showMorphicBarAtStart)
        
        updateShowMorphicBarAtStartMenuItems()
    }
    
    func updateShowMorphicBarAtStartMenuItems() {
        let showMorphicBarAtStart = Session.shared.bool(for: .showMorphicBarAtStart) ?? false
        showMorphicBarAtStartMenuItem?.state = (showMorphicBarAtStart ? .on : .off)
    }
    
    //
    
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
    //
    // NOTE: this helper class functions purely to watch the StatusItem's mouse enter/exit events (without needing to subclass its button)
    var statusBarMouseActionOwner: StatusBarMouseActionOwner? = nil
    class StatusBarMouseActionOwner: NSResponder {
        override func mouseEntered(with event: NSEvent) {
            AppDelegate.shared.changeStatusItemMode(enableCustomMouseDownActions: true)
        }
        
        override func mouseExited(with event: NSEvent) {
            AppDelegate.shared.changeStatusItemMode(enableCustomMouseDownActions: false)
        }
    }
    
    /// Create our `statusItem` for the macOS menu bar
    ///
    /// Should be called during application launch
    func createStatusItem() {
        os_log(.info, log: logger, "Creating status item")
        statusItem = NSStatusBar.system.statusItem(withLength: -1)
        // NOTE: here we use a default menu for the statusicon (which works with VoiceOver and with ^F8 a11y keyboard navigation); separately we will capture mouse enter/exit events to make the statusitem something more custom
        statusItem.menu = self.mainMenu
        
        // update the menu to match the proper edition of Morphic
        updateMenu()

        guard let statusItemButton = statusItem.button else {
            fatalError("Could not get reference to statusItemButton")
        }

        let buttonImage = NSImage(named: "MenuIconBlack")
        buttonImage?.isTemplate = true
        statusItemButton.image = buttonImage

        // capture statusItem (menubar extra) mouse enter/exit events; we'll use these events to switch the statusItem between "normal macOS StatusItem" mode (which is compatible with a11y keyboard navigation and VoiceOver) and "custom macOS StatusItem" mode (where we can separate left- and right-click into two separate actions)
        self.statusBarMouseActionOwner = StatusBarMouseActionOwner()
        let boundsTrackingArea = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .inVisibleRect, .activeAlways], owner: statusBarMouseActionOwner, userInfo: nil)
        statusItemButton.addTrackingArea(boundsTrackingArea)

        // connect the "left-click" action to toggle show/hide of the MorphicBar (and right-click to show the menu)
        statusItemButton.target = self
        statusItemButton.action = #selector(AppDelegate.statusItemMousePressed)
        statusItemButton.sendAction(on: [.leftMouseDown, .rightMouseDown])
    }

    func changeStatusItemMode(enableCustomMouseDownActions: Bool) {
        guard let _ = statusItem.button else {
            fatalError("Could not get reference to statusItemButton")
        }

        switch enableCustomMouseDownActions {
        case true:
            // disable menu so that our left- and right-click action handlers will be called
            statusItem.menu = nil
        case false:
            // re-enable menu by default (for macos keyboard accessibility and voiceover compatibility
            statusItem.menu = mainMenu
        }
    }
    
    @objc
    func statusItemMousePressed(sender: NSStatusBarButton?) {
        guard let currentEvent = NSApp.currentEvent else {
            return
        }

        if currentEvent.type == .leftMouseDown {
            // when the left mouse button is pressed, toggle the MorphicBar's visibility (i.e. show/hide the MorphicBar)

            let morphicBarWindowWasVisible = morphicBarWindow != nil
            defer {
                let segmentation: [String: String] = ["eventSource": "trayIconClick"]
                if morphicBarWindowWasVisible == true {
                    self.countly_RecordEvent("morphicBarHide", segmentation: segmentation)
                } else {
                    self.countly_RecordEvent("morphicBarShow", segmentation: segmentation)
                }
            }
            toggleMorphicBar(sender)
        } else if currentEvent.type == .rightMouseDown {
            // when the right mouse button is pressed, show the main menu

            guard let statusItem = self.statusItem else {
                assertionFailure("Could not obtain reference to MenuBar extra's StatusItem.")
                return
            }
            guard let statusItemButton = statusItem.button else {
                assertionFailure("Could not obtain reference to MenuBar extra's StatusItem's button.")
                return
            }

            // show the menu (by assigning it to the menubar extra and re-clicking the extra; then disconnect the menu again so that our custom actions (custom left- and right-mouseDown) work properly.
            defer {
                let segmentation = AppDelegate.shared.createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
                self.countly_RecordEvent("showMenu", segmentation: segmentation)
            }
            statusItem.menu = self.mainMenu
            statusItemButton.performClick(sender)
            statusItem.menu = nil

            // NOTE: due to a glitch in macOS, our StatusItem's Button's view doesn't get the "rightMouseUp" event so it gets into an odd state where it doesn't respond to the _next_ button down event.  So we manually send ourselves a "rightMouseUp" event, centered over the status item, to clear the state issue.
            let statusItemButtonBoundsInWindow = statusItemButton.convert(statusItemButton.bounds, to: nil)
            if let statusItemBoundsOnScreen = statusItemButton.window?.convertToScreen(statusItemButtonBoundsInWindow) {
                let cursorPosition = CGPoint(x: statusItemBoundsOnScreen.midX, y: statusItemBoundsOnScreen.midY)
                let eventMouseUp = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: cursorPosition, mouseButton: .right)
                eventMouseUp!.postToPid(NSRunningApplication.current.processIdentifier)
            }
        }
    }
    
    private func updateMenu() {
        if let _ = ConfigurableFeatures.shared.autorunConfig {
            self.automaticallyStartMorphicAtLoginMenuItem.isHidden = true
        }
        if let _ = ConfigurableFeatures.shared.morphicBarVisibilityAfterLogin {
            self.showMorphicBarAtStartMenuItem.isHidden = true
        }
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
    
    @objc
    func showMorphicBarDueToDockAppActivation() {
        showMorphicBar(nil)
    }
    
    @IBAction
    func menuBarExtraShowMorphicBarMenuItemClicked(_ sender: NSMenuItem) {
        let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
        self.countly_RecordEvent("morphicBarShow", segmentation: segmentation)
        showMorphicBar(sender)
    }
    
    func showMorphicBar(_ sender: Any?) {
        if morphicBarWindow == nil {
            morphicBarWindow = MorphicBarWindow()
            self.updateMorphicAutostartAtLoginMenuItems()
            self.updateShowMorphicBarAtStartMenuItems()
            self.updateHideQuickHelpMenuItems()
            morphicBarWindow?.delegate = self
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        morphicBarWindow?.makeKeyAndOrderFront(nil)
        showMorphicBarMenuItem?.isHidden = true
        hideMorphicBarMenuItem?.isHidden = false
        if Session.shared.bool(for: .morphicBarVisible) != true {
            Session.shared.set(true, for: .morphicBarVisible)
        }
    }
    
    @IBAction
    func menuBarExtraHideMorphicBarMenuItemClicked(_ sender: NSMenuItem) {
        let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
        self.countly_RecordEvent("morphicBarHide", segmentation: segmentation)
        hideMorphicBar(sender)
    }

    @IBAction
    func morphicBarIconHideMorphicBarMenuItemClicked(_ sender: NSMenuItem) {
        let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
        self.countly_RecordEvent("morphicBarHide", segmentation: segmentation)
        hideMorphicBar(sender)
    }

    func morphicBarCloseButtonPressed() {
        let segmentation = ["eventSource": "closeButton"]
        self.countly_RecordEvent("morphicBarHide", segmentation: segmentation)
        hideMorphicBar(nil)
    }
    
    func hideMorphicBar(_ sender: Any?) {
        currentKeyboardSelectedQuickHelpViewController = nil

        if let morphicBarWindow = morphicBarWindow {
            morphicBarWindow.close()
        } else {
            os_log(.info, log: logger, "Could not close MorphicBar; morphicBarWindow is nil")
        }
        self.morphicBarWindow = nil
        
        showMorphicBarMenuItem?.isHidden = false
        hideMorphicBarMenuItem?.isHidden = true
        QuickHelpWindow.hide()
        if Session.shared.bool(for: .morphicBarVisible) != false {
            Session.shared.set(false, for: .morphicBarVisible)
        }
    }
    
    //

    @IBAction
    func menuBarExtraCustomizeMorphicbarMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
            self.countly_RecordEvent("customizeMorphicbar", segmentation: segmentation)
        }

        customizeMorphicbarClicked()
    }

    func customizeMorphicbarClicked() {
        guard let morphicbarEditorUrlAsString = Bundle.main.infoDictionary?["MorphicbarEditorURL"] as? String else {
            fatalError("MORPHICBAR_EDITOR_URL (mandatory) not set in .xcconfig")
        }

        let url = URL(string: morphicbarEditorUrlAsString)!
        NSWorkspace.shared.open(url)
    }

    @IBAction
    func menuBarExtraHowToCopySetupsMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
            self.countly_RecordEvent("howToCopySetups", segmentation: segmentation)
        }

        transferSetupsClicked()
    }

    func transferSetupsClicked() {
        let url = URL(string: "https://morphic.org/xfersetups")!
        NSWorkspace.shared.open(url)
    }

    @IBAction
    func menuBarExtraExploreMorphicMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
            self.countly_RecordEvent("exploreMorphic", segmentation: segmentation)
        }

        exploreMorphicClicked()
    }

    @IBAction
    func morphicBarIconExploreMorphicMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
            self.countly_RecordEvent("exploreMorphic", segmentation: segmentation)
        }
        
        exploreMorphicClicked()
    }
    
    func exploreMorphicClicked() {
        let url = URL(string: "https://morphic.org/exploremorphic")!
        NSWorkspace.shared.open(url)
    }

    @IBAction
    func menuBarExtraQuickDemoMoviesMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
            self.countly_RecordEvent("quickDemoVideo", segmentation: segmentation)
        }
        
        quickDemoMoviesClicked()
    }
    
    @IBAction
    func morphicBarIconQuickDemoMoviesMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
            self.countly_RecordEvent("quickDemoVideo", segmentation: segmentation)
        }

        quickDemoMoviesClicked()
    }
    
    func quickDemoMoviesClicked() {
        let url = URL(string: "https://morphic.org/demos")!
        NSWorkspace.shared.open(url)
    }

    @IBAction
    func menuBarExtraOtherHelpfulThingsMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
            self.countly_RecordEvent("otherHelpfulThings", segmentation: segmentation)
        }
        
        otherHelpfulThingsClicked()
    }
    
    @IBAction
    func morphicBarIconOtherHelpfulThingsMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
            self.countly_RecordEvent("otherHelpfulThings", segmentation: segmentation)
        }

        otherHelpfulThingsClicked()
    }
    
    func otherHelpfulThingsClicked() {
        let url = URL(string: "https://morphic.org/helpful")!
        NSWorkspace.shared.open(url)
    }

    //

    @IBAction
    func launchAllAccessibilityOptionsSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "allAccessibility", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.accessibilityOverview)
    }
    
    @IBAction
    func launchBrightnessSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "brightness", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.displaysDisplay)
    }
    
    @IBAction
    func launchColorVisionSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "colorFilter", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.accessibilityDisplayColorFilters)
    }
    
    @IBAction
    func launchContrastSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "highContrast", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.accessibilityDisplayDisplay)
    }
    
    @IBAction
    func launchDarkModeSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "darkMode", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.general)
    }

    @IBAction
    func launchLanguageSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "language", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.languageandregionGeneral)
    }
    
    @IBAction
    func launchMagnifierSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "magnifier", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.accessibilityZoom)
    }

    @IBAction
    func launchMouseSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "mouse", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.mouse)
    }

    @IBAction
    func launchNightModeSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "nightMode", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.displaysNightShift)
    }
    
    @IBAction
    func launchPointerSizeSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "pointerSize", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.accessibilityDisplayCursor)
    }
    
    @IBAction
    func launchReadAloudSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "readAloud", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.accessibilitySpeech)
    }

    @IBAction
    func launchKeyboardSettings(_ sender: Any?) {
        defer {
            recordCountlyOpenSystemSettingsEvent(category: "keyboard", tag: (sender as? NSView)?.tag)
        }
        SettingsLinkActions.openSystemPreferencesPane(.keyboardKeyboard)
    }
    
    //
    
    func recordCountlyOpenSystemSettingsEvent(category settingsCategoryName: String, tag: Int?) {
        var segmentation: [String: String] = [:]
        segmentation["category"] = settingsCategoryName
        if tag == nil || tag! == 0 {
            // main menu
            segmentation["eventSource"] = "iconMenu"
        } else if tag! == 1 {
            segmentation["eventSource"] = "contextMenu"
        }
        self.countly_RecordEvent("systemSettings", segmentation: segmentation)
//        self.countly_RecordEvent("systemSettings" + settingsCategoryName)
    }
    
    //

    var currentKeyboardSelectedQuickHelpViewController: NSViewController? = nil
    
    ///This function fires if the bar window gains focus.
    func windowDidBecomeKey(_ notification: Notification) {
        morphicBarWindow?.windowIsKey = true
        if let currentKeyboardSelectedQuickHelpViewController = currentKeyboardSelectedQuickHelpViewController {
            QuickHelpWindow.show(viewController: currentKeyboardSelectedQuickHelpViewController)
        }
    }
     
    ///This function fires if the bar window loses focus.
    func windowDidResignKey(_ notification: Notification) {
        morphicBarWindow?.windowIsKey = false
        morphicBarWindow?.morphicBarViewController.closeTray(nil)   //get rid of this to have the tray stay open when defocused
        QuickHelpWindow.hide()
    }
     
    func windowDidChangeScreen(_ notification: Notification) {
        morphicBarWindow?.reposition(animated: false)
    }
     
    // MARK: - Configurator App
    
    @IBAction
    func launchCaptureToCloudVault(_ sender: Any?) {
        copySettingsWindowController?.close()
        copySettingsWindowController = nil

        launchConfigurator(argument: "capture")
    }

    @IBAction
    func launchApplyFromCloudVault(_ sender: Any?) {
        copySettingsWindowController?.close()
        copySettingsWindowController = nil

        launchLogin(sender)
    }
    
    @IBAction
    func launchLogin(_ sender: Any?) {
        launchConfigurator(argument: "login")
    }
    
    func launchConfigurator(argument: String) {
//        let url = URL(string: "morphicconfig:\(argument)")!
//        NSWorkspace.shared.open(url)
        os_log(.info, log: logger, "launching configurator")
        
        let morphicConfiguratorAppName = "MorphicConfigurator.app"
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
    
    func launchDockAppIfNotRunning() {
        guard morphicDockAppIsRunning() == false else {
            os_log(.info, log: logger, "skipping launch of dock app (as dock app is already running)")
            return
        }
        
        os_log(.info, log: logger, "launching dock app")
        
        // NOTE: the application name (with an extra space before and after the application) is an artifact of the fact that we can't easily name the dock app "Morphic" while our main app is also named "Morphic"...yet we need the display name (in the dock and the cmd+tab order) to read as "Morphic."  Adding spaces on both sides makes the name appear reasonably properly (and still be centered) but long-term we should ideally consider making the dock app the startup app or renaming the main application bundle.
        let morphicDockAppAppName = " Morphic .app"
        guard let url = Bundle.main.resourceURL?.deletingLastPathComponent().appendingPathComponent("Library").appendingPathComponent(morphicDockAppAppName) else {
            os_log(.error, log: logger, "Failed to construct bundled dock app URL")
            return
        }
        let arguments = ["--ignoreFirstActivation"]
        MorphicProcess.openProcess(at: url, arguments: arguments, activate: false, hide: false) {
            (app, error) in
            guard error == nil else {
                os_log(.error, log: logger, "Failed to launch dock app: %{public}s", error!.localizedDescription)
                return
            }
        }
    }
    
    // MARK: - Native code observers
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else {
            return
        }
        
        switch keyPath {
        case "increaseContrast":
            guard let enabledAsBool = change?[NSKeyValueChangeKey.newKey] as? Bool else {
                return
            }
            NotificationCenter.default.post(name: .morphicFeatureContrastEnabledChanged, object: nil, userInfo: ["enabled" : enabledAsBool])
        case "__Color__-MADisplayFilterCategoryEnabled":
            guard let enabledAsBool = change?[NSKeyValueChangeKey.newKey] as? Bool else {
                return
            }
            NotificationCenter.default.post(name: .morphicFeatureColorFiltersEnabledChanged, object: nil, userInfo: ["enabled" : enabledAsBool])
        default:
            return
        }
    }
    
    @objc
    func appleInterfaceThemeChanged(_ aNotification: Notification) {
        NotificationCenter.default.post(name: .morphicFeatureInterfaceThemeChanged, object: nil, userInfo: nil)
    }

    //

    var contrastChangeNotificationsEnabled = false
    var contrastChangeNotificationsDefaults: UserDefaults? = nil
    func enableContrastChangeNotifications() {
        if self.contrastChangeNotificationsEnabled == false {
            self.contrastChangeNotificationsDefaults = UserDefaults(suiteName: "com.apple.universalaccess")
            self.contrastChangeNotificationsDefaults?.addObserver(AppDelegate.shared, forKeyPath: "increaseContrast", options: .new, context: nil)
            
            self.contrastChangeNotificationsEnabled = true
        }
    }
    
    var colorFiltersEnabledChangeNotificationsEnabled = false
    var colorFiltersEnabledChangeNotificationsDefaults: UserDefaults? = nil
    func enableColorFiltersEnabledChangeNotifications() {
        if self.colorFiltersEnabledChangeNotificationsEnabled == false {
            self.colorFiltersEnabledChangeNotificationsDefaults = UserDefaults(suiteName: "com.apple.mediaaccessibility")
            self.colorFiltersEnabledChangeNotificationsDefaults?.addObserver(AppDelegate.shared, forKeyPath: "__Color__-MADisplayFilterCategoryEnabled", options: .new, context: nil)
            
            self.colorFiltersEnabledChangeNotificationsEnabled = true
        }
    }
    
    var darkAppearanceEnabledChangeNotificationsEnabled = false
    func enableDarkAppearanceEnabledChangeNotifications() {
        if self.darkAppearanceEnabledChangeNotificationsEnabled == false {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.appleInterfaceThemeChanged(_:)), name: .appleInterfaceThemeChanged, object: nil)

            self.darkAppearanceEnabledChangeNotificationsEnabled = true
        }
    }
}

public extension NSNotification.Name {
    static let morphicFeatureColorFiltersEnabledChanged = NSNotification.Name("org.raisingthefloor.morphicFeatureColorFiltersEnabledChanged")
    static let morphicFeatureContrastEnabledChanged = NSNotification.Name("org.raisingthefloor.morphicFeatureContrastEnabledChanged")
    static let morphicFeatureInterfaceThemeChanged = NSNotification.Name("org.raisingthefloor.morphicFeatureInterfaceThemeChanged")
    static let showMorphicBarDueToDockAppActivation = NSNotification.Name("org.raisingthefloor.showMorphicBarDueToDockAppActivation")
    static let showMorphicBarDueToUserRelaunch = NSNotification.Name(rawValue: "org.raisingthefloor.showMorphicBarDueToUserRelaunch")
    static let terminateMorphicClientDueToDockAppTermination = NSNotification.Name(rawValue: "org.raisingthefloor.terminateMorphicClientDueToDockAppTermination")
    static let terminateMorphicDockApp = NSNotification.Name(rawValue: "org.raisingthefloor.terminateMorphicDockApp")
    static let terminateMorphicLauncher = NSNotification.Name(rawValue: "org.raisingthefloor.terminateMorphicLauncher")
}

extension UserDefaults
{
    @objc dynamic var AppleKeyboardUIMode: Int
    {
        get {
            return integer(forKey: "AppleKeyboardUIMode")
        }
    }
}
