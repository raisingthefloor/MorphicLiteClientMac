//
//  WorkspaceElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

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
    
}
