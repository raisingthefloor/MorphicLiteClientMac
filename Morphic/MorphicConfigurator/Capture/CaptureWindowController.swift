//
//  CaptureWindowController.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 6/24/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import MorphicCore
import MorphicService

class CaptureWindowController: NSWindowController, CaptureViewControllerDelegate, CreateAccountViewControllerDelegate {
    
    var pageViewController = PageViewController(nibName: "PageViewController", bundle: nil)

    override func windowDidLoad() {
        super.windowDidLoad()
//        window?.backgroundColor = NSColor(named: "WindowBackgroundColor")
        window?.contentViewController = pageViewController
        showCapture(animated: false)
    }
    
    func showCapture(animated: Bool){
        let captureViewController = CaptureViewController(nibName: "CaptureViewController", bundle: nil)
        captureViewController.delegate = self
        pageViewController.show(viewController: captureViewController, animated: animated)
    }
    
    func capture(_ viewController: CaptureViewController, didCapture preferences: Preferences) {
        if Session.shared.user == nil{
            showCreateAccount(preferences: preferences, animated: true)
        }else{
            showDone(animated: true)
        }
    }
    
    func showCreateAccount(preferences: Preferences, animated: Bool){
        let createAccountViewController = CreateAccountViewController(nibName: "CreateAccountViewController", bundle: nil)
        createAccountViewController.preferences = preferences
        createAccountViewController.delegate = self
        pageViewController.show(viewController: createAccountViewController, animated: animated)
    }
    
    func createAccount(_ viewController: CreateAccountViewController, didCreate user: User) {
        showDone(animated: true)
    }
    
    func showDone(animated: Bool){
        let doneViewController = DoneViewController(nibName: "DoneViewController", bundle: nil)
        pageViewController.show(viewController: doneViewController, animated: animated)
    }

}
