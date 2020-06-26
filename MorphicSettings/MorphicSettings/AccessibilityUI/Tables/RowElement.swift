//
//  RowElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class RowElement: UIElement{
    
    public func select() -> Bool{
        return accessibilityElement.setValue(true, forAttribute: .selected)
    }
    
    public func cell(at index: Int) -> CellElement?{
        guard let cells = accessibilityElement.children()?.filter({ $0.role == .cell }) else{
            return nil
        }
        guard index > 0 else{
            return nil
        }
        guard index < cells.count else{
            return nil
        }
        return CellElement(accessibilityElement: cells[index])
    }
    
}
