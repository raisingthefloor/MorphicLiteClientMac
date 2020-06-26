//
//  WindowElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class WindowElement: UIElement{
    
    public var toolbar: ToolbarElement?{
        get{
            guard let toolbar = accessibilityElement.children()?.firstAndOnly(where: { $0.role == .toolbar }) else{
                return nil
            }
            return ToolbarElement(accessibilityElement: toolbar)
        }
    }
    
    public func raise() -> Bool{
        return accessibilityElement.perform(action: .raise)
    }
    
    public var title: String?{
        get{
            return accessibilityElement.value(forAttribute: .title)
        }
    }
}
