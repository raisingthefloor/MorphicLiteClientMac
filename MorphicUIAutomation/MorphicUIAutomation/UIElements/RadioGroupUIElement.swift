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

public class RadioGroupUIElement : UIElement {
    public let accessibilityUiElement: MorphicA11yUIElement
    
    public required init(accessibilityUiElement: MorphicA11yUIElement) {
        self.accessibilityUiElement = accessibilityUiElement
    }
    
    // actions
    
    public func getSelectedRadioButton() throws -> String? {
        // find our AXRadioButton children
        let radioButtons = try self.accessibilityUiElement.children(role: .radioButton)
        
        for radioButton in radioButtons {
            guard let radioButtonIsSelectedAsInt: Int = try radioButton.value(forAttribute: .value) else {
                throw MorphicError.unspecified
            }
            let radioButtonIsSelected: Bool = (radioButtonIsSelectedAsInt != 0) ? true: false
            
            if radioButtonIsSelected == true {
                guard let radioButtonLabel: String = try radioButton.value(forAttribute: .description) else {
                    throw MorphicError.unspecified
                }
                
                return radioButtonLabel
            }
        }
        
        // if none of the radio buttons were selected (or if there were no radio buttons as children), return nil
        return nil
    }

    public func setSelectedRadioButton(_ radioButtonLabel: String) throws {
        // find our AXRadioButton children
        let radioButtons = try self.accessibilityUiElement.children(role: .radioButton)
        
        for radioButton in radioButtons {
            guard let currentRadioButtonLabel: String = try radioButton.value(forAttribute: .description) else {
                throw MorphicError.unspecified
            }

            if currentRadioButtonLabel == radioButtonLabel {
                // we have found the radio button; select it now
                try radioButton.perform(action: .press)

                // once we have found the desired radio button and set it, we have succeeded
                return
            }
        }
        
        // if we did not find any radio button with the specified label, return an error
        throw MorphicError.unspecified
    }
}
