//
//  QuickHelpContentProvider.swift
//  Morphic
//
//  Created by Owen Shaw on 7/4/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

protocol QuickHelpContentProvider {
    
    func quickHelpViewController() -> NSViewController?
    
}
