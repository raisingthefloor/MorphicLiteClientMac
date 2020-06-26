//
//  LabelElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class LabelElement: UIElement{
    
    public var text: String?{
        get{
            guard let value: String = accessibilityElement.value(forAttribute: .value) else{
                return nil
            }
            return value
        }
    }
}
