// Copyright 2020 Raising the Floor - International
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Cocoa
import MorphicCore

public class KeyboardPreferencesElement: UIElement {
    
    public func select(tabTitled title: String) throws {
        guard let _ = try tabGroup?.select(tabTitled: title) else {
            throw MorphicError()
        }
    }
    
    public func select(tableRowTitled rowTitle: String, ofTableTitled tableTitle: String) throws {
        guard let table = table(titled: tableTitle) else {
            throw MorphicError()
        }
        var targetRow: RowElement? = nil
        for row in table.rows {
            guard let rowChildren = row.accessibilityElement.children() else {
                continue
            }
            for rowChild in rowChildren {
                if let childRoleAsString: String = rowChild.value(forAttribute: .role) {
                    let childRole = NSAccessibility.Role(rawValue: childRoleAsString)
                    if childRole == .staticText {
                        if let currentRowTitle: String = rowChild.value(forAttribute: .value) {
                            if currentRowTitle == rowTitle {
                                targetRow = row
                                break
                            }
                        }
                    }
                }
            }
            
            if targetRow != nil {
                break 
            }
        }
        guard let _ = targetRow else {
            throw MorphicError()
        }

        try targetRow!.select()
    }

}
