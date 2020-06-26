//
//  TabElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/26/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class TabElement: UIElement{
    
    public enum State{
        case normal
        case selected
        case unknown
    }
    
    public var state: State {
        guard let selected: Bool = accessibilityElement.value(forAttribute: .value) else{
            return .unknown
        }
        if selected{
            return .selected
        }
        return .normal
    }
    
    public func select() -> Bool{
        switch state{
        case .selected:
            return true
        case .normal:
            if !accessibilityElement.perform(action: .press){
                return false
            }
            return state == .selected
        case .unknown:
            return false
        }
    }
    
}
