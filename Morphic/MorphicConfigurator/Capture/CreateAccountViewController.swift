//
//  CreateAccountViewController.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 6/24/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import MorphicCore
import MorphicSettings
import MorphicService

protocol CreateAccountViewControllerDelegate: class{
    
    func createAccount(_ viewController: CreateAccountViewController, didCreate user: User)

}

class CreateAccountViewController: NSViewController, NSTextFieldDelegate, PresentedPageViewController {
    
    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var confirmPasswordField: NSSecureTextField!
    @IBOutlet weak var submitButton: NSButton!
    
    var preferences: Preferences!
    
    weak var delegate: CreateAccountViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func pageTransitionCompleted(){
        view.window?.makeFirstResponder(emailField)
    }
    
    @IBAction
    func createAccount(_ sender: Any?){
        hideError()
        setFieldsEnabled(false)
        var user = User(identifier: "")
        user.email = emailField.stringValue.trimmingCharacters(in: .whitespaces)
        let creds = UsernameCredentials(username: user.email!, password: passwordField.stringValue)
        Session.shared.register(user: user, credentials: creds, preferences: preferences){
            result in
            switch result{
            case .success(let auth):
                DistributedNotificationCenter.default().postNotificationName(.morphicSignin, object: nil, userInfo: ["isRegister": true], deliverImmediately: true)
                self.delegate?.createAccount(self, didCreate: auth.user)
            case .badPassword:
                self.showError(message: "Password too short or easily guessed", pointingTo: self.passwordField)
                self.setFieldsEnabled(true)
                self.view.window?.makeFirstResponder(self.passwordField)
                self.hasTypedBothPasswords = false
                self.confirmPasswordField.stringValue = ""
            case .existingEmail:
                self.showError(message: "This email already has an account", pointingTo: self.emailField)
                self.setFieldsEnabled(true)
                self.view.window?.makeFirstResponder(self.emailField)
            case .invalidEmail:
                self.showError(message: "Must be an email address", pointingTo: self.emailField)
                self.setFieldsEnabled(true)
                self.view.window?.makeFirstResponder(self.emailField)
            case .error:
                let alert = NSAlert()
                alert.messageText = "Account Creation Failed"
                alert.informativeText = "Sorry we couldn't create your account right now.  Please try again."
                alert.runModal()
                self.setFieldsEnabled(true)
                self.view.window?.makeFirstResponder(self.emailField)
            }
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateValid()
        guard let field = obj.object as? NSTextField else{
            return
        }
        if (field == passwordField || field == confirmPasswordField){
            if hasTypedBothPasswords{
                updatePasswordMatch()
            }
        }
    }
    
    @IBOutlet weak var errorPopover: NSPopover!
    var hasTypedBothPasswords = false
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else{
            return
        }
        if field == passwordField || field == confirmPasswordField{
            if passwordField.stringValue.count > 0 && confirmPasswordField.stringValue.count > 0{
                hasTypedBothPasswords = true
                updatePasswordMatch()
            }
        }
    }
    
    func updatePasswordMatch(){
        if passwordField.stringValue.count > 0 && confirmPasswordField.stringValue.count > 0 && passwordField.stringValue != confirmPasswordField.stringValue{
            showError(message: "Passwords do not match", pointingTo: confirmPasswordField)
        }else{
            hideError()
        }
    }
    
    func updateValid(){
        submitButton.isEnabled = emailField.stringValue.trimmingCharacters(in: .whitespaces).count > 0 && passwordField.stringValue.count > 0 && passwordField.stringValue == confirmPasswordField.stringValue
    }
    
    func setFieldsEnabled(_ enabled: Bool){
        emailField.isEnabled = enabled
        passwordField.isEnabled = enabled
        confirmPasswordField.isEnabled = enabled
        submitButton.isEnabled = enabled
    }
    
    @IBOutlet var errorViewController: CreateAccountErrorViewController!
    
    func showError(message: String, pointingTo view: NSView){
        errorViewController.errorText = message
        errorPopover.show(relativeTo: view.bounds, of: view, preferredEdge: .maxX)
    }
    
    func hideError(){
        if errorPopover.isShown{
            errorPopover.close()
        }
    }
    
}

class CreateAccountErrorViewController: NSViewController{
    
    @IBOutlet weak var errorLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.stringValue = errorText ?? ""
    }
    
    var errorText: String?{
        didSet{
            errorLabel?.stringValue = errorText ?? ""
        }
    }
    
}
