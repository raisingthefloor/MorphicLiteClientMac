//
//  CaptureWindowController.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 6/24/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

class CaptureWindowController: NSWindowController {
    
    var pageViewController = PageViewController()

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.contentViewController = pageViewController
    }
    
    func showCapture(){
    }
    
    func showCreateAccount(){
    }
    
    func showDone(){
    }

}
