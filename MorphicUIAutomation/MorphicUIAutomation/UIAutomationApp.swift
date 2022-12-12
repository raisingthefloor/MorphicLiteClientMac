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
import MorphicCore
import MorphicMacOSNative

public class UIAutomationApp {
    public let runningApplication: NSRunningApplication
    
    private init(runningApplication: NSRunningApplication) {
        self.runningApplication = runningApplication
    }
    
    public enum LaunchError: Error {
        case couldNotResolveBundleIdentifierToUrl
        case osError(Error)
    }
    // NOTE: we intentionally do not support arguments in this implementation of the function because we return success if the application is already launched
    public static func launchOrAttach(bundleIdentifier: String, waitUntilFinishedLaunching: TimeInterval, hideIfLaunched: Bool = true) async throws -> (uiAutomationApp: UIAutomationApp, isFinishedLaunching: Bool) {
        // determine if the application is already running
        if let runningApplication = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            // NOTE: a runningApplication retrieved from NSRunningApplication should never be terminated, but we check anyway out of an abundance of caution
            if runningApplication.isTerminated == false {
                // the application is already running

                // wait until the application is open (so that we can capture its main window)
                let applicationIsRunning = await AsyncUtils.wait(atMost: waitUntilFinishedLaunching, for: { runningApplication.isFinishedLaunching })

                // return an instance of the attached application (along with a flag indiciating if it has fully launched yet or not)
                let uiAutomationApp = UIAutomationApp(runningApplication: runningApplication)
                return (uiAutomationApp: uiAutomationApp, isFinishedLaunching: applicationIsRunning)
            }
        }

        // if the app was not already running, launch it now
        let result = try await UIAutomationApp.launch(bundleIdentifier: bundleIdentifier, arguments: [], waitUntilFinishedLaunching: waitUntilFinishedLaunching, activate: false, hide: hideIfLaunched)
        return result
    }
    //
    // NOTE: this implementation opens the app using the provided arguments; it does not check to see if the app is already started
    public static func launch(bundleIdentifier: String, arguments: [String], waitUntilFinishedLaunching: TimeInterval, activate: Bool, hide: Bool) async throws -> (uiAutomationApp: UIAutomationApp, isFinishedLaunching: Bool) {
        guard waitUntilFinishedLaunching >= 0.0 else {
            fatalError("Argument 'waitUntilFinishedLaunching' cannot be a negative value")
        }
        
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            throw LaunchError.couldNotResolveBundleIdentifierToUrl
        }

        // open the process; this will wait until the process has started to launch
        let launchedApplication: NSRunningApplication
        do {
            launchedApplication = try await MorphicProcess.openProcess(at: url, arguments: arguments, activate: activate, hide: hide)
        } catch let error as MorphicProcess.OpenProcessError {
            switch error {
            case MorphicProcess.OpenProcessError.osError(let error):
                throw LaunchError.osError(error)
            }
        }
        
        // wait until the application is open (so that we can capture its main window)
        let applicationIsRunning = await AsyncUtils.wait(atMost: waitUntilFinishedLaunching, for: { launchedApplication.isFinishedLaunching == true })
        
        // return an instance of our running application (along with a flag indiciating if it has fully launched yet or not)
        let uiAutomationApp = UIAutomationApp(runningApplication: launchedApplication)
        return (uiAutomationApp: uiAutomationApp, isFinishedLaunching: applicationIsRunning)
    }

    // MARK: - Instance-specific runtime functionality
    
    public func waitUntilFinishedLaunching(_ timeInterval: TimeInterval) async -> Bool {
        guard timeInterval >= 0.0 else {
            fatalError("Argument 'timeInterval' cannot be a negative value")
        }
        
        let result = await AsyncUtils.wait(atMost: timeInterval, for: { self.runningApplication.isFinishedLaunching == true })
        return result
    }

    public func terminate() throws {
        if runningApplication.isTerminated == true {
            return
        }
        if runningApplication.terminate() == false {
            throw MorphicError.unspecified
        }
    }
    
    // MARK: - Accessibility UI
    
    public enum AccessibilityError: Error {
        case isNotFinishedLaunching
        case isTerminated
        case notAuthorized // NOTE: if the caller receives this error, the program should probably promptthe user to grand authorization (by calling MorphicA11yAuthorization.promptUserToGrantAuthorization() or otherwise)
        case unspecified
    }
    //
    private func accessibilityUiElement() throws -> MorphicA11yUIElement {
        if self.runningApplication.isTerminated == true {
            throw AccessibilityError.isTerminated
        }
        if self.runningApplication.isFinishedLaunching == false {
            throw AccessibilityError.isNotFinishedLaunching
        }
        
        var result: MorphicA11yUIElement
        do {
            result = try MorphicA11yUIElement.createFromProcess(processIdentifier: self.runningApplication.processIdentifier)
        } catch MorphicA11yAuthorizationError.notAuthorized {
            throw AccessibilityError.notAuthorized
        } catch /* InitError, etc. */ {
            throw AccessibilityError.unspecified
        }

        return result
    }
    
    // MARK: Application-specific UI elements
    
    private func mainWindow() throws -> WindowUIElement {
        // NOTE: we bubble up any error from the call to accessibilityUiElement()
        let accessibilityUiElement = try self.accessibilityUiElement()
        
        // get the main window element
        var mainWindowUiElement: MorphicA11yUIElement
        do {
            mainWindowUiElement = try accessibilityUiElement.value(forAttribute: .mainWindow)
        } catch {
            throw AccessibilityError.unspecified
        }
        
        return WindowUIElement(accessibilityUiElement: mainWindowUiElement)
    }
    
    public func windows() throws -> [WindowUIElement] {
        // NOTE: we bubble up any error from the call to accessibilityUiElement()
        let accessibilityUiElement = try self.accessibilityUiElement()
        
        // get the main window element
        var windowUiElements: [MorphicA11yUIElement]
        do {
            windowUiElements = try accessibilityUiElement.values(forAttribute: .windows)
        } catch {
            throw AccessibilityError.unspecified
        }

        var result: [WindowUIElement] = []
        for windowUiElement in windowUiElements {
            let element = WindowUIElement(accessibilityUiElement: windowUiElement)
            result.append(element)
        }
        return result
    }

}
