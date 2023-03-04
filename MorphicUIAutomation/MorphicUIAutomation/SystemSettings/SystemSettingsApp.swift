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

public class SystemSettingsApp {
    // NOTE: prior to macOS 13, the app was named "System Preferences"; the bundle identifier is "com.apple.systempreferences" under all tested versions of macOS (10.14 through 13.0, as of 2022-Dec)
    public static let bundleIdentifier = "com.apple.systempreferences"

    private let uiAutomationApp: UIAutomationApp
    
    private init(uiAutomationApp: UIAutomationApp) {
        self.uiAutomationApp = uiAutomationApp
    }
    
    public static func isRunningApplication() -> Bool {
        UIAutomationApp.isRunningApplication(bundleIdentifier: SystemSettingsApp.bundleIdentifier)
    }
    
    public static func launchOrAttach(waitUntilFinishedLaunching: TimeInterval = 0.0) async throws -> (app: SystemSettingsApp, launchedSystemSettingsApp: Bool) {
        let uiAutomationApp: UIAutomationApp
        let launchedSystemSettingsApp: Bool
        do {
            (uiAutomationApp, launchedSystemSettingsApp, _) = try await UIAutomationApp.launchOrAttach(bundleIdentifier: SystemSettingsApp.bundleIdentifier, waitUntilFinishedLaunching: waitUntilFinishedLaunching)
        } catch let error {
            throw error // UIAutomationApp.LaunchError
        }
                
        let app = SystemSettingsApp(uiAutomationApp: uiAutomationApp)
        return (app: app, launchedSystemSettingsApp: launchedSystemSettingsApp)
    }
    
    public func terminate() throws {
        try self.uiAutomationApp.terminate()
    }
    
    public static func terminate() throws {
        try UIAutomationApp.terminate(bundleIdentifier: SystemSettingsApp.bundleIdentifier)
    }
 
    // MARK: - App process status
    
    public func waitUntilFinishedLaunching(_ timeInterval: TimeInterval) async -> Bool {
        let result = await self.uiAutomationApp.waitUntilFinishedLaunching(timeInterval)
        return result
    }
    
    public func waitUntilMainWindowIsAvailable(_ timeInterval: TimeInterval) async throws -> Bool {
        let result = try await self.uiAutomationApp.waitUntilMainWindowIsAvailable(timeInterval)
        return result
    }

    public var isFinishedLaunching: Bool {
        return self.uiAutomationApp.runningApplication.isFinishedLaunching
    }

    public var isTerminated: Bool {
        return self.uiAutomationApp.runningApplication.isTerminated
    }
    
    public func activate(options: NSApplication.ActivationOptions) -> Bool {
        return uiAutomationApp.runningApplication.activate(options: options)
    }

    // MARK: - App UI logic
    
