//
//  LoginWindowController.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 6/24/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import MorphicCore
import MorphicSettings
import MorphicService

class LoginWindowController: NSWindowController, NSTextFieldDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
//        window?.backgroundColor = NSColor(named: "WindowBackgroundColor")
        forgotPasswordButton.cursor = .pointingHand
    }
    
    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var submitButton: NSButton!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var forgotPasswordButton: CustomCursorButton!
    
    @IBAction
    func login(_ sender: Any?){
        errorLabel.isHidden = true
        setFieldsEnabled(false)
        let creds = UsernameCredentials(username: usernameField.stringValue, password: passwordField.stringValue)
        _ = Session.shared.authenticate(usingUsername: creds){
            success in
            guard success else{
                self.setFieldsEnabled(true)
                self.errorLabel.isHidden = false
                return
            }
//            self.indicateActivity(withStatusText: "Applying your settings...")
            DistributedNotificationCenter.default().postNotificationName(.morphicSignin, object: nil, userInfo: nil, deliverImmediately: true)
            NSApplication.shared.terminate(nil)
        }
    }
    
    @IBAction
    func forgotPassword(_ sender: Any?){
        guard let urlString = Bundle.main.infoDictionary?["FrontEndURL"] as? String else{
            return
        }
        let url = URL(string: urlString)!.appendingPathComponent("password").appendingPathComponent("reset")
        NSWorkspace.shared.open(url)
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateValid()
    }
    
    func setFieldsEnabled(_ enabled: Bool){
        usernameField.isEnabled = enabled
        passwordField.isEnabled = enabled
        submitButton.isEnabled = enabled
    }
    
    func indicateActivity(withStatusText text: String?){
        statusLabel.isHidden = false
        statusLabel.stringValue = text ?? ""
        activityIndicator.startAnimation(nil)
    }
    
    func updateValid(){
        submitButton.isEnabled = usernameField.stringValue.trimmingCharacters(in: .whitespaces).count > 0 && passwordField.stringValue.count > 0
    }
    
    func stopActivity(){
        statusLabel.isHidden = true
        activityIndicator.stopAnimation(nil)
    }

}
