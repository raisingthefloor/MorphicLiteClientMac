//
//  TableElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class TableElement: UIElement{
    
    public func row(titled: String) -> RowElement?{
        for row in rows{
            if row.cell(at: 0)?.text == titled{
                return row
            }
        }
        return nil
    }
    
    public var rows: [RowElement]{
        guard let accessibilityRows: [MorphicA11yUIElement] = accessibilityElement.values(forAttribute: .rows) else{
            return []
        }
        return accessibilityRows.map{ RowElement(accessibilityElement: $0) }
    }
    
}
