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
        if let email = Session.shared.user?.email{
            emailLabel.stringValue = email
        }else{
            emailLabel.isHidden = true
            emailIntroLabel.isHidden = true
        }
    }
    
    @IBOutlet weak var emailLabel: NSTextField!
    @IBOutlet weak var emailIntroLabel: NSTextField!
    
    @IBAction
    func done(_ sender: Any?){
        NSApplication.shared.terminate(nil)
    }
}
