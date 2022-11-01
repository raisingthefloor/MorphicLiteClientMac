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

public class CheckboxElement: UIElement {
    
    public enum State {
        case checked
        case unchecked
        case mixed
        case unknown
    }
    
    public var state: State {
        guard let checked: Bool = try? accessibilityElement.value(forAttribute: .value) else {
            return .unknown
        }
        if checked {
            return .checked
        }
        return .unchecked
    }
    
    public func setChecked(_ checked: Bool) throws {
        if checked {
            try check()
        } else {
            try uncheck()
        }
    }
    
    public func check() throws {
        switch state {
        case .checked:
            return
        case .unchecked, .mixed:
            try accessibilityElement.perform(action: .press)
            if state == .checked {
                return
            } else {
                throw MorphicError.unspecified
            }
        case .unknown:
            throw MorphicError.unspecified
        }
    }
    
    public func uncheck() throws {
        switch state{
        case .unchecked:
            return
        case .checked, .mixed:
            try accessibilityElement.perform(action: .press)
            if state == .unchecked {
                return
            } else {
                throw MorphicError.unspecified
            }
        case .unknown:
            throw MorphicError.unspecified
        }
    }
    
}
