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

public class AccessibilityPreferencesElement: UIElement{
    
    public enum CategoryIdentifier{
        
        case display
        case zoom
        case voiceOver
        
        public var rowTitle: String{
            get{
                switch self {
                case .display:
                    return "Display"
                case .zoom:
                    return "Zoom"
                case .voiceOver:
                    return "VoiceOver"
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
    
    public func selectVoiceOver(completion: @escaping (_ success: Bool) -> Void){
        select(category: .voiceOver){
            success in
            guard success else{
                completion(false)
                return
            }
            self.wait(atMost: 1.0, for: { self.checkbox(titled: "Enable VoiceOver") != nil}){
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
