//
//  QuickHelpWindow.swift
//  Morphic
//
//  Created by Owen Shaw on 4/17/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

class QuickHelpWindow: NSWindow {
    
    private var quickHelpViewController: QuickHelpViewController
    
    /// Create a new Quick Strip Window with a `QuickStripViewController` as its `contentViewController`
    private init(){
        quickHelpViewController = QuickHelpViewController.init(nibName: nil, bundle: nil)
        super.init(contentRect: NSMakeRect(0, 0, 100, 100), styleMask: .borderless, backing: .buffered, defer: false)
        contentViewController = quickHelpViewController
        hasShadow = false
        isReleasedWhenClosed = false
        level = .floating
        backgroundColor = .clear
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces]
        ignoresMouseEvents = true
        reposition()
    }
    
    private static var shared: QuickHelpWindow?
    
    public static func show(title: String, message: String){
        if shared == nil{
            shared = QuickHelpWindow()
        }
        shared?.quickHelpViewController.titleText = title
        shared?.quickHelpViewController.messageText = message
        shared?.makeKeyAndOrderFront(nil)
        shared?.hideQueued = false
    }
    
    private var hideQueued = false
    
    public static func hide(){
        shared?.hideQueued = true
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false){
            timer in
            if shared?.hideQueued ?? false{
                shared?.close()
                shared = nil
            }
        }
    }
    
    override var canBecomeKey: Bool{
        return false
    }
    
    override var canBecomeMain: Bool{
        return false
    }
    
    func reposition(){
        guard let screen = screen else{
            return
        }
        let frame = NSRect(x: round((screen.visibleFrame.width - self.frame.size.width) / 2), y: round((screen.visibleFrame.width - self.frame.size.width) / 2), width: self.frame.size.width, height: self.frame.size.height)
        setFrame(frame, display: true, animate: false)
    }
}
