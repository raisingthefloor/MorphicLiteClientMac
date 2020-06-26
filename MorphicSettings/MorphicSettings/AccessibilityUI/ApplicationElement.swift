//
//  ApplicationElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import Cocoa

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
        guard let bundle = Bundle(identifier: bundleIdentifier) else{
            completion(false)
            return
        }
        guard runningApplication == nil || runningApplication!.isTerminated else{
            completion(true)
            return
        }
        let complete = {
            guard let runningApplication = self.runningApplication else{
                completion(false)
                return
            }
            guard let accessibilityElement = MorphicA11yUIElement.createFromProcess(processIdentifier: runningApplication.processIdentifier) else{
                completion(false)
                return
            }
            self.runningApplication = nil
            self.accessibilityElement = accessibilityElement
            completion(true)
        }
        runningApplication = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        if runningApplication == nil{
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            config.hides = true
            NSWorkspace.shared.openApplication(at: bundle.bundleURL, configuration: config){
                (runningApplication, error) in
                self.runningApplication = runningApplication
                complete()
            }
        }else{
            complete()
        }
    }
    
    public func terminate() -> Bool{
        runningApplication?.terminate() ?? false
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
