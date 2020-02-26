//
//  QuickStripWindow.swift
//  MorphicMenuBar
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

class QuickStripWindow: NSWindow {
    
    override var canBecomeKey: Bool{
        return true
    }
    
    override var canBecomeMain: Bool{
        return false
    }

}
