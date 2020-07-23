//
//  SelectElement.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/29/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class PopUpButtonElement: UIElement{
    
    public var value: String?{
        get{
            accessibilityElement.value(forAttribute: .value)
        }
    }
    
    public func setValue(_ value: String, completion: @escaping (_ success: Bool) -> Void){
        guard accessibilityElement.perform(action: .showMenu) else{
            completion(false)
            return
        }
        self.wait(atMost: 2.0, for: { self.menu != nil }){
            sucess in
            guard let menu = self.menu else{
                completion(false)
                return
            }
            guard menu.select(itemTitled: value) else{
                completion(false)
                return
            }
            self.wait(atMost: 2.0, for: { self.value == value }){
                success in
                completion(success)
            }
        }
    }
    
}
