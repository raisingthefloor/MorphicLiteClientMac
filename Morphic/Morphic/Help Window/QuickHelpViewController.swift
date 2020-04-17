//
//  QuickHelpViewController.swift
//  Morphic
//
//  Created by Owen Shaw on 4/17/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

class QuickHelpViewController: NSViewController {
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var messageLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = CGColor(gray: 0, alpha: 0.7)
        view.layer?.cornerRadius = 6
        titleLabel.stringValue = titleText
        messageLabel.stringValue = messageText
    }
    
    public var titleText: String = ""{
        didSet{
            titleLabel?.stringValue = titleText
        }
    }
    
    public var messageText: String = ""{
        didSet{
            messageLabel?.stringValue = messageText
        }
    }
    
}
