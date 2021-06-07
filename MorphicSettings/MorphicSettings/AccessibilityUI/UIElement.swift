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

public class UIElement {
    
    var accessibilityElement: MorphicA11yUIElement!
    
    public required init(accessibilityElement: MorphicA11yUIElement?) {
        self.accessibilityElement = accessibilityElement
    }
    
    public func button(titled: String) -> ButtonElement? {
        return descendant(role: .button, title: titled)
    }
    
    public func checkbox(titled: String) -> CheckboxElement? {
        return descendant(role: .checkBox, title: titled)
    }
    
    public func firstCheckbox() -> CheckboxElement? {
        return descendant(role: .checkBox)
    }
    
    public func table(titled: String) -> TableElement? {
        return descendant(role: .table, title: titled)
    }
    
    public var label: LabelElement? {
        return descendant(role: .staticText)
    }
    
    public func label(value: String) -> LabelElement? {
        return descendant(role: .staticText, value: value)
    }
    
    public var tabGroup: TabGroupElement? {
        return descendant(role: .tabGroup)
    }
    
    public func popUpButton(titled: String) -> PopUpButtonElement? {
        return descendant(role: .popUpButton, title: titled)
    }
    
    public func firstPopupButton() -> PopUpButtonElement? {
        return descendant(role: .popUpButton)
    }
    
    public func slider(titled: String) -> SliderElement? {
        return descendant(role: .slider, title: titled)
    }
    
    public func firstSlider() -> SliderElement? {
        return descendant(role: .slider)
    }
    
    public var menu: MenuElement? {
        return descendant(role: .menu)
    }
    
    private func descendant<ElementType: UIElement>(role: NSAccessibility.Role, title: String) -> ElementType? {
    guard let accessibilityElement = accessibilityDescendant(role: role, title: title) else {
            return nil
        }
        return ElementType(accessibilityElement: accessibilityElement)
    }

    private func descendant<ElementType: UIElement>(role: NSAccessibility.Role, value: String) -> ElementType? {
        guard let accessibilityElement = accessibilityDescendant(role: role, value: value) else {
            return nil
        }
        return ElementType(accessibilityElement: accessibilityElement)
    }

    private func descendant<ElementType: UIElement>(role: NSAccessibility.Role) -> ElementType? {
        guard let accessibilityElement = accessibilityDescendant(role: role) else {
            return nil
        }
        return ElementType(accessibilityElement: accessibilityElement)
    }
    
    private func accessibilityDescendant(role: NSAccessibility.Role, title: String) -> MorphicA11yUIElement? {
        guard let children = accessibilityElement.children() else {
            return nil
        }
        var stack = children
        var i = 0
        while i < stack.count {
            let candidate = stack[i]
            if candidate.role == role {
                if candidate.value(forAttribute: .title) == title || candidate.value(forAttribute: .description) == title {
                    return candidate
                }
                if let titleElement: MorphicA11yUIElement = candidate.value(forAttribute: .titleUIElement) {
                    if titleElement.value(forAttribute: .value) == title {
                        return candidate
                    }
                }
            }
            if let children = candidate.children() {
                stack.append(contentsOf: children)
            }
            i += 1
        }
        return nil
    }
    
    private func accessibilityDescendant(role: NSAccessibility.Role, value: String) -> MorphicA11yUIElement? {
        guard let children = accessibilityElement.children() else {
            return nil
        }
        var stack = children
        var i = 0
        while i < stack.count {
            let candidate = stack[i]
            if candidate.role == role {
                if candidate.value(forAttribute: .value) == value {
                    return candidate
                }
            }
            if let children = candidate.children() {
                stack.append(contentsOf: children)
            }
            i += 1
        }
        return nil
    }
    
    private func accessibilityDescendant(role: NSAccessibility.Role) -> MorphicA11yUIElement? {
        guard let children = accessibilityElement.children() else {
            return nil
        }
        var stack = children
        var i = 0
        while i < stack.count {
            let candidate = stack[i]
            if candidate.role == role {
                return candidate
            }
            if let children = candidate.children() {
                stack.append(contentsOf: children)
            }
            i += 1
        }
        return nil
    }
    
    public func closeButton() -> MorphicA11yUIElement? {
        guard let children = accessibilityElement.children() else {
            return nil
        }
        var stack = children
        var i = 0
        while i < stack.count {
            let candidate = stack[i]
            if candidate.subrole == NSAccessibility.Subrole.closeButton {
                return candidate
            }
            if let children = candidate.children() {
                stack.append(contentsOf: children)
            }
            i += 1
        }
        return nil
    }
        
    public func perform(action: Action, completion: @escaping (_ success: Bool, _ nextTarget: UIElement?) -> Void) {
        switch action {
        case .check(let title, let checked):
            let checkbox = self.checkbox(titled: title)
            let success: Bool
            if let _ = try? checkbox?.setChecked(checked) {
                success = true
            } else {
                success = false
            }
            completion(success, self)
        case .press(let title):
            let button = self.button(titled: title)
            let success: Bool
            if let _ = try? button?.press() {
                success = true
            } else {
                success = false
            }
            completion(success, self)
        default:
            completion(false, self)
        }
    }
    
    public enum Action {
        case launch(bundleIdentifier: String)
        case show(identifier: String)
        case check(checkboxTitle: String, checked: Bool)
        case press(buttonTitle: String)
    }

}
