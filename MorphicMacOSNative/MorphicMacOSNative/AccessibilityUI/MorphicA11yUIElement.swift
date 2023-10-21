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
        } catch let error {
            assertionFailure("undocumented error path")
            throw error
        }
    }

    //

    public func children() throws -> [MorphicA11yUIElement] {
        guard self.supportedAttributes.contains(.children) == true else {
            return []
        }
        let children: [MorphicA11yUIElement]
        do {
            children = try self.values(forAttribute: .children)
        } catch let error as MorphicA11yUIElementError {
            throw error
        } catch let error {
            assertionFailure("undocumented error path")
            throw error
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

    public func value<T>(forAttribute attribute: NSAccessibility.Attribute) throws -> T? where T: MorphicA11yUIAttributeValueCompatible {
        // NOTE: we bubble up any errors thrown by the following call
        let result: T? = try MorphicA11yUIElement.value(forAttribute: attribute, forAXUIElement: self.axUiElement)
        return result
    }

    private static func value<T>(forAttribute attribute: NSAccessibility.Attribute, forAXUIElement axUiElement: AXUIElement) throws -> T? where T: MorphicA11yUIAttributeValueCompatible {
        var valueAsCFTypeRef: AnyObject? = nil

        let error = AXUIElementCopyAttributeValue(axUiElement, attribute.rawValue as CFString, &valueAsCFTypeRef)
        guard error == .success && valueAsCFTypeRef != nil else {
            switch error {
            case .noValue:
                return nil
            default:
                throw MorphicA11yUIElementError.axError(error)
            }
        }
        //
        let result: FoundationA11yUIAttributeValueCompatible
        do {
            result = try MorphicA11yAttributeValueCompatibleSampleImpl.fromCFTypeRef(valueAsCFTypeRef!)
        } catch let error as MorphicA11yUIAttributeValueCompatibleError {
            throw MorphicA11yUIElementError.uiAttributeValueCompatibleError(error)
        } catch let error {
            assertionFailure("undocumented error path")
            throw error
        }
        return (result as! T)
    }

    //

    public func values<T>(forAttribute attribute: NSAccessibility.Attribute) throws -> [T] where T: MorphicA11yUIAttributeValueCompatible {
        let result: [T]
        do {
            result = try MorphicA11yUIElement.values(forAttribute: attribute, forAXUIElement: self.axUiElement)
        } catch let error as MorphicA11yUIElementError {
            throw error
        } catch let error {
            assertionFailure("undocumented error path")
            throw error
        }

        return result
    }

    public static func values<T>(forAttribute attribute: NSAccessibility.Attribute, forAXUIElement axUiElement: AXUIElement) throws -> [T] where T: MorphicA11yUIAttributeValueCompatible {
        var valuesAsCFArray: CFArray? = nil

        let numberOfValues: Int
        do {
            numberOfValues = try MorphicA11yUIElement.valueCount(forAttribute: attribute, forAXUIElement: axUiElement)
        } catch MorphicA11yUIElementError.axError(let error) {
            throw MorphicA11yUIElementError.axError(error)
        } catch let error {
            assertionFailure("undocumented error path")
            throw error
        }

        let error = AXUIElementCopyAttributeValues(axUiElement, attribute.rawValue as CFString, 0, numberOfValues, &valuesAsCFArray)
        guard error == .success && valuesAsCFArray != nil else {
            throw MorphicA11yUIElementError.axError(error)
        }
        //
        var values: [T] = []
        for valueAsCFTypeRef in valuesAsCFArray! as [CFTypeRef] {
            let value:  FoundationA11yUIAttributeValueCompatible
            do {
                value = try MorphicA11yAttributeValueCompatibleSampleImpl.fromCFTypeRef(valueAsCFTypeRef)
            } catch let error as MorphicA11yUIAttributeValueCompatibleError {
                throw MorphicA11yUIElementError.uiAttributeValueCompatibleError(error)
            } catch let error {
                assertionFailure("undocumented error path")
                throw error
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
            throw MorphicA11yUIElementError.axError(error)
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
            throw MorphicA11yUIElementError.axError(error)
        }
    }

    //

    public func supportedActions() throws -> [NSAccessibility.Action] {
        var supportedActionNamesAsCFArray: CFArray?
        let error = AXUIElementCopyActionNames(axUiElement, &supportedActionNamesAsCFArray)
        guard error == .success && supportedActionNamesAsCFArray != nil else {
            throw MorphicA11yUIElementError.axError(error)
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
            throw MorphicA11yUIElementError.axError(error)
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
    
    //
    
    public func firstAncestorInLineage(where predicate: (MorphicA11yUIElement) throws -> Bool) throws -> MorphicA11yUIElement? {
        // if only a direct child is found in the lineage, return nil
        if self.count <= 1 {
            return nil
        }
        
        for parent in self[1...] {
            // if the parent satisfies the predicate, return that parent
            let parentSatisfiesPredicate: Bool
            do {
                parentSatisfiesPredicate = try predicate(parent)
            } catch let error {
                throw error
            }
            if parentSatisfiesPredicate == true {
                return parent
            }
        }
        
        // if no parents satisfied the predicate, return nil
        return nil
    }
    
    public func firstAncestorInLineage(identifier: String) throws -> MorphicA11yUIElement? {
        return try self.firstAncestorInLineage(
            where: { parent in
                // if the parent's identifier matches the requested identifier, return that parent
                let parentIdentifier: String?
                do {
                    parentIdentifier = try parent.value(forAttribute: .identifier)
                } catch let error {
                    throw error
                }
                guard let parentIdentifier = parentIdentifier else {
                    return false
                }
                return (parentIdentifier == identifier)
            }
        )
    }
    
    public func firstAncestorInLineage(role: NSAccessibility.Role) throws -> MorphicA11yUIElement? {
        return try self.firstAncestorInLineage(where: { $0.role == role })
    }
}

// MARK: - functions for finding specific types of children/parents and descendants/ancestors

extension MorphicA11yUIElement {
    public func firstChild(where predicate: (MorphicA11yUIElement) throws -> Bool) throws -> MorphicA11yUIElement? {
        let children: [MorphicA11yUIElement]
        do {
            children = try self.children()
        } catch let error {
            throw error
        }
        
        for child in children {
            // check to see if the child matches the predicate
            let childSatisfiesPredicate: Bool
            do {
                childSatisfiesPredicate = try predicate(child)
            } catch let error {
                throw error
            }
            if childSatisfiesPredicate == true {
                return child
            }
        }
        
        // no child found which satisfies the predicate
        return nil
    }
    
    public func firstChild(role: NSAccessibility.Role) throws -> MorphicA11yUIElement? {
        return try self.firstChild(where: { $0.role == role })
    }
    
    //
    
    public func onlyChild(where predicate: (MorphicA11yUIElement) throws -> Bool) throws -> MorphicA11yUIElement? {
        let children: [MorphicA11yUIElement]
        do {
            children = try self.children()
        } catch let error {
            throw error
        }
        
        var matches: [MorphicA11yUIElement] = []
        
        for child in children {
            // check to see if the child matches the predicate
            let childSatisfiesPredicate: Bool
            do {
                childSatisfiesPredicate = try predicate(child)
            } catch let error {
                throw error
            }
            if childSatisfiesPredicate == true {
                matches.append(child)
            }
        }
        
        if matches.count == 1 {
            return matches.first!
        } else {
            return nil
        }
    }
    
    public func onlyChild(role: NSAccessibility.Role) throws -> MorphicA11yUIElement? {
        return try self.onlyChild(where: { $0.role == role })
    }

    //
    
    public func children(where predicate: (MorphicA11yUIElement) throws -> Bool) throws -> [MorphicA11yUIElement] {
        var result: [MorphicA11yUIElement] = []
        
        let children: [MorphicA11yUIElement]
        do {
            children = try self.children()
        } catch let error {
            throw error
        }
        
        for child in children {
            // check to see if the child matches the predicate
            let childSatisfiesPredicate: Bool
            do {
                childSatisfiesPredicate = try predicate(child)
            } catch let error {
                throw error
            }
            if childSatisfiesPredicate == true {
                result.append(child)
            }
        }
        
        return result
    }
    
    public func children(role: NSAccessibility.Role) throws -> [MorphicA11yUIElement] {
        return try self.children(where: { $0.role == role })
    }
    
    //
    
    // NOTE: firstDescendant iterates through each child's branch, left-to-right; it will return a deep match before returning a shallow match if that deep match is a descendant of a child which is more leftmost; as it could be easily misunderstood and misused, returning technically-accurate results which did not match up with the intentions of the caller, we have marked it as private
    private func firstDescendant(where predicate: (MorphicA11yUIElement) throws -> Bool, maxDepth: Int = Int.max) throws -> MorphicA11yUIElement? {
        return try MorphicA11yUIElement.firstDescendant(where: predicate, startingElement: self, currentDepth: 1, maxDepth: maxDepth)
    }
    private static func firstDescendant(where predicate: (MorphicA11yUIElement) throws -> Bool, startingElement: MorphicA11yUIElement, currentDepth: Int, maxDepth: Int) throws -> MorphicA11yUIElement? {
        
        let firstDescendantWithLineage: [MorphicA11yUIElement]?
        do {
            firstDescendantWithLineage = try self.firstDescendantWithLineage(where: predicate, startingElement: startingElement, currentDepth: currentDepth, maxDepth: maxDepth)
        } catch let error {
            throw error
        }
        
        guard let firstDescendant = firstDescendantWithLineage?.first else {
            return nil
        }
        
        return firstDescendant
    }
    
    private func firstDescendantWithLineage(where predicate: (MorphicA11yUIElement) throws -> Bool, maxDepth: Int = Int.max) throws -> [MorphicA11yUIElement]? {
        return try MorphicA11yUIElement.firstDescendantWithLineage(where: predicate, startingElement: self, currentDepth: 1, maxDepth: maxDepth)
    }
    private static func firstDescendantWithLineage(where predicate: (MorphicA11yUIElement) throws -> Bool, startingElement: MorphicA11yUIElement, currentDepth: Int, maxDepth: Int) throws -> [MorphicA11yUIElement]? {
        guard currentDepth <= maxDepth else {
            return nil
        }
        
        let children: [MorphicA11yUIElement]
        do {
            children = try startingElement.children()
        } catch let error {
            throw error
        }
        
        for child in children {
            // check to see if the child matches the predicate
            let childSatisfiesPredicate: Bool
            do {
                childSatisfiesPredicate = try predicate(child)
            } catch let error {
                throw error
            }
            if childSatisfiesPredicate == true {
                return [child, startingElement]
            }
            
            // if the child does not satisfy the predicate, recurse into the child
            //
            // NOTE: special-case: if currentDepth is already the maximum depth, do not attempt to recurse any further as we have already reached the maximum depth
            guard currentDepth < Int.max else {
                return nil
            }
            //
            let descendantElements: [MorphicA11yUIElement]?
            do {
                descendantElements = try MorphicA11yUIElement.firstDescendantWithLineage(where: predicate, startingElement: child, currentDepth: currentDepth + 1, maxDepth: maxDepth)
            } catch let error {
                throw error
            }
            // if a descendant matched, return that descendant's lineage (appending the starting element, so that the descendant is the ultimate first entry and the original ancestor is the last entry)
            if var descendantElements = descendantElements {
                descendantElements.append(startingElement)
                return descendantElements
            }
        }
        
        // if no children matched, return nil
        return nil
    }
    
    public func descendantWithLineage(identifier: String, maxDepth: Int = Int.max) throws -> [MorphicA11yUIElement]? {
        return try self.firstDescendantWithLineage(
            where: { child in
                // check to see if the child matches the specified identifier
                let childIdentifier: String?
                do {
                    childIdentifier = try child.value(forAttribute: .identifier)
                } catch let error {
                    throw error
                }
                guard let childIdentifier = childIdentifier else {
                    return false
                }
                return (childIdentifier == identifier)
            },
            maxDepth: maxDepth)
    }
    
    public func descendant(identifier: String, maxDepth: Int = Int.max) throws -> MorphicA11yUIElement? {
        let descendantWithLineage: [MorphicA11yUIElement]?
        do {
            descendantWithLineage = try self.descendantWithLineage(identifier: identifier, maxDepth: maxDepth)
        } catch let error {
            throw error
        }
        
        guard let descendant = descendantWithLineage?.first else {
            return nil
        }
        
        return descendant
    }
    
    //
    
    // NOTE: we provide these "dangerous" options for finding descendants in exceptional circumstances; these should not be relied on, however
    public func dangerousFirstDescendant(where predicate: (MorphicA11yUIElement) throws -> Bool, maxDepth: Int = Int.max) throws -> MorphicA11yUIElement? {
        return try self.firstDescendant(where: predicate, maxDepth: maxDepth)
    }
    
    public func dangerousFirstDescendantWithLineage(where predicate: (MorphicA11yUIElement) throws -> Bool, maxDepth: Int = Int.max) throws -> [MorphicA11yUIElement]? {
        return try self.firstDescendantWithLineage(where: predicate, maxDepth: maxDepth)
    }

    //
    
    public func firstAncestor(where predicate: (MorphicA11yUIElement) throws -> Bool, maxDepth: Int = Int.max) throws -> MorphicA11yUIElement? {
        return try MorphicA11yUIElement.firstAncestor(where: predicate, startingElement: self, currentDepth: 1, maxDepth: maxDepth)
    }
    private static func firstAncestor(where predicate: (MorphicA11yUIElement) throws -> Bool, startingElement: MorphicA11yUIElement, currentDepth: Int, maxDepth: Int) throws -> MorphicA11yUIElement? {
        guard currentDepth <= maxDepth else {
            return nil
        }
        
        let parent: MorphicA11yUIElement?
        do {
            parent = try startingElement.parent()
        } catch let error {
            throw error
        }
        
        // if our element has no parent, return nil
        guard let parent = parent else {
            return nil
        }
        
        // if the parent satisfies the predicate, return that parent
        let parentSatisfiesPredicate: Bool
        do {
            parentSatisfiesPredicate = try predicate(parent)
        } catch let error {
            throw error
        }
        if parentSatisfiesPredicate == true {
            return parent
        }
        
        // if the parent does not satisfy the predicate, try the parent's parent
        //
        // NOTE: special-case: if currentDepth is already the maximum depth, do not attempt to recurse any further as we have already reached the maximum depth
        guard currentDepth < Int.max else {
            return nil
        }
        //
        return try MorphicA11yUIElement.firstAncestor(where: predicate, startingElement: parent, currentDepth: currentDepth + 1, maxDepth: maxDepth)
    }
    
    public func firstAncestor(identifier: String, maxDepth: Int = Int.max) throws -> MorphicA11yUIElement? {
        return try self.firstAncestor(
            where: { parent in
                // if the parent's identifier matches the requested identifier, return that parent
                let parentIdentifier: String?
                do {
                    parentIdentifier = try parent.value(forAttribute: .identifier)
                } catch let error {
                    throw error
                }
                guard let parentIdentifier = parentIdentifier else {
                    return false
                }
                return (parentIdentifier == identifier)
            },
            maxDepth: maxDepth
        )
    }
    
    public func firstAncestor(role: NSAccessibility.Role, maxDepth: Int = Int.max) throws -> MorphicA11yUIElement? {
        return try self.firstAncestor(where: { $0.role == role }, maxDepth: maxDepth)
    }
}
