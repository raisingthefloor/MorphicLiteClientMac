//
//  ApplicationElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import Cocoa
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "ApplicationElement")

public class ApplicationElement: UIElement{
    
    public static func from(bundleIdentifier: String) -> ApplicationElement{
        switch bundleIdentifier{
        case "com.apple.systempreferences":
            return SystemPreferencesElement()
        default:
            return ApplicationElement(bundleIdentifier: bundleIdentifier)
        }
    }
    
    public init(bundleIdentifier: String){
        self.bundleIdentifier = bundleIdentifier
        super.init(accessibilityElement: nil)
    }
    
    public required init(accessibilityElement: MorphicA11yUIElement?) {
        fatalError("Cannot create an application element from an a11 element")
    }
    
    public var bundleIdentifier: String
    
    private var runningApplication: NSRunningApplication?
    
    public func open(completion: @escaping (_ success: Bool) -> Void){
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else{
            os_log(.error, log: logger, "Failed to find url for application %{public}s", bundleIdentifier)
            completion(false)
            return
        }
        guard runningApplication == nil || runningApplication!.isTerminated else{
            completion(true)
            return
        }
        let complete = {
            let runningApplication: NSRunningApplication! = self.runningApplication
            self.wait(atMost: 5.0, for: { runningApplication.isFinishedLaunching }){
                success in
                guard success else{
                    os_log(.error, log: logger, "Timeout waiting for isFinishLaunching")
                    completion(false)
                    return
                }
                guard let accessibilityElement = MorphicA11yUIElement.createFromProcess(processIdentifier: runningApplication.processIdentifier) else{
                    os_log(.error, log: logger, "Failed to get automation element for application")
                    completion(false)
                    return
                }
                self.accessibilityElement = accessibilityElement
                completion(true)
            }
        }
        runningApplication = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        if runningApplication == nil{
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            config.hides = true
            NSWorkspace.shared.openApplication(at: url, configuration: config){
                (runningApplication, error) in
                DispatchQueue.main.async {
                    guard runningApplication != nil else{
                        os_log(.error, log: logger, "Failed to launch application")
                        completion(false)
                        return
                    }
                    WorkspaceElement.shared.launchedApplications.append(self)
                    self.runningApplication = runningApplication
                    complete()
                }
            }
        }else{
            complete()
        }
    }
    
    public func terminate() -> Bool{
        guard let runningApplication = runningApplication else{
            return true
        }
        guard !runningApplication.isTerminated else{
            return true
        }
        return runningApplication.terminate()
    }
    
    public var mainWindow: WindowElement?{
        get{
            guard accessibilityElement != nil else{
                return nil
            }
            guard let mainWindow: MorphicA11yUIElement = accessibilityElement.value(forAttribute: .mainWindow) else{
                return nil
            }
            return WindowElement(accessibilityElement: mainWindow)
        }
    }
    
}
