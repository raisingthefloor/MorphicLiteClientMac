//
//  CaptureWindowController.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 6/24/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import MorphicService

class CaptureWindowController: NSWindowController, CaptureViewControllerDelegate, CreateAccountViewControllerDelegate {
    
    var pageViewController = PageViewController(nibName: "PageViewController", bundle: nil)

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.contentViewController = pageViewController
        showCapture(animated: false)
    }
    
    func showCapture(animated: Bool){
        let captureViewController = CaptureViewController(nibName: "CaptureViewController", bundle: nil)
        pageViewController.show(viewController: captureViewController, animated: animated)
    }
    
    func captureDidComplete() {
        if Session.shared.user == nil{
            showCreateAccount(animated: true)
        }else{
            showDone(animated: true)
        }
    }
    
    func showCreateAccount(animated: Bool){
        let createAccountViewController = CreateAccountViewController(nibName: "CreateAccountViewController", bundle: nil)
        pageViewController.show(viewController: createAccountViewController, animated: animated)
    }
    
    func createAccountDidComplete() {
        showDone(animated: true)
    }
    
    func showDone(animated: Bool){
        let doneViewController = DoneViewController(nibName: "DoneViewController", bundle: nil)
        pageViewController.show(viewController: doneViewController, animated: animated)
    }

}
