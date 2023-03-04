// Copyright 2020-2022 Raising the Floor - US, Inc.
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

public class SplitGroupUIElement : UIElement {
    public let accessibilityUiElement: MorphicA11yUIElement
    
    public required init(accessibilityUiElement: MorphicA11yUIElement) {
        self.accessibilityUiElement = accessibilityUiElement
    }
    
    public func splitGroupItemsAsA11yUIElements() throws -> [MorphicA11yUIElement] {
        var result: [MorphicA11yUIElement] = []

        do {
            let splitGroupChildren = try self.accessibilityUiElement.children()

            // NOTE: every odd element should be a non-splitviewsplitter
            for (index, splitGroupChild) in splitGroupChildren.enumerated() {
                if index % 2 == 0 {
                    // odd elements should be child views (not splitters)
                    guard splitGroupChild.role != .splitter else {
                        throw MorphicError.unspecified
                    }

                    result.append(splitGroupChild)
                } else {
                    // even elements hsould be splitters
                    guard splitGroupChild.role == .splitter else {
                        throw MorphicError.unspecified
                    }
                }
            }
        } catch let error {
            throw error
        }
        
        return result
    }

    public func splitGroupItemsAsGroupUIElements() throws -> [GroupUIElement] {
        var result: [GroupUIElement] = []

        let items: [MorphicA11yUIElement]
        do {
            items = try self.splitGroupItemsAsA11yUIElements()
        } catch let error {
            throw error
        }
        //
        for item in items {
            guard item.role == .group else {
                throw MorphicError.unspecified
            }
            
            let itemAsGroupUIElement = GroupUIElement(accessibilityUiElement: item)
            result.append(itemAsGroupUIElement)
        }
        
        return result
    }
}