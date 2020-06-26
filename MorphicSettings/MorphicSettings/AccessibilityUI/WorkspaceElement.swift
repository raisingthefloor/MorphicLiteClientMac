//
//  WorkspaceElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import OSLog

private var logger = OSLog(subsystem: "MorphicSettings", category: "WorkspaceElement")

public class WorkspaceElement: UIElement{
    
    public static let shared = WorkspaceElement(accessibilityElement: nil)
    
    public override func perform(action: Action, completion: @escaping (_ success: Bool, _ nextTarget: UIElement?) -> Void){
        switch action {
        case .launch(let bundleIdentifier):
            let app = ApplicationElement.from(bundleIdentifier: bundleIdentifier)
            app.open{
                success in
                completion(success, app)
            }
        default:
            completion(false, nil)
        }
    }
    
    public var launchedApplications = [ApplicationElement]()
    
    public func closeLaunchedApplications(){
        for application in launchedApplications{
            if !application.terminate(){
                os_log(.error, log: logger, "Failed to terminate application %{public}s", application.bundleIdentifier)
            }
        }
        launchedApplications = []
    }
    
}