    public static func launchOrAttachThenNavigateTo(_ view: SystemSettingsView, waitUntilFinishedLaunching: TimeInterval) async throws -> (groupUIElementWrapper: SystemSettingsGroupUIElementWrapper?, launchedSystemSettingsApp: Bool) {
        let waitUntilFinishedLaunchingDeadline = ProcessInfo.processInfo.systemUptime + waitUntilFinishedLaunching

        let systemSettingsApp: SystemSettingsApp
        let launchedSystemSettingsApp: Bool
        do {
            (systemSettingsApp, launchedSystemSettingsApp) = try await SystemSettingsApp.launchOrAttach(waitUntilFinishedLaunching: waitUntilFinishedLaunching)
        } catch let error {
            throw error // UIAutomationApp.LaunchError
        }
        // make sure that our application is launched
        guard systemSettingsApp.isFinishedLaunching == true else {
            throw SystemSettingsApp.NavigationError.unspecified
        }
        
        // make sure that the main window is available
        let waitUntilMainWindowIsAvailableInterval = Double.maximum(waitUntilFinishedLaunchingDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let mainWindowIsAvailable: Bool
        do {
            mainWindowIsAvailable = try await systemSettingsApp.waitUntilMainWindowIsAvailable(waitUntilMainWindowIsAvailableInterval)
        } catch let error {
            throw error
        }
        guard mainWindowIsAvailable == true else {
            throw SystemSettingsApp.NavigationError.unspecified
        }
        
        let result: SystemSettingsGroupUIElementWrapper?
        do {
            result = try await systemSettingsApp.navigateTo(view)
        } catch let error {
            throw error
        }
        
        return (groupUIElementWrapper: result, launchedSystemSettingsApp: launchedSystemSettingsApp)
    }
    
    public enum NavigationError: Error {
        case unspecified
    }
    
    public enum SystemSettingsView {
        case accessibility
        case accessibilityDisplay
        case accessibilitySpokenContent
        case accessibilityZoom
        case appearance
        case colorFilters
        case contrast
        case displayBrightness
        case general
        case keyboard
        case languageAndRegion
        case mouse
        case nightShift
        case pointerSize
        case screenshotKeyboardShortcuts
        case speech
        case trackpad
    }
    public func navigateTo(_ view: SystemSettingsView, waitAtMost: TimeInterval = TimeInterval(2.0)) async throws -> SystemSettingsGroupUIElementWrapper? {
        let windowUIElement: WindowUIElement?
        do {
            windowUIElement = try self.uiAutomationApp.mainWindow()
        } catch let error {
            throw error // UIAutomationApp.AccessibilityError
        }
        guard let windowUIElement = windowUIElement else {
            throw NavigationError.unspecified
        }
        
        // wait for the main category (or subcategory) navigation up to "waitAtMost" (or 2 seconds, whichever is shorter)
        let mainCategoryNavigationWaitMaximum = TimeInterval.minimum(waitAtMost, TimeInterval(2.0))
        let subCategoryNavigationWaitMaximum = TimeInterval.minimum(waitAtMost, TimeInterval(2.0))
        
        var groupUIElementWrapper: SystemSettingsGroupUIElementWrapper? = nil
        
        switch view {
        case .accessibility:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                do {
                    let groupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.accessibility, waitAtMost: mainCategoryNavigationWaitMaximum)
                    groupUIElementWrapper = SystemSettingsAccessibilityCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: groupUIElement)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .accessibilityDisplay:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                let accessibilityCategoryGroupUIElement: GroupUIElement
                do {
                    accessibilityCategoryGroupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.accessibility, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
                
                let accessibilityCategoryPane = SystemSettingsAccessibilityCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: accessibilityCategoryGroupUIElement)
                do {
                    let groupUIElement = try await accessibilityCategoryPane.navigateTo(.display, waitAtMost: subCategoryNavigationWaitMaximum)
                    groupUIElementWrapper = SystemSettingsAccessibilityDisplayCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: groupUIElement)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .accessibilitySpokenContent:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                let accessibilityCategoryGroupUIElement: GroupUIElement
                do {
                    accessibilityCategoryGroupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.accessibility, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
                
                let accessibilityCategoryPane = SystemSettingsAccessibilityCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: accessibilityCategoryGroupUIElement)
                do {
                    let groupUIElement = try await accessibilityCategoryPane.navigateTo(.spokenContent, waitAtMost: subCategoryNavigationWaitMaximum)
                    groupUIElementWrapper = SystemSettingsAccessibilitySpokenContentCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: groupUIElement)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .accessibilityZoom:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                let accessibilityCategoryGroupUIElement: GroupUIElement
                do {
                    accessibilityCategoryGroupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.accessibility, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
                
                let accessibilityCategoryPane = SystemSettingsAccessibilityCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: accessibilityCategoryGroupUIElement)
                do {
                    let groupUIElement = try await accessibilityCategoryPane.navigateTo(.zoom, waitAtMost: subCategoryNavigationWaitMaximum)
                    groupUIElementWrapper = SystemSettingsAccessibilityZoomCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: groupUIElement)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .appearance:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                do {
                    _ = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.appearance, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .colorFilters:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                let accessibilityCategoryGroupUIElement: GroupUIElement
                do {
                    accessibilityCategoryGroupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.accessibility, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
                
                let accessibilityCategoryPane = SystemSettingsAccessibilityCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: accessibilityCategoryGroupUIElement)
                do {
                    _ = try await accessibilityCategoryPane.navigateTo(.display, waitAtMost: subCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .contrast:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                let accessibilityCategoryGroupUIElement: GroupUIElement
                do {
                    accessibilityCategoryGroupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.accessibility, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
                
                let accessibilityCategoryPane = SystemSettingsAccessibilityCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: accessibilityCategoryGroupUIElement)
                do {
                    _ = try await accessibilityCategoryPane.navigateTo(.display, waitAtMost: subCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .displayBrightness:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                do {
                    _ = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.displays, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .general:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                do {
                    let groupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.general, waitAtMost: mainCategoryNavigationWaitMaximum)
                    groupUIElementWrapper = SystemSettingsGeneralCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: groupUIElement)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .keyboard:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                do {
                    let groupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.keyboard, waitAtMost: mainCategoryNavigationWaitMaximum)
                    groupUIElementWrapper = SystemSettingsKeyboardCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: groupUIElement)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .languageAndRegion:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                let generalCategoryGroupUIElement: GroupUIElement
                do {
                    generalCategoryGroupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.general, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
                
                let generalCategoryPane = SystemSettingsGeneralCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: generalCategoryGroupUIElement)
                do {
                    _ = try await generalCategoryPane.navigateTo(.languageAndRegion, waitAtMost: subCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .mouse:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                do {
                    _ = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.mouse, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .nightShift:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                let displaysCategoryGroupUIElement: GroupUIElement
                do {
                    displaysCategoryGroupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.displays, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
                
                // find the "Night Shift..." button and press it
                let displaysCategoryPane = SystemSettingsDisplaysCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: displaysCategoryGroupUIElement)
                do {
                    _ = try displaysCategoryPane.pressButton(forButtonWithLabel: SystemSettingsDisplaysCategoryPane_macOS13.Button.nightShift)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .pointerSize:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                let accessibilityCategoryGroupUIElement: GroupUIElement
                do {
                    accessibilityCategoryGroupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.accessibility, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
                
                let accessibilityCategoryPane = SystemSettingsAccessibilityCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: accessibilityCategoryGroupUIElement)
                do {
                    _ = try await accessibilityCategoryPane.navigateTo(.display, waitAtMost: subCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .screenshotKeyboardShortcuts:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                let keyboardCategoryGroupUIElement: GroupUIElement
                do {
                    keyboardCategoryGroupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.keyboard, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
                
                // find the "Keyboard Shortcuts..." button and press it
                let keyboardCategoryPane = SystemSettingsKeyboardCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: keyboardCategoryGroupUIElement)
                do {
                    _ = try keyboardCategoryPane.pressButton(forButtonWithLabel: SystemSettingsKeyboardCategoryPane_macOS13.Button.keyboardShortcuts)
                } catch let error {
                    throw error
                }
                
                // now find the sheet
                var sheet: SheetUIElement?
                let _ = try await AsyncUtils.wait(atMost: subCategoryNavigationWaitMaximum, for: {
                    do {
                        sheet = try systemSettingsMainWindow.sheet()
                    } catch let error {
                        throw error
                    }
                    guard let _ = sheet else {
                        return false
                    }
                    
                    return true
                })
                guard let sheet = sheet else {
                    throw SystemSettingsApp.NavigationError.unspecified
                }
                //
                // get the main group element from the sheet
                let sheetGroupA11yUIElement: MorphicA11yUIElement?
                do {
                    sheetGroupA11yUIElement = try sheet.accessibilityUiElement.onlyChild(role: .group)
                } catch let error {
                    throw error
                }
                guard let sheetGroupA11yElement = sheetGroupA11yUIElement else {
                    throw SystemSettingsApp.NavigationError.unspecified
                }
                //
                // convert SheetGroupA11yUIElement into a SheetGroupUIElement
                let sheetGroupUIElement = GroupUIElement(accessibilityUiElement: sheetGroupA11yElement)
                //
                // create a KeyboardShortcutsSheet object using the sheet's group
                let keyboardShortcutsSheet = SystemSettingsKeyboardShortcutsSheet_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: sheetGroupUIElement)
                //
                do {
                    _ = try await keyboardShortcutsSheet.navigateTo(SystemSettingsKeyboardShortcutsSheet_macOS13.CategoryPane.screenshots, waitAtMost: subCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .speech:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                let accessibilityCategoryGroupUIElement: GroupUIElement
                do {
                    accessibilityCategoryGroupUIElement = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.accessibility, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
                
                let accessibilityCategoryPane = SystemSettingsAccessibilityCategoryPane_macOS13(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: accessibilityCategoryGroupUIElement)
                do {
                    _ = try await accessibilityCategoryPane.navigateTo(.spokenContent, waitAtMost: subCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        case .trackpad:
            if #available(macOS 13.0, *) {
                // macOS 13.0 and later
                let systemSettingsMainWindow = SystemSettingsMainWindow_macOS13(windowUIElement: windowUIElement)
                do {
                    _ = try await systemSettingsMainWindow.navigateTo(SystemSettingsMainWindow_macOS13.CategoryPane.trackpad, waitAtMost: mainCategoryNavigationWaitMaximum)
                } catch let error {
                    throw error
                }
            } else {
                fatalError("Unsupported macOS version")
            }
        }
        
        return groupUIElementWrapper
    }
}
