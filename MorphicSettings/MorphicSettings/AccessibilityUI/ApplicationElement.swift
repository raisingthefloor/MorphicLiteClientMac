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

import Foundation
import Cocoa
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "ApplicationElement")

public class ApplicationElement: UIElement {
    
    public static func from(bundleIdentifier: String) -> ApplicationElement {
        switch bundleIdentifier {
        case SystemPreferencesElement.bundleIdentifier:
            return SystemPreferencesElement()
        default:
            return ApplicationElement(bundleIdentifier: bundleIdentifier)
        }
    }
    
    public init(bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
        super.init(accessibilityElement: nil)
    }
    
    public required init(accessibilityElement: MorphicA11yUIElement?) {
        fatalError("Cannot create an application element from an a11 element")
    }
    
    public var bundleIdentifier: String
    
    private var runningApplication: NSRunningApplication?
    
    public func open(completion: @escaping (_ success: Bool) -> Void) {
        open(hide: true, completion: completion)
    }
    
    public func open(hide: Bool, attachOnly: Bool = false, completion: @escaping (_ success: Bool) -> Void) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            os_log(.error, log: logger, "Failed to find url for application %{public}s", bundleIdentifier)
            completion(false)
            return
        }
        guard runningApplication == nil || runningApplication!.isTerminated else {
            completion(true)
            return
        }
        let complete = {
            let runningApplication: NSRunningApplication! = self.runningApplication
            AsyncUtils.wait(atMost: 5.0, for: { runningApplication.isFinishedLaunching }) {
                success in
                guard success else {
                    os_log(.error, log: logger, "Timeout waiting for isFinishLaunching")
                    completion(false)
                    return
                }
                //
                var accessibilityElement: MorphicA11yUIElement? = nil
                do {
                    accessibilityElement = try MorphicA11yUIElement.createFromProcess(processIdentifier: runningApplication.processIdentifier)
                } catch MorphicA11yAuthorizationError.notAuthorized {
                    // prompt the user to grant our application accessibility permissions
                    MorphicA11yAuthorization.promptUserToGrantAuthorization()
                } catch {
                    // no other errors should be throws by MorphicA11yUIElement.createFromProcess
                }
                guard accessibilityElement != nil else {
                    os_log(.error, log: logger, "Failed to get automation element for application")
                    completion(false)
                    return
                }
                self.accessibilityElement = accessibilityElement
                completion(true)
            }
        }
        runningApplication = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        if runningApplication == nil {
            if(attachOnly) {
                completion(false)
                return
            }
            MorphicProcess.openProcess(at: url, arguments: [], activate: false, hide: hide) {
                (runningApplication, error) in
                DispatchQueue.main.async {
                    guard runningApplication != nil else {
                        os_log(.error, log: logger, "Failed to launch application")
                        completion(false)
                        return
                    }
                    WorkspaceElement.shared.launchedApplications.append(self)
                    self.runningApplication = runningApplication
                    complete()
                }
            }
        } else {
            complete()
        }
    }
    
    public func terminate() throws {
        guard let runningApplication = self.runningApplication else {
            return
        }
        guard runningApplication.isTerminated == false else {
            return
        }
        if runningApplication.terminate() == false {
            throw MorphicError()
        }
    }
    
    public var mainWindow: WindowElement? {
        get {
            guard accessibilityElement != nil else {
                return nil
            }
            guard let mainWindow: MorphicA11yUIElement = accessibilityElement.value(forAttribute: .mainWindow) else {
                return nil
            }
            return WindowElement(accessibilityElement: mainWindow)
        }
    }
    
    public var windows: [WindowElement]? {
        get {
            guard accessibilityElement != nil else {
                return nil
            }
            guard let windows: [MorphicA11yUIElement] = accessibilityElement.values(forAttribute: .windows) else {
                return nil
            }

            var windowElements: [WindowElement] = []
            for window in windows {
                let windowElement = WindowElement(accessibilityElement: window)
                windowElements.append(windowElement)
            }
            return windowElements
        }
    }
    
}
