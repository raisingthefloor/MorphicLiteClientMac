//
//  MenuItemElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 7/4/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class MenuItemElement: UIElement{
    
    public var title: String? {
        accessibilityElement.value(forAttribute: .title)
    }
    
    public func select() -> Bool{
        guard accessibilityElement.perform(action: .press) else{
            return false
        }
        return true
    }
    
}
