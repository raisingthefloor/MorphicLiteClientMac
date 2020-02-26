//
//  ViewController.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import MorphicCore

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        createUserButton.isHidden = UserDefaults.morphic.string(forKey: .morphicDefaultsKeyUserIdentifier) != nil
        clearUserButton.isHidden = !createUserButton.isHidden
        
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    @IBOutlet weak var createUserButton: NSButton!
    @IBOutlet weak var clearUserButton: NSButton!
    
    @IBAction
    func createTestUser(_ sender: Any){
        let user = User()
        UserDefaults.morphic.setValue(user.identifier, forKey: .morphicDefaultsKeyUserIdentifier)
        NSApplication.shared.terminate(sender)
    }
    
    @IBAction
    func clearUser(_ sender: Any){
        UserDefaults.morphic.setValue(nil, forKey: .morphicDefaultsKeyUserIdentifier)
        NSApplication.shared.terminate(sender)
    }


}

