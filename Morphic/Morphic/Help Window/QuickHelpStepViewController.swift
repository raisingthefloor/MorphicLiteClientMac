//
//  QuickHelpStepViewController.swift
//  Morphic
//
//  Created by Owen Shaw on 7/4/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

class QuickHelpStepViewController: NSViewController {
    
    /// The label that displays the help title
    @IBOutlet weak var titleLabel: NSTextField!
    
    /// The label that displays the detailed help message
    @IBOutlet weak var messageLabel: NSTextField!
    
    @IBOutlet weak var pageControl: PageControl!
    
    var percentageFormatter = NumberFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = CGColor(gray: 0, alpha: 0.8)
        view.layer?.cornerRadius = 6
        percentageFormatter.numberStyle = .percent
        updateTitleLabel()
        updateMessageLabel()
        updateStep()
    }
    
    /// The text to display in the title label
    public var titleText: String = ""{
        didSet{
            updateTitleLabel()
        }
    }
    
    public func updateTitleLabel(){
        titleLabel?.stringValue = titleText
    }
    
    /// The text to display in the message label
    public var messageText: String = ""{
        didSet{
            updateMessageLabel()
        }
    }
    
    public func updateMessageLabel(){
        messageLabel?.stringValue = messageText
    }
    
    public var numberOfSteps: Int = 1{
        didSet{
            updateStep()
        }
    }
    
    public var step: Int = 0{
        didSet{
            updateStep()
        }
    }
    
    public func updateStep(){
        pageControl?.numberOfPages = numberOfSteps
        pageControl?.selectedPage = step
    }
    
}
