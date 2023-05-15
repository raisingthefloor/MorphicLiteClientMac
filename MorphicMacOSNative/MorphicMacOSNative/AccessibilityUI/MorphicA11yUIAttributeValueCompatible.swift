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

public protocol FoundationA11yUIAttributeValueCompatible {
}
extension NSNumber: FoundationA11yUIAttributeValueCompatible {
}

public enum MorphicA11yUIAttributeValueCompatibleError: Error {
    case couldNotConvertValue
    case couldNotInitializeA11yUIElement(initError: MorphicA11yUIElement.InitError)
    case unsupportedAxValueType(_ axValueType: AXValueType)
    case unsupportedCoreFoundationType(_ cfTypeId: CFTypeID)
}

public protocol MorphicA11yUIAttributeValueCompatible: FoundationA11yUIAttributeValueCompatible {
    static func fromCFTypeRef(_ value: AnyObject) throws -> FoundationA11yUIAttributeValueCompatible
    func toCFTypeRef() -> CFTypeRef
}
extension MorphicA11yUIAttributeValueCompatible {
    public static func fromCFTypeRef(_ axValue: CFTypeRef) throws -> FoundationA11yUIAttributeValueCompatible {
        // determine Core Foundation type (so we can handle UIElements separately from Core Foundation data types
        let coreFoundationTypeId = CFGetTypeID(axValue)

        if axValue is NSNumber {
            return axValue as! NSNumber
        }
        if axValue is String {
            return axValue as! String
        }
        
        if coreFoundationTypeId == AXUIElementGetTypeID() {
            let valueAsAxValue = axValue as! AXUIElement
            
            do {
                let result = try MorphicA11yUIElement(axUiElement: valueAsAxValue)
                return result
            } catch let error as MorphicA11yUIElement.InitError {
                throw MorphicA11yUIAttributeValueCompatibleError.couldNotInitializeA11yUIElement(initError: error)
            }
        } else if coreFoundationTypeId == AXValueGetTypeID() {
            // get type of AXValue
            let valueAsAxValue: AXValue = axValue as! AXValue
            let axValueType: AXValueType = AXValueGetType(valueAsAxValue)
            
            switch axValueType {
            case .cfRange:
                var result: CFRange = CFRange()
                let success = AXValueGetValue(valueAsAxValue, axValueType, &result)
                if success == false {
                    throw MorphicA11yUIAttributeValueCompatibleError.couldNotConvertValue
                }
                return result
            case .cgPoint:
                var result: CGPoint = CGPoint()
                let success = AXValueGetValue(valueAsAxValue, axValueType, &result)
                if success == false {
                    throw MorphicA11yUIAttributeValueCompatibleError.couldNotConvertValue
                }
                return result
            case .cgRect:
                var result: CGRect = CGRect()
                let success = AXValueGetValue(valueAsAxValue, axValueType, &result)
                if success == false {
                    throw MorphicA11yUIAttributeValueCompatibleError.couldNotConvertValue
                }
                return result
            case .cgSize:
                var result: CGSize = CGSize()
                let success = AXValueGetValue(valueAsAxValue, axValueType, &result)
                if success == false {
                    throw MorphicA11yUIAttributeValueCompatibleError.couldNotConvertValue
                }
                return result
            case .axError:
                throw MorphicA11yUIAttributeValueCompatibleError.unsupportedAxValueType(axValueType)
            case .illegal:
                throw MorphicA11yUIAttributeValueCompatibleError.unsupportedAxValueType(axValueType)
            @unknown default:
                throw MorphicA11yUIAttributeValueCompatibleError.unsupportedAxValueType(axValueType)
            }
        } else {
            throw MorphicA11yUIAttributeValueCompatibleError.unsupportedCoreFoundationType(coreFoundationTypeId)
        }
    }
}
extension Bool: MorphicA11yUIAttributeValueCompatible {
    public func toCFTypeRef() -> CFTypeRef {
        return self as CFTypeRef
    }
}
extension Double: MorphicA11yUIAttributeValueCompatible {
    public func toCFTypeRef() -> CFTypeRef {
        return self as CFTypeRef
    }
}
extension Int: MorphicA11yUIAttributeValueCompatible {
    public func toCFTypeRef() -> CFTypeRef {
        return self as CFTypeRef
    }
}
extension CFRange: MorphicA11yUIAttributeValueCompatible {
    public func toCFTypeRef() -> CFTypeRef {
        var mutableSelf = self
        return AXValueCreate(.cfRange, &mutableSelf)!
    }
}
extension CGPoint: MorphicA11yUIAttributeValueCompatible {
    public func toCFTypeRef() -> CFTypeRef {
        var mutableSelf = self
        return AXValueCreate(.cgPoint, &mutableSelf)!
    }
}
extension CGRect: MorphicA11yUIAttributeValueCompatible {
    public func toCFTypeRef() -> CFTypeRef {
        var mutableSelf = self
        return AXValueCreate(.cgRect, &mutableSelf)!
    }
}
extension CGSize: MorphicA11yUIAttributeValueCompatible {
    public func toCFTypeRef() -> CFTypeRef {
        var mutableSelf = self
        return AXValueCreate(.cgSize, &mutableSelf)!
    }
}
extension MorphicA11yUIElement: MorphicA11yUIAttributeValueCompatible {
    public func toCFTypeRef() -> CFTypeRef {
        return self.axUiElement as CFTypeRef
    }
}
extension String: MorphicA11yUIAttributeValueCompatible {
    public func toCFTypeRef() -> CFTypeRef {
        return self as CFTypeRef
    }
}

internal struct MorphicA11yAttributeValueCompatibleSampleImpl: MorphicA11yUIAttributeValueCompatible {
    public func toCFTypeRef() -> CFTypeRef {
        fatalError("not implemented")
    }
}
