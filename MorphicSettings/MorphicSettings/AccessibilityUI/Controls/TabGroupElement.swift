//
//  UITabElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class TabGroupElement: UIElement{
    
    public func select(tabTitled title: String) -> Bool{
        guard let tab = self.tab(titled: title) else{
            return false
        }
        return tab.select()
    }
    
    public func tab(titled: String) -> TabElement?{
        guard let tabs: [MorphicA11yUIElement] = accessibilityElement.values(forAttribute: .tabs) else{
            return nil
        }
        guard let tab = tabs.first(where: { $0.value(forAttribute: .title) == titled }) else{
            return nil
        }
        return TabElement(accessibilityElement: tab)
    }
    
}
