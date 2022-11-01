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

public class TabGroupElement: UIElement {
    
    public func select(tabTitled title: String) throws {
        guard let tab = self.tab(titled: title) else {
            throw MorphicError.unspecified
        }
        try tab.select()
    }
    
    public func tab(titled: String) -> TabElement? {
        guard let tabs: [MorphicA11yUIElement] = try? accessibilityElement.values(forAttribute: .tabs) else {
            return nil
        }
        guard let tab = tabs.first(where: {
            do {
                let title: String = try $0.value(forAttribute: .title)
                return title == titled
            } catch {
                // if we could not retrieve the title attribute, return false
                // NOTE: in the future, we should consider bubbling-up errors
                return false
            }
        }) else {
            return nil
        }
        return TabElement(accessibilityElement: tab)
    }
    
}
