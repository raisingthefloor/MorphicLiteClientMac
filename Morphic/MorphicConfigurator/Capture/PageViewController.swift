//
//  PageViewController.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 6/24/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

class PageViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func show(viewController: NSViewController, animated: Bool){
        let shown = children.first
        shown?.removeFromParent()
        addChild(viewController)
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        let completion = {
            shown?.view.removeFromSuperview()
            if let presentedViewController = viewController as? PresentedPageViewController{
                presentedViewController.pageTransitionCompleted()
            }
        }
        if animated{
            let dismissing = shown?.view
            let presenting = viewController.view
            presenting.frame = NSRect(origin: NSPoint(x: self.view.bounds.width, y: 0), size: view.bounds.size)
            NSAnimationContext.runAnimationGroup({
                context in
                context.duration = 0.4
                presenting.animator().frame = NSRect(origin: .zero, size: self.view.bounds.size)
                dismissing?.animator().frame = NSRect(origin: NSPoint(x: -self.view.bounds.width, y: 0), size: self.view.bounds.size)
                dismissing?.animator().alphaValue = 0.0
            }, completionHandler: completion)
        }else{
            completion()
        }
    }
    
}

protocol PresentedPageViewController{
    
    func pageTransitionCompleted()
    
}
