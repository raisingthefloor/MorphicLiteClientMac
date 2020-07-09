//
//  MenuElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 7/4/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class MenuElement: UIElement{
    
    public func select(itemTitled title: String) -> Bool{
        guard items.first(where: { $0.title == title })?.select() ?? false else{
            return false
        }
        return true
    }
    
    public var items: [MenuItemElement]{
        guard let children = accessibilityElement.children() else{
            return []
        }
        var items = [MenuItemElement]()
        for child in children{
            if child.role == .menuItem{
                items.append(MenuItemElement(accessibilityElement: child))
            }
        }
        return items
    }
    
}
