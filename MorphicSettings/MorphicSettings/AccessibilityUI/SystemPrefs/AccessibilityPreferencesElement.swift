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
    
    public func selectDisplay(completion: @escaping (_ success: Bool) -> Void){
        select(category: .display){
            success in
            guard success else{
                completion(false)
                return
            }
            self.wait(atMost: 1.0, for: { self.tabGroup?.tab(titled: "Display") != nil}){
                success in
                completion(success)
            }
        }
    }

    public func select(category identifier: CategoryIdentifier, completion: @escaping (_ success: Bool) -> Void){
        wait(atMost: 1.0, for: { self.categoriesTable != nil }){
            success in
            guard success else{
                completion(false)
                return
            }
            guard let row = self.categoriesTable?.row(titled: identifier.rowTitle) else{
                completion(false)
                return
            }
            let selected = row.select()
            completion(selected)
        }
    }
    
    public func select(tabTitled title: String) -> Bool{
        return tabGroup?.select(tabTitled: title) ?? false
    }
    
}
