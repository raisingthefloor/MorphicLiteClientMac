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

import Cocoa
import MorphicCore

public struct MorphicA11yUIElement {
    internal let axUiElement: AXUIElement
    //
    // supportedAttributes
    // https://developer.apple.com/documentation/appkit/nsaccessibility/attribute
    public let supportedAttributes: [NSAccessibility.Attribute]
    //
    // role
    // https://developer.apple.com/documentation/appkit/nsaccessibility/role
    public let role: NSAccessibility.Role
    //
    // subrole
    // https://develpoer.apple.com/documentation/appkit/nsaccessibility/subrole
    public let subrole: NSAccessibility.Subrole
    
    internal init?(axUiElement: AXUIElement) {
        // axUiElement
        self.axUiElement = axUiElement
        //
        // supportedAttributes
        var supportedAttributeNamesAsCFArray: CFArray?
        let error = AXUIElementCopyAttributeNames(axUiElement, &supportedAttributeNamesAsCFArray)
        guard error == .success && supportedAttributeNamesAsCFArray != nil else {
            return nil
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
            guard let roleAsString: String = MorphicA11yUIElement.value(forAttribute: .role, forAXUIElement: self.axUiElement) else {
                return nil
            }
            self.role = NSAccessibility.Role(rawValue: roleAsString)
        } else {
            self.role = .unknown
        }
        //
        // role
        if self.supportedAttributes.contains(.subrole) == true {
            guard let subroleAsString: String = MorphicA11yUIElement.value(forAttribute: .subrole, forAXUIElement: self.axUiElement) else {
                return nil
            }
            self.subrole = NSAccessibility.Subrole(rawValue: subroleAsString)
        } else {
            self.subrole = .unknown
        }
    }
    
    public static func createFromProcess(processIdentifier: pid_t) throws -> MorphicA11yUIElement? {
        // verify that the application has accessibility authorization; if it does not, do not prompt the user (as we want the application to control the authorization pop-ups)
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: false) == true else {
            throw MorphicA11yAuthorizationError.notAuthorized
        }

        // get a reference to the top-level accessibility object for this process
        let topLevelAccessibilityObject = AXUIElementCreateApplication(processIdentifier)
        return MorphicA11yUIElement(axUiElement: topLevelAccessibilityObject)
    }

    //
    
    public func children() -> [MorphicA11yUIElement]? {
        guard self.supportedAttributes.contains(.children) == true else {
            return nil
        }
        guard let children: [MorphicA11yUIElement] = self.values(forAttribute: .children) else {
            return nil
        }
        //
        return children
    }

    //
    
    public func value<T>(forAttribute attribute: NSAccessibility.Attribute) -> T? where T: MorphicA11yUIAttributeValueCompatible {
        let result: T? = MorphicA11yUIElement.value(forAttribute: attribute, forAXUIElement: self.axUiElement)
        return result
    }
    
    private static func value<T>(forAttribute attribute: NSAccessibility.Attribute, forAXUIElement axUiElement: AXUIElement) -> T? where T: MorphicA11yUIAttributeValueCompatible {
        var valueAsCFTypeRef: AnyObject? = nil
        
        let error = AXUIElementCopyAttributeValue(axUiElement, attribute.rawValue as CFString, &valueAsCFTypeRef)
        guard error == .success && valueAsCFTypeRef != nil else {
            return nil
        }
        //
        return (MorphicA11yAttributeValueCompatibleSampleImpl.fromCFTypeRef(valueAsCFTypeRef!) as! T)
    }
    
    //
    
    public func values<T>(forAttribute attribute: NSAccessibility.Attribute) -> [T]? where T: MorphicA11yUIAttributeValueCompatible {
        let result: [T]? = MorphicA11yUIElement.values(forAttribute: attribute, forAXUIElement: self.axUiElement)
        return result
    }
    
    public static func values<T>(forAttribute attribute: NSAccessibility.Attribute, forAXUIElement axUiElement: AXUIElement) -> [T]? where T: MorphicA11yUIAttributeValueCompatible {
        var valuesAsCFArray: CFArray? = nil
        
        let numberOfValues = MorphicA11yUIElement.valueCount(forAttribute: attribute, forAXUIElement: axUiElement)
        
        let error = AXUIElementCopyAttributeValues(axUiElement, attribute.rawValue as CFString, 0, numberOfValues, &valuesAsCFArray)
        guard error == .success && valuesAsCFArray != nil else {
            return nil
        }
        //
        var values: [T] = []
        for valueAsCFTypeRef in valuesAsCFArray! as [CFTypeRef] {
            guard let value = MorphicA11yAttributeValueCompatibleSampleImpl.fromCFTypeRef(valueAsCFTypeRef) else {
                return nil
            }
            values.append(value as! T)
        }
        //
        return values
    }

    //
    
    private static func valueCount(forAttribute attribute: NSAccessibility.Attribute, forAXUIElement axUiElement: AXUIElement) -> Int {
        var count: CFIndex = 0
        AXUIElementGetAttributeValueCount(axUiElement, attribute.rawValue as CFString, &count)
        return count as Int
    }

    //

    public func setValue(_ value: MorphicA11yUIAttributeValueCompatible, forAttribute attribute: NSAccessibility.Attribute) throws {
        try MorphicA11yUIElement.setValue(value, forAttribute: attribute, forAXUIElement: self.axUiElement)
    }

    private static func setValue(_ value: MorphicA11yUIAttributeValueCompatible, forAttribute attribute: NSAccessibility.Attribute, forAXUIElement axUiElement: AXUIElement) throws {
        let valueAsCFTypeRef = value.toCFTypeRef()
        let error = AXUIElementSetAttributeValue(axUiElement, attribute.rawValue as CFString, valueAsCFTypeRef)
        if error != .success {
            throw MorphicError()
        }
    }
    
    //
    
    public func supportedActions() -> [NSAccessibility.Action]? {
        var supportedActionNamesAsCFArray: CFArray?
        let error = AXUIElementCopyActionNames(axUiElement, &supportedActionNamesAsCFArray)
        guard error == .success && supportedActionNamesAsCFArray != nil else {
            return nil
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
        if error != .success {
            throw MorphicError()
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
