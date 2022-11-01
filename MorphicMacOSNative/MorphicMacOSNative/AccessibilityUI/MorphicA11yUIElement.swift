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

import Cocoa
import MorphicCore

public struct MorphicA11yUIElement {
    internal let axUiElement: AXUIElement
    //
    // role
    // NOTE: NSAccessibility.Role has an "unknown" member; rather than make role an optional, we simply assign .unknown
    // https://developer.apple.com/documentation/appkit/nsaccessibility/role
    public let role: NSAccessibility.Role
    //
    // supportedAttributes
    // https://developer.apple.com/documentation/appkit/nsaccessibility/attribute
    public let supportedAttributes: [NSAccessibility.Attribute]

    public enum InitError: Error {
        case couldNotRetrieveAttributes
        case couldNotRetrieveRole
    }
    internal init(axUiElement: AXUIElement) throws {
        // axUiElement
        self.axUiElement = axUiElement
        //
        // supportedAttributes
        var supportedAttributeNamesAsCFArray: CFArray?
        let error = AXUIElementCopyAttributeNames(axUiElement, &supportedAttributeNamesAsCFArray)
        guard error == .success && supportedAttributeNamesAsCFArray != nil else {
            throw InitError.couldNotRetrieveAttributes
        }
        //
        var supportedAttributes: [NSAccessibility.Attribute] = []
        let supportedAttributeNames = supportedAttributeNamesAsCFArray! as! [String]
        for supportedAttributeName in supportedAttributeNames {
            let supportedAttribute = NSAccessibility.Attribute(rawValue: supportedAttributeName)
            supportedAttributes.append(supportedAttribute)
        }
        self.supportedAttributes = supportedAttributes
        //
        // role
        if self.supportedAttributes.contains(.role) == true {
            guard let roleAsString: String = try? MorphicA11yUIElement.value(forAttribute: .role, forAXUIElement: self.axUiElement) else {
                throw InitError.couldNotRetrieveRole
            }
            self.role = NSAccessibility.Role(rawValue: roleAsString)
        } else {
            self.role = .unknown
        }
    }

    //
    
    public static func createFromProcess(processIdentifier: pid_t) throws -> MorphicA11yUIElement {
        // verify that the application has accessibility authorization; if it does not, do not prompt the user (as we want the application to control the authorization pop-ups)
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: false) == true else {
            throw MorphicA11yAuthorizationError.notAuthorized
        }

