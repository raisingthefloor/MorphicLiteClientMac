//
//  DoneViewController.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 6/24/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import MorphicCore
import MorphicService

class DoneViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        emailLabel.stringValue = Session.shared.user?.email ?? ""
    }
    
    @IBOutlet weak var emailLabel: NSTextField!
    
    @IBAction
    func done(_ sender: Any?){
        NSApplication.shared.terminate(nil)
    }
}
