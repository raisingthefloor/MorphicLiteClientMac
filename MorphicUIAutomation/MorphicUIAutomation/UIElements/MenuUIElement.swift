// Copyright 2020-2023 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/raisingthefloor/morphic-macos/blob/master/LICENSE.txt
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

import Foundation
import MorphicCore
import MorphicMacOSNative

public class MenuUIElement : UIElement {
    public let accessibilityUiElement: MorphicA11yUIElement
    
    public required init(accessibilityUiElement: MorphicA11yUIElement) {
        self.accessibilityUiElement = accessibilityUiElement
    }
    
    public func getItems() throws -> [MenuItemUIElement]? {
        let childA11yUIElements: [MorphicA11yUIElement]
        do {
            childA11yUIElements = try self.accessibilityUiElement.children()
        } catch let error {
            throw error
        }
        
        var result: [MenuItemUIElement] = []
        for childA11yUIElement in childA11yUIElements {
            if childA11yUIElement.role == .menuItem {
                let menuItemUIElement = MenuItemUIElement(accessibilityUiElement: childA11yUIElement)
                result.append(menuItemUIElement)
            }
        }
        
        return result
    }
    
    // actions
    
    public func selectItem(titled title: String) throws {
        // get a list of all our menu items
        guard let items = try self.getItems() else {
            throw MorphicError.unspecified
        }
        
        // find the requested item
        // NOTE: this comparison is case-sensitive; if we want to allow case insensitivity, we should provide a comparison parameter in our function's params list
        let itemToSelect = try items.first(where: { menuItemUIElement in
            let menuItemTitle = try menuItemUIElement.getTitle()
            
            return menuItemTitle == title
        })
        guard let itemToSelect = itemToSelect else {
            throw MorphicError.unspecified
        }
        
        // select the item
        try itemToSelect.select()
    }
}
