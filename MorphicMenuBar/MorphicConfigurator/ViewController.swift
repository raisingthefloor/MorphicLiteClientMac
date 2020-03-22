//
//  ViewController.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import MorphicCore
import MorphicService
import CryptoKit

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
        let key = SymmetricKey(size: .init(bitCount: 512))
        let base64 = key.withUnsafeBytes{
            (bytes: UnsafeRawBufferPointer) in
            Data(Array(bytes)).base64EncodedString()
        }
        createUserButton.isEnabled = false
        _ = Session.shared.service.register(user: user, key: base64){
            auth in
            if auth != nil{
                Session.shared.savedKeyCredentials = KeyCredentials(key: base64)
                UserDefaults.morphic.setValue(user.identifier, forKey: .morphicDefaultsKeyUserIdentifier)
                NSApplication.shared.terminate(sender)
            }else{
                self.createUserButton.isEnabled = true
            }
        }
    }
    
    @IBAction
    func clearUser(_ sender: Any){
        UserDefaults.morphic.setValue(nil, forKey: .morphicDefaultsKeyUserIdentifier)
        NSApplication.shared.terminate(sender)
    }


}

