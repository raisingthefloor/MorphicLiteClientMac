//
//  UIAutomation.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/26/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore

public protocol UIAutomation{
    
    init()
    
    func apply(_ value: Interoperable?, completion: @escaping (_ success: Bool) -> Void)
    
}
