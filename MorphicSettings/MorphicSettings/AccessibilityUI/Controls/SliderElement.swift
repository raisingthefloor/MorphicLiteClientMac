//
//  SliderElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/29/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class SliderElement: UIElement{
    
    public var value: Double?{
        get{
            accessibilityElement.value(forAttribute: .value)
        }
    }
    
    public func setValue(_ value: Double) -> Bool{
        guard accessibilityElement.setValue(value, forAttribute: .value) else{
            return false
        }
        return true
    }
}
