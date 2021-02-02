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
    
    @IBOutlet var menu: NSMenu!
    @IBOutlet weak var showMorphicBarMenuItem: NSMenuItem?
    @IBOutlet weak var hideMorphicBarMenuItem: NSMenuItem?
    @IBOutlet weak var copySettingsBetweenComputersMenuItem: NSMenuItem!
    @IBOutlet weak var loginMenuItem: NSMenuItem!
    @IBOutlet weak var logoutMenuItem: NSMenuItem?
    @IBOutlet weak var selectCommunityMenuItem: NSMenuItem!
    
    @IBOutlet weak var automaticallyStartMorphicAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var showMorphicBarAtStartMenuItem: NSMenuItem!
    @IBOutlet weak var hideQuickHelpMenuItem: NSMenuItem!

    @IBOutlet weak var turnOffKeyRepeatMenuItem: NSMenuItem!
    
    private var voiceOverEnabledObservation: NSKeyValueObservation?
    private var appleKeyboardUIModeObservation: NSKeyValueObservation?

    let appCastUrl = URL(string: "https://app.morphic.org/autoupdate/morphic-macos.appcast.xml")!

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        os_log(.info, log: logger, "applicationDidFinishLaunching")
        AppDelegate.shared = self

        // capture the edition of Morphic
        #if EDITION_BASIC
        Session.morphicEdition = .basic
        #elseif EDITION_COMMUNITY
        Session.morphicEdition = .plus
        #else
        fatalError("This application was not compiled with the mandatory EDITION flag")
        #endif
        
        // watch for notifications that the user attempted to relaunch Morphic
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.showMorphicBarDueToApplicationRelaunch(_:)), name: .showMorphicBarDueToUserRelaunch, object: nil)

        // NOTE: if desired, we could call morphicLauncherIsRunning() to detect if we were auto-started by our launch item (and capture that on startup); this would (generally) confirm that "autostart Morphic on login" is enabled without having to use deprecated SMJob functions
        //
        // terminate Morphic Launcher if it is already running
        terminateMorphicLauncherIfRunning()

        // before we open any storage or use UserDefaults, set up our ApplicationSupport path and UserDefaults suiteName
        switch Session.morphicEdition {
        case .basic:
            Storage.setApplicationSupportDirectoryName("org.raisingthefloor.MorphicBasic")
            UserDefaults.setMorphicSuiteName("org.raisingthefloor.MorphicBasic")
        case .plus:
            Storage.setApplicationSupportDirectoryName("org.raisingthefloor.MorphicCommunity")
            UserDefaults.setMorphicSuiteName("org.raisingthefloor.MorphicCommunity")
        }

        // set up options for the current edition of Morphic
        switch Session.morphicEdition {
        case .basic:
            // capture the common configuration (if one is present)
            let commonConfiguration = self.getCommonConfiguration()
            ConfigurableFeatures.shared.morphicBarVisibilityAfterLogin = commonConfiguration.morphicBarVisibilityAfterLogin
            ConfigurableFeatures.shared.morphicBarExtraItems = commonConfiguration.extraMorphicBarItems
            ConfigurableFeatures.shared.autorunConfig = commonConfiguration.autorunConfig
            ConfigurableFeatures.shared.checkForUpdatesIsEnabled = commonConfiguration.checkForUpdatesIsEnabled
            ConfigurableFeatures.shared.resetSettingsIsEnabled = commonConfiguration.resetSettingsIsEnabled
            Session.shared.isCaptureAndApplyEnabled = commonConfiguration.cloudSettingsTransferIsEnabled
            Session.shared.isServerPreferencesSyncEnabled = true
        case .plus:
            Session.shared.isCaptureAndApplyEnabled = false
            Session.shared.isServerPreferencesSyncEnabled = false
        }

        self.configureCountly()
        
        switch Session.morphicEdition {
        case .basic:
            #if DEBUG
                // do not run the auto-updater checks in debug mode
            #else
                if ConfigurableFeatures.shared.checkForUpdatesIsEnabled == true {
                    Autoupdater.startCheckingForUpdates(url: self.appCastUrl)
                }
            #endif
        case .plus:
            break
        }

        os_log(.info, log: logger, "opening morphic session...")
        populateSolutions()
        createStatusItem()
        loadInitialDefaultPreferences()
        createEmptyDefaultPreferencesIfNotExist {
            Session.shared.open {
                os_log(.info, log: logger, "session open")
                
                switch Session.morphicEdition {
                case .basic:
                    if ConfigurableFeatures.shared.resetSettingsIsEnabled == true {
                        self.resetSettings()
                    }
                case .plus:
                    break
                }

                self.copySettingsBetweenComputersMenuItem?.isHidden = (Session.shared.isCaptureAndApplyEnabled == false)
                
                switch Session.morphicEdition {
                case .basic:
                    break
                case .plus:
                    if Session.shared.user == nil {
                        self.showMorphicBarMenuItem?.isHidden = true
                    }
                }
                switch Session.morphicEdition {
                case .basic:
                    break
                case .plus:
                    self.loginMenuItem?.isHidden = (Session.shared.user != nil)
                }
                self.logoutMenuItem?.isHidden = (Session.shared.user == nil)

                self.menu?.delegate = self
                
                // capture the user's preference as to whether or not to show the Morphic Bar at startup
                // showMorphicBarAtStart: true if we should always try to show the MorphicBar at application startup
                let showMorphicBarAtStart = Session.shared.bool(for: .showMorphicBarAtStart) ?? false

                // show the Morphic Bar (if we have a bar to show and it's (a) our first startup or (b) the user had the bar showing when the app was last exited or (c) the user has "show MorphicBar at start" set to true
                switch Session.morphicEdition {
                case .basic:
                    var showMorphicBar: Bool = false
                    if showMorphicBarAtStart == true {
                        showMorphicBar = true;
                    }
                    switch ConfigurableFeatures.shared.morphicBarVisibilityAfterLogin {
                    case .show:
                        showMorphicBar = true
                    case .hide:
                        showMorphicBar = false
                    case .restore,
                         nil: // restore is the default setting
                        // if the bar has not been shown before, show it now; if it has been shown/hidden before, use the last known visibility state
                        // NOTE: morphicBarVisible is true if the MorphicBar was visible when we last exited the application
                        showMorphicBar = Session.shared.bool(for: .morphicBarVisible) ?? true
                    }

                    if showMorphicBar == true {
                        self.showMorphicBar(nil)
                    }
                case .plus:
                    // morphicBarVisible: true if the MorphicBar was visible when we last exited the application
                    let morphicBarVisible = Session.shared.bool(for: .morphicBarVisible) ?? true

                    if Session.shared.user != nil && (morphicBarVisible || showMorphicBarAtStart) {
                        self.showMorphicBar(nil)
                    }
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

                switch Session.morphicEdition {
                case .basic:
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
                case .plus:
                    break
                }

                if Session.shared.user != nil {
                    switch Session.morphicEdition {
                    case .basic:
                        break
                    case .plus:
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
                    }
                }
                DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.userDidSignin), name: .morphicSignin, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.sessionUserDidChange(_:)), name: .morphicSessionUserDidChange, object: Session.shared)

                switch Session.morphicEdition {
                case .basic:
                    break
                case .plus:
                    // if no user is logged in, launch the login window at startup of Morphic Community
                    // NOTE: in the future we may want to consider only auto-launching the login window on first-run (perhaps as part of an animated sequence introducing Morphic to the user).
                    if (Session.shared.user == nil) {
                        self.launchConfigurator(argument: "login")
                    }
                }
                
                switch Session.morphicEdition {
                case .basic:
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
                case .plus:
                    break
                }
                
                // if the user has already configured settings which we set defaults for, make sure we don't change those settings
                self.markUserConfiguredSettingsAsAlreadySet()
            }
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
        let telemetryDeviceUuid: String
        let telemetryDeviceUuidAsOptional = UserDefaults.morphic.telemetryDeviceUuid()
        if let telemetryDeviceUuidAsOptional = telemetryDeviceUuidAsOptional {
            // use the existing telemetry device uuid
            telemetryDeviceUuid = telemetryDeviceUuidAsOptional
        } else {
            // create a new device uuid for purposes of telemetry
            // NOTE: GUIDs should be lowercase; macOS outputs UUIDs as uppercase; therefore we manually lowercase them
            telemetryDeviceUuid = "D_" + NSUUID().uuidString.lowercased()
            UserDefaults.morphic.set(telemetryDeviceUuid: telemetryDeviceUuid)
        }
        
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
        Countly.sharedInstance().endSession()
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
            switch Session.morphicEdition {
            case .basic:
                let userInfo = notification.userInfo ?? [:]
                if !(userInfo["isRegister"] as? Bool ?? false) {
                    os_log(.info, log: logger, "Is not a registration signin, applying all preferences")
                    Session.shared.applyAllPreferences {
                    }
                }
            case .plus:
                break
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
            
            switch Session.morphicEdition {
            case .basic:
                switch application.bundleIdentifier {
                case "org.raisingthefloor.MorphicLauncher",
                     "org.raisingthefloor.MorphicLauncher-Debug":
                    return true
                default:
                    return false
                }
            case .plus:
                switch application.bundleIdentifier {
                case "org.raisingthefloor.MorphicCommunityLauncher",
                     "org.raisingthefloor.MorphicCommunityLauncher-Debug":
                    return true
                default:
                    return false
                }
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
        switch Session.morphicEdition {
        case .basic:
            break
        case .plus:
            self.loginMenuItem?.isHidden = (session.user != nil)
        }
        self.logoutMenuItem?.isHidden = (session.user == nil)
        
        switch Session.morphicEdition {
        case .basic:
            break
        case .plus:
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
        }
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
    }

    struct CommonConfigurationContents {
        public var autorunConfig: ConfigurableFeatures.AutorunConfigOption? = nil
        public var checkForUpdatesIsEnabled: Bool = false
        public var cloudSettingsTransferIsEnabled: Bool = false
        public var resetSettingsIsEnabled: Bool = false
        public var morphicBarVisibilityAfterLogin: ConfigurableFeatures.MorphicBarVisibilityAfterLoginOption? = nil
        public var extraMorphicBarItems: [MorphicBarExtraItem] = []
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
                if (extraItem.type == nil) || (extraItem.label == nil) || (extraItem.tooltipHeader == nil) {
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

                let extraMorphicBarItem = MorphicBarExtraItem(
                    type: extraItem.type,
                    label: extraItem.label,
                    tooltipHeader: extraItem.tooltipHeader,
                    tooltipText: extraItem.tooltipText,
                    url: extraItem.url,
                    function: extraItem.function)
                result.extraMorphicBarItems.append(extraMorphicBarItem)
            }
        }
        
        return result
    }
    
    // MARK: - Updates
    
    private func startCheckingForUpdates() {
	// TODO: check for updates
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
                _ = Display.main?.zoom(to: defaultDisplayZoomPercentage)
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
            switch Session.morphicEdition {
            case .basic:
                break
            case .plus:
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
            }
            
            switch Session.morphicEdition {
            case .basic:
                break
            case .plus:
                self.loginMenuItem?.isHidden = false
                self.selectCommunityMenuItem.isHidden = true
            }
            self.logoutMenuItem?.isHidden = true
        }
    }
    
    var copySettingsWindowController: NSWindowController?
    
    @IBAction
    func showCopySettingsWindow(_ sender: Any?) {
        if copySettingsWindowController == nil {
            copySettingsWindowController = CopySettingsWindowController(windowNibName: "CopySettingsWindow")
        }
        copySettingsWindowController?.window?.makeKeyAndOrderFront(sender)
        copySettingsWindowController?.window?.delegate = self
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
    
    @IBAction func menuBarExtraAboutMorphicMenuItemClicked(_ sender: NSMenuItem) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
            Countly.sharedInstance().recordEvent("aboutMorphic", segmentation: segmentation)
        }
        showAboutBox()
    }

    @IBAction func morphicBarIconAboutMorphicMenuItemClicked(_ sender: NSMenuItem) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
            Countly.sharedInstance().recordEvent("aboutMorphic", segmentation: segmentation)
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
        Countly.sharedInstance().recordEvent("quit", segmentation: segmentation)

        quitApplication()
    }
    
    @IBAction func menuBarExtraQuitApplicationMenuItemClicked(_ sender: NSMenuItem) {
        let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
        Countly.sharedInstance().recordEvent("quit", segmentation: segmentation)

        quitApplication()
    }

    @IBAction func morphicBarIconQuitApplicationMenuItemClicked(_ sender: NSMenuItem) {
        let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
        Countly.sharedInstance().recordEvent("quit", segmentation: segmentation)

        quitApplication()
    }

    func quitApplication() {
        // immediately hide our MorphicBar window
        morphicBarWindow?.setIsVisible(false)
        
        switch Session.morphicEdition {
        case .basic:
            // terminate our dock app (if it's running)
            terminateDockAppIfRunning()
        case .plus:
            break
        }

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
        switch Session.morphicEdition {
        case .basic:
            break
        case .plus:
            return .terminateNow
        }

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
                Countly.sharedInstance().recordEvent("autorunAfterLoginDisabled")
            }
            _ = setMorphicAutostartAtLogin(false)
        case .off:
            defer {
                Countly.sharedInstance().recordEvent("autorunAfterLoginEnabled")
            }
            _ = setMorphicAutostartAtLogin(true)
        default:
            fatalError("invalid code path")
        }
    }
    
    func updateMorphicAutostartAtLoginMenuItems() {
        let autostartAtLogin = self.morphicAutostartAtLogin()
        automaticallyStartMorphicAtLoginMenuItem?.state = (autostartAtLogin ? .on : .off)
        morphicBarWindow?.morphicBarViewController.automaticallyStartMorphicAtLoginMenuItem.state = (autostartAtLogin ? .on : .off)
    }
    
    func morphicAutostartAtLogin() -> Bool {
        // NOTE: in the future, we may want to save the autostart state in UserDefaults (although perhaps not in "UserDefaults.morphic"); we'd need to store in the UserDefaults area which was specific to _this_ user and _this_ application (including differentiating between Morphic and Morphic Community if there are two apps for that
        // If we do switch to UserDefaults in the future, we will effectively capture its "autostart enabled" state when we set it and then trust that the user hasn't used launchctl at the command-line to reverse our state; the worst-case scenario with this approach should be that our corresponding menu item checkbox is out of sync with system reality, and a poweruser who uses launchctl could simply uncheck and then recheck the menu item (or use launchctl) to reenable autostart-at-login for Morphic
        
        // NOTE: SMCopyAllJobDictionaries (the API typically used to get the list of login items) was deprecated in macOS 10.10 but has not been replaced.  It is technically still available as of macOS 10.15.
        guard let userLaunchedApps = SMCopyAllJobDictionaries(kSMDomainUserLaunchd)?.takeRetainedValue() as? [[String: Any]] else {
            return false
        }
        for userLaunchedApp in userLaunchedApps {
            switch Session.morphicEdition {
            case .basic:
                switch userLaunchedApp["Program"] as? String {
                case "org.raisingthefloor.MorphicLauncher",
                     "org.raisingthefloor.MorphicLauncher-Debug":
                    return true
                default:
                    break
                }
            case .plus:
                switch userLaunchedApp["Program"] as? String {
                case "org.raisingthefloor.MorphicCommunityLauncher",
                     "org.raisingthefloor.MorphicCommunityLauncher-Debug":
                    return true
                default:
                    break
                }
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
        
        switch Session.morphicEdition {
        case .basic:
            #if DEBUG
                success = SMLoginItemSetEnabled("org.raisingthefloor.MorphicLauncher-Debug" as CFString, autostartAtLogin)
            #else
                success = SMLoginItemSetEnabled("org.raisingthefloor.MorphicLauncher" as CFString, autostartAtLogin)
            #endif
        case .plus:
            #if DEBUG
                success = SMLoginItemSetEnabled("org.raisingthefloor.MorphicCommunityLauncher-Debug" as CFString, autostartAtLogin)
            #else
                success = SMLoginItemSetEnabled("org.raisingthefloor.MorphicCommunityLauncher" as CFString, autostartAtLogin)
            #endif
        }
        
        // NOTE: in the future, we may want to save the autostart state in UserDefaults (although perhaps not in "UserDefaults.morphic"); we'd need to store in the UserDefaults area which was specific to _this_ user and _this_ application (including differentiating between Morphic and Morphic Community if there are two apps for that
        
        // update the appropriate menu items to match
        if success == true {
            automaticallyStartMorphicAtLoginMenuItem?.state = (autostartAtLogin ? .on : .off)
            morphicBarWindow?.morphicBarViewController.automaticallyStartMorphicAtLoginMenuItem.state = (autostartAtLogin ? .on : .off)
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
                Countly.sharedInstance().recordEvent("stopKeyRepeatOff")
            case false:
                Countly.sharedInstance().recordEvent("stopKeyRepeatOn")
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
        morphicBarWindow?.morphicBarViewController.turnOffKeyRepeatMenuItem.state = keyRepeatIsEnabled ? .off : .on
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

        switch Session.morphicEdition {
        case .basic:
            if currentModifierKeys.rawValue & NSEvent.ModifierFlags.option.rawValue != 0 {
                self.hideQuickHelpMenuItem.isHidden = false
                self.morphicBarWindow?.morphicBarViewController.hideQuickHelpMenuItem.isHidden = false
            } else {
                self.hideQuickHelpMenuItem.isHidden = true
                self.morphicBarWindow?.morphicBarViewController.hideQuickHelpMenuItem.isHidden = true
            }
        case .plus:
            break
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
        morphicBarWindow?.morphicBarViewController.hideQuickHelpMenuItem.state = (hideQuickHelpAtLogin ? .on : .off)
    }

    func hideQuickHelpState() -> Bool {
        let morphicBarShowsHelp = Session.shared.bool(for: .morphicBarShowsHelp) ?? MorphicBarWindow.showsHelpByDefault
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
                Countly.sharedInstance().recordEvent("showMorphicBarAfterLoginDisabled")
            }
            showMorphicBarAtStart = false
        case .off:
            defer {
                Countly.sharedInstance().recordEvent("showMorphicBarAfterLoginEnabled")
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
        morphicBarWindow?.morphicBarViewController.showMorphicBarAtStartMenuItem.state = (showMorphicBarAtStart ? .on : .off)
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
        statusItem.menu = menu
        
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
            statusItem.menu = menu
        }
    }
    
    @objc
    func statusItemMousePressed(sender: NSStatusBarButton?) {
        guard let currentEvent = NSApp.currentEvent else {
            return
        }

        if currentEvent.type == .leftMouseDown {
            // when the left mouse button is pressed, toggle the MorphicBar's visibility (i.e. show/hide the MorphicBar)

            switch Session.morphicEdition {
            case .basic:
                let morphicBarWindowWasVisible = morphicBarWindow != nil
                defer {
                    let segmentation: [String: String] = ["eventSource": "trayIconClick"]
                    if morphicBarWindowWasVisible == true {
                        Countly.sharedInstance().recordEvent("morphicBarHide", segmentation: segmentation)
                    } else {
                        Countly.sharedInstance().recordEvent("morphicBarShow", segmentation: segmentation)
                    }
                }
                toggleMorphicBar(sender)
            case .plus:
                //
                if (Session.shared.user == nil) {
                    // NOTE: if we're running MorphicCommunity and there is no actively logged-in user, then show the login instead of toggling the MorphicBar
                    self.launchConfigurator(argument: "login")
                } else {
                    toggleMorphicBar(sender)
                }
            }
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
                Countly.sharedInstance().recordEvent("showMenu", segmentation: segmentation)
            }
            statusItem.menu = self.menu
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
        switch Session.morphicEdition {
        case .basic:
            if let _ = ConfigurableFeatures.shared.autorunConfig {
                self.automaticallyStartMorphicAtLoginMenuItem.isHidden = true
            }
            if let _ = ConfigurableFeatures.shared.morphicBarVisibilityAfterLogin {
                self.showMorphicBarAtStartMenuItem.isHidden = true
            }
        case .plus:
            break
        }

        switch Session.morphicEdition {
        case .basic:
            // NOTE: the default menu items are already configured for Morphic Basic
        break
        case .plus:
            // configure menu items to match the Morphic Community scheme
            copySettingsBetweenComputersMenuItem?.isHidden = true
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
        Countly.sharedInstance().recordEvent("morphicBarShow", segmentation: segmentation)
        showMorphicBar(sender)
    }
    
    func showMorphicBar(_ sender: Any?) {
        if morphicBarWindow == nil {
            morphicBarWindow = MorphicBarWindow()
            self.updateMorphicAutostartAtLoginMenuItems()
            self.updateShowMorphicBarAtStartMenuItems()
            self.updateHideQuickHelpMenuItems()
            switch Session.morphicEdition {
            case .basic:
                morphicBarWindow?.orientation = .horizontal
            case .plus:
                morphicBarWindow?.orientation = .vertical
            }
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
        Countly.sharedInstance().recordEvent("morphicBarHide", segmentation: segmentation)
        hideMorphicBar(sender)
    }

    @IBAction
    func morphicBarIconHideMorphicBarMenuItemClicked(_ sender: NSMenuItem) {
        let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
        Countly.sharedInstance().recordEvent("morphicBarHide", segmentation: segmentation)
        hideMorphicBar(sender)
    }

    func morphicBarCloseButtonPressed() {
        let segmentation = ["eventSource": "closeButton"]
        Countly.sharedInstance().recordEvent("morphicBarHide", segmentation: segmentation)
        hideMorphicBar(nil)
    }
    
    func hideMorphicBar(_ sender: Any?) {
        currentKeyboardSelectedQuickHelpViewController = nil

        morphicBarWindow?.close()
        switch Session.morphicEdition {
        case .basic:
            showMorphicBarMenuItem?.isHidden = false
        case .plus:
            if Session.shared.user != nil {
                showMorphicBarMenuItem?.isHidden = false
            } else {
                showMorphicBarMenuItem?.isHidden = true
            }
        }
        hideMorphicBarMenuItem?.isHidden = true
        QuickHelpWindow.hide()
        if Session.shared.bool(for: .morphicBarVisible) != false {
            Session.shared.set(false, for: .morphicBarVisible)
        }
    }
    
    //
    
    @IBAction
    func menuBarExtraLearnAboutMorphicMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
            Countly.sharedInstance().recordEvent("learnAboutMorphic", segmentation: segmentation)
        }

        learnAboutMorphicClicked()
    }

    @IBAction
    func morphicBarIconLearnAboutMorphicMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
            Countly.sharedInstance().recordEvent("learnAboutMorphic", segmentation: segmentation)
        }
        
        learnAboutMorphicClicked()
    }
    
    func learnAboutMorphicClicked() {
        let url = URL(string: "https://morphic.org")!
        NSWorkspace.shared.open(url)
    }

    @IBAction
    func menuBarExtraQuickDemoMoviesMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
            Countly.sharedInstance().recordEvent("quickDemoVideo", segmentation: segmentation)
        }
        
        quickDemoMoviesClicked()
    }
    
    @IBAction
    func morphicBarIconQuickDemoMoviesMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
            Countly.sharedInstance().recordEvent("quickDemoVideo", segmentation: segmentation)
        }

        quickDemoMoviesClicked()
    }
    
    func quickDemoMoviesClicked() {
        let url = URL(string: "https://morphic.org/movies/main")!
        NSWorkspace.shared.open(url)
    }

    @IBAction
    func menuBarExtraOtherHelpfulThingsMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .trayIcon)
            Countly.sharedInstance().recordEvent("otherHelpfulThings", segmentation: segmentation)
        }
        
        otherHelpfulThingsClicked()
    }
    
    @IBAction
    func morphicBarIconOtherHelpfulThingsMenuItemClicked(_ sender: NSMenuItem?) {
        defer {
            let segmentation = createMenuOpenedSourceSegmentation(menuOpenedSource: .morphicBarIcon)
            Countly.sharedInstance().recordEvent("otherHelpfulThings", segmentation: segmentation)
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
        Countly.sharedInstance().recordEvent("systemSettings", segmentation: segmentation)
//        Countly.sharedInstance().recordEvent("systemSettings" + settingsCategoryName)
    }
    
    //

    var currentKeyboardSelectedQuickHelpViewController: NSViewController? = nil
    
    func windowDidBecomeKey(_ notification: Notification) {
        morphicBarWindow?.windowIsKey = true
        if let currentKeyboardSelectedQuickHelpViewController = currentKeyboardSelectedQuickHelpViewController {
            QuickHelpWindow.show(viewController: currentKeyboardSelectedQuickHelpViewController)
        }
    }
     
    func windowDidResignKey(_ notification: Notification) {
        morphicBarWindow?.windowIsKey = false
        QuickHelpWindow.hide()
    }
     
    func windowWillClose(_ notification: Notification) {
        morphicBarWindow = nil
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
        
        let morphicConfiguratorAppName: String
        switch Session.morphicEdition {
        case .basic:
            morphicConfiguratorAppName = "MorphicConfigurator.app"
        case .plus:
            morphicConfiguratorAppName = "MorphicCommunityConfigurator.app"
        }
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