        // get a reference to the top-level accessibility object for this process
        let topLevelAccessibilityObject = AXUIElementCreateApplication(processIdentifier)
        do {
            let result = try MorphicA11yUIElement(axUiElement: topLevelAccessibilityObject)
            return result
        } catch let error as InitError {
            throw error
        }
    }

    //

    public func children() throws -> [MorphicA11yUIElement] {
        guard self.supportedAttributes.contains(.children) == true else {
            return []
        }
        guard let children: [MorphicA11yUIElement] = try? self.values(forAttribute: .children) else {
            throw MorphicError.unspecified
        }
        //
        return children
    }

    public func parent() throws -> MorphicA11yUIElement? {
        guard self.supportedAttributes.contains(.parent) == true else {
            return nil
        }
        guard let parent: MorphicA11yUIElement = try? self.value(forAttribute: .parent) else {
            throw MorphicError.unspecified
        }
        //
        return parent
    }

    //

    public func value<T>(forAttribute attribute: NSAccessibility.Attribute) throws -> T where T: MorphicA11yUIAttributeValueCompatible {
        // NOTE: we bubble up any errors thrown by the following call
        let result: T = try MorphicA11yUIElement.value(forAttribute: attribute, forAXUIElement: self.axUiElement)
        return result
    }

    private static func value<T>(forAttribute attribute: NSAccessibility.Attribute, forAXUIElement axUiElement: AXUIElement) throws -> T where T: MorphicA11yUIAttributeValueCompatible {
        var valueAsCFTypeRef: AnyObject? = nil

        let error = AXUIElementCopyAttributeValue(axUiElement, attribute.rawValue as CFString, &valueAsCFTypeRef)
        guard error == .success && valueAsCFTypeRef != nil else {
            throw MorphicError.unspecified
        }
        //
        guard let result = try? MorphicA11yAttributeValueCompatibleSampleImpl.fromCFTypeRef(valueAsCFTypeRef!) else {
            throw MorphicError.unspecified
        }
        return (result as! T)
    }

    //

    public func values<T>(forAttribute attribute: NSAccessibility.Attribute) throws -> [T] where T: MorphicA11yUIAttributeValueCompatible {
        guard let result: [T] = try? MorphicA11yUIElement.values(forAttribute: attribute, forAXUIElement: self.axUiElement) else {
            throw MorphicError.unspecified
        }
        return result
    }

    public static func values<T>(forAttribute attribute: NSAccessibility.Attribute, forAXUIElement axUiElement: AXUIElement) throws -> [T] where T: MorphicA11yUIAttributeValueCompatible {
        var valuesAsCFArray: CFArray? = nil

        guard let numberOfValues = try? MorphicA11yUIElement.valueCount(forAttribute: attribute, forAXUIElement: axUiElement) else {
            throw MorphicError.unspecified
        }

        let error = AXUIElementCopyAttributeValues(axUiElement, attribute.rawValue as CFString, 0, numberOfValues, &valuesAsCFArray)
        guard error == .success && valuesAsCFArray != nil else {
            throw MorphicError.unspecified
        }
        //
        var values: [T] = []
        for valueAsCFTypeRef in valuesAsCFArray! as [CFTypeRef] {
            guard let value = try? MorphicA11yAttributeValueCompatibleSampleImpl.fromCFTypeRef(valueAsCFTypeRef) else {
                throw MorphicError.unspecified
            }
            values.append(value as! T)
        }
        //
        return values
    }

    //

    private static func valueCount(forAttribute attribute: NSAccessibility.Attribute, forAXUIElement axUiElement: AXUIElement) throws -> Int {
        var count: CFIndex = 0
        let error = AXUIElementGetAttributeValueCount(axUiElement, attribute.rawValue as CFString, &count)
        guard error == .success else {
            throw MorphicError.unspecified
        }
        return count as Int
    }

    //

    public func setValue(_ value: MorphicA11yUIAttributeValueCompatible, forAttribute attribute: NSAccessibility.Attribute) throws {
        try MorphicA11yUIElement.setValue(value, forAttribute: attribute, forAXUIElement: self.axUiElement)
    }

    private static func setValue(_ value: MorphicA11yUIAttributeValueCompatible, forAttribute attribute: NSAccessibility.Attribute, forAXUIElement axUiElement: AXUIElement) throws {
        let valueAsCFTypeRef = value.toCFTypeRef()
        let error = AXUIElementSetAttributeValue(axUiElement, attribute.rawValue as CFString, valueAsCFTypeRef)
        guard error == .success else {
            throw MorphicError.unspecified
        }
    }

    //

    public func supportedActions() throws -> [NSAccessibility.Action] {
        var supportedActionNamesAsCFArray: CFArray?
        let error = AXUIElementCopyActionNames(axUiElement, &supportedActionNamesAsCFArray)
        guard error == .success && supportedActionNamesAsCFArray != nil else {
            throw MorphicError.unspecified
        }
        //
        var supportedActions: [NSAccessibility.Action] = []
        let supportedActionNames = supportedActionNamesAsCFArray! as! [String]
        for supportedActionName in supportedActionNames {
            let supportedAction = NSAccessibility.Action(rawValue: supportedActionName)
            supportedActions.append(supportedAction)
        }
        return supportedActions
    }

    //

    public func perform(action: NSAccessibility.Action) throws {
        let error = AXUIElementPerformAction(self.axUiElement, action.rawValue as CFString)
        guard error == .success else {
            throw MorphicError.unspecified
        }
    }
}

extension Array where Element == MorphicA11yUIElement {
    public var firstAndOnly: MorphicA11yUIElement? {
        get {
            if self.count == 1 {
                return self.first
            } else {
                return nil
            }
        }
    }

    public func firstAndOnly(where filterClosure: (Element) throws -> Bool) rethrows -> MorphicA11yUIElement? {
        let allMatches = try self.filter(filterClosure)
        if allMatches.count == 1 {
            return allMatches.first
        } else {
            return nil
        }
    }
}
