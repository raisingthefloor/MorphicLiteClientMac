//
//  CheckboxElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class CheckboxElement: UIElement{
    
    public enum State{
        case checked
        case unchecked
        case mixed
        case unknown
    }
    
    public var state: State {
        guard let checked: Bool = accessibilityElement.value(forAttribute: .value) else{
            return .unknown
        }
        if checked{
            return .checked
        }
        return .unchecked
    }
    
    public func setChecked(_ checked: Bool) -> Bool{
        if checked{
            return check()
        }else{
            return uncheck()
        }
    }
    
    public func check() -> Bool{
        switch state{
        case .checked:
            return true
        case .unchecked, .mixed:
            if !accessibilityElement.perform(action: .press){
                return false
            }
            return state == .checked
        case .unknown:
            return false
        }
    }
    
    public func uncheck() -> Bool{
        switch state{
        case .unchecked:
            return true
        case .checked, .mixed:
            if !accessibilityElement.perform(action: .press){
                return false
            }
            return state == .unchecked
        case .unknown:
            return false
        }
    }
    
}
