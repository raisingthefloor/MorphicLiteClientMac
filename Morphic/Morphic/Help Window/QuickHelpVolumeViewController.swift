//
//  QuickHelpVolumeViewController.swift
//  Morphic
//
//  Created by Owen Shaw on 7/4/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

class QuickHelpVolumeViewController: NSViewController {
    
    /// The label that displays the help title
    @IBOutlet weak var titleLabel: NSTextField!
    
    /// The label that displays the detailed help message
    @IBOutlet weak var messageLabel: NSTextField!
    
    @IBOutlet weak var progressBar: ProgressIndicator!
    
    @IBOutlet weak var progressLabel: NSTextField!
    
    var percentageFormatter = NumberFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = CGColor(gray: 0, alpha: 0.8)
        view.layer?.cornerRadius = 6
        percentageFormatter.numberStyle = .percent
        updateTitleLabel()
        updateMessageLabel()
        updateVolume()
        updateMuted()
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
    
    public var volumeLevel: Double = 0.0{
        didSet{
            updateVolume()
        }
    }
    
    public func updateVolume(){
        progressLabel?.stringValue = percentageFormatter.string(from: NSNumber(floatLiteral: volumeLevel))!
        progressBar?.doubleValue = volumeLevel
    }
    
    public var muted: Bool = false{
        didSet{
            updateMuted()
        }
    }
    
    public func updateMuted(){
        if muted{
            progressLabel?.alphaValue = 0.5
            progressBar?.alphaValue = 0.5
        }else{
            progressLabel?.alphaValue = 1
            progressBar?.alphaValue = 1
        }
    }
    
}
