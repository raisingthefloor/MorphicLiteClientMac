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

import Foundation
import MorphicCore

public class PopUpButtonElement: UIElement {
    
    public var value: String? {
        get{
            accessibilityElement.value(forAttribute: .value)
        }
    }
    
    public func setValue(_ value: String, completion: @escaping (_ success: Bool) -> Void) {
        guard let _ = try? accessibilityElement.perform(action: .showMenu) else {
            completion(false)
            return
        }
        AsyncUtils.wait(atMost: 2.0, for: { self.menu != nil }) {
            sucess in
            guard let menu = self.menu else {
                completion(false)
                return
            }
            guard let _ = try? menu.select(itemTitled: value) else {
                completion(false)
                return
            }
            AsyncUtils.wait(atMost: 2.0, for: { self.value == value }) {
                success in
                completion(success)
            }
        }
    }
    
}
