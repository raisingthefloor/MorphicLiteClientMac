//
//  AccessibilityPreferencesElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class AccessibilityPreferencesElement: UIElement{
    
    public enum CategoryIdentifier{
        
        case display
        
        public var rowTitle: String{
            get{
                switch self {
                case .display:
                    return "Display"
                }
            }
        }
        
    }
    
    public var categoriesTable: TableElement?{
        return table(titled: "Accessibility features")
    }

    public func select(category identifier: CategoryIdentifier) -> Bool{
        return categoriesTable?.select(rowTitled: identifier.rowTitle) ?? false
    }
    
    public func select(tabTitled title: String) -> Bool{
        return tabGroup?.select(tabTitled: title) ?? false
    }
    
}
