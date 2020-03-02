//
//  QuickStripWindow.swift
//  MorphicMenuBar
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

class QuickStripWindow: NSWindow {
    
    init(){
        super.init(contentRect: NSMakeRect(0, 0, 137, 137), styleMask: .borderless, backing: .buffered, defer: false)
        contentViewController = QuickStripViewController.init(nibName: "QuickStrip", bundle: nil)
        hasShadow = true
        isReleasedWhenClosed = false
    }
    
    override var canBecomeKey: Bool{
        return true
    }
    
    override var canBecomeMain: Bool{
        return false
    }

}
