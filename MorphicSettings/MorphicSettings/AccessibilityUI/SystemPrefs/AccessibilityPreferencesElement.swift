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

public class AccessibilityPreferencesElement: UIElement {
    
    public enum CategoryIdentifier {
        
        case display
        case overview
        case speech
        case voiceOver
        case zoom

        public var rowTitle: String {
            get {
                switch self {
                case .display:
                    return "Display"
                case .overview:
                    return "Overview"
                case .speech:
                    return "Spoken Content"
                case .voiceOver:
                    return "VoiceOver"
                case .zoom:
                    return "Zoom"
                }
            }
        }
        
    }
    
    public var categoriesTable: TableElement? {
        return table(titled: "Accessibility features")
    }

    public func selectOverview(completion: @escaping (_ success: Bool) -> Void) {
        select(category: .overview) {
            success in
            guard success else {
                completion(false)
                return
            }
            AsyncUtils.wait(atMost: 1.0, for: {
                if self.label(value: "Your Mac can be customized to support your vision, hearing, physical motor, and learning & literacy requirements.") != nil {
                    return true
                }
                
                return false
            }) {
                success in
                completion(success)
            }
        }
    }

    public func selectDisplay(completion: @escaping (_ success: Bool) -> Void) {
        select(category: .display) {
            success in
            guard success else {
                completion(false)
                return
            }            
            AsyncUtils.wait(atMost: 1.0, for: {
                // look for the "display" subtab
                return self.tabGroup?.tab(titled: "Display") != nil
            }) {
                success in
                completion(success)
            }
        }
    }

    public func selectSpeech(completion: @escaping (_ success: Bool) -> Void) {
        select(category: .speech) {
            success in
            guard success else {
                completion(false)
                return
            }
            //
            let waitForCheckboxTitle: String
            waitForCheckboxTitle = "Speak announcements"
            //
            AsyncUtils.wait(atMost: 1.0, for: { self.checkbox(titled: waitForCheckboxTitle) != nil}) {
                success in
                completion(success)
            }
        }
    }

    public func selectVoiceOver(completion: @escaping (_ success: Bool) -> Void) {
        select(category: .voiceOver) {
            success in
            guard success else {
                completion(false)
                return
            }
            AsyncUtils.wait(atMost: 1.0, for: { self.checkbox(titled: "Enable VoiceOver") != nil}) {
                success in
                completion(success)
            }
        }
    }
    
    public func selectZoom(completion: @escaping (_ success: Bool) -> Void) {
        select(category: .zoom) {
            success in
            guard success else {
                completion(false)
                return
            }
            AsyncUtils.wait(atMost: 1.0, for: { self.checkbox(titled: "Use keyboard shortcuts to zoom") != nil}) {
                success in
                completion(success)
            }
        }
        
    }

    public func select(category identifier: CategoryIdentifier, completion: @escaping (_ success: Bool) -> Void) {
        AsyncUtils.wait(atMost: 1.0, for: { self.categoriesTable != nil }) {
            success in
            guard success else {
                completion(false)
                return
            }
            guard let row = self.categoriesTable?.row(titled: identifier.rowTitle) else {
                completion(false)
                return
            }
            let selected: Bool
            if let _ = try? row.select() {
                selected = true
            } else {
                selected = false
            }
            completion(selected)
        }
    }
    
    public func select(tabTitled title: String) throws {
        guard let _ = try tabGroup?.select(tabTitled: title) else {
            throw MorphicError.unspecified
        }
    }
    
}
