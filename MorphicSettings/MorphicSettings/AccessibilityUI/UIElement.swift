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
import Cocoa
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "UIElement")

public class UIElement{
    
    var accessibilityElement: MorphicA11yUIElement!
    
    public required init(accessibilityElement: MorphicA11yUIElement?){
        self.accessibilityElement = accessibilityElement
    }
    
    public func button(titled: String) -> ButtonElement?{
        return descendant(role: .button, title: titled)
    }
    
    public func checkbox(titled: String) -> CheckboxElement?{
        return descendant(role: .checkBox, title: titled)
    }
    
    public func table(titled: String) -> TableElement?{
        return descendant(role: .table, title: titled)
    }
    
    public var label: LabelElement?{
        return descendant(role: .staticText)
    }
    
    public var tabGroup: TabGroupElement?{
        return descendant(role: .tabGroup)
    }
    
    private func descendant<ElementType: UIElement>(role: NSAccessibility.Role, title: String) -> ElementType?{
        guard let accessibilityElement = accessibilityDescendant(role: role, title: title) else{
            return nil
        }
        return ElementType(accessibilityElement: accessibilityElement)
    }
    
    private func descendant<ElementType: UIElement>(role: NSAccessibility.Role) -> ElementType?{
        guard let accessibilityElement = accessibilityDescendant(role: role) else{
            return nil
        }
        return ElementType(accessibilityElement: accessibilityElement)
    }
    
    private func accessibilityDescendant(role: NSAccessibility.Role, title: String) -> MorphicA11yUIElement?{
        guard let children = accessibilityElement.children() else{
            return nil
        }
        var stack = children
        var i = 0
        while i < stack.count{
            let candidate = stack[i]
            if candidate.role == role{
                if candidate.value(forAttribute: .title) == title || candidate.value(forAttribute: .description) == title{
                    return candidate
                }
            }
            if let children = candidate.children(){
                stack.append(contentsOf: children)
            }
            i += 1
        }
        return nil
    }
    
    private func accessibilityDescendant(role: NSAccessibility.Role) -> MorphicA11yUIElement?{
        guard let children = accessibilityElement.children() else{
            return nil
        }
        var stack = children
        var i = 0
        while i < stack.count{
            let candidate = stack[i]
            if candidate.role == role{
                return candidate
            }
            if let children = candidate.children(){
                stack.append(contentsOf: children)
            }
            i += 1
        }
        return nil
    }
    
    public func wait(atMost: TimeInterval, for condition: @escaping () -> Bool, completion: @escaping (_ success: Bool) -> Void){
        guard !condition() else{
            completion(true)
            return
        }
        var checkTimer: Timer?
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: atMost, repeats: false){
            _ in
            checkTimer?.invalidate()
            completion(condition())
        }
        var checkInterval: TimeInterval = 0.1
        var check: (() -> Void)!
        check = {
            checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: false){
                _ in
                if condition(){
                    timeoutTimer.invalidate()
                    completion(true)
                }else{
                    checkInterval *= 2
                    check()
                }
            }
        }
        check()
    }
    
    public func perform(action: Action, completion: @escaping (_ success: Bool, _ nextTarget: UIElement?) -> Void){
        switch action{
        case .check(let title, let checked):
            let checkbox = self.checkbox(titled: title)
            let success = checkbox?.setChecked(checked) ?? false
            completion(success, self)
        case .press(let title):
            let button = self.button(titled: title)
            let success = button?.press() ?? false
            completion(success, self)
        default:
            completion(false, self)
        }
    }
    
    public enum Action{
        case launch(bundleIdentifier: String)
        case show(identifier: String)
        case check(checkboxTitle: String, checked: Bool)
        case press(buttonTitle: String)
    }
    
}
