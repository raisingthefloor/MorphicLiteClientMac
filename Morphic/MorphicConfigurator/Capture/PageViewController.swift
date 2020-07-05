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
        if animated{
            let dismissing = shown?.view.layer
            let presenting = viewController.view.layer
            presenting?.setAffineTransform(CGAffineTransform(translationX: view.bounds.width, y: 0))
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            CATransaction.setCompletionBlock{
                shown?.view.removeFromSuperview()
            }
            presenting?.setAffineTransform(.identity)
            dismissing?.setAffineTransform(CGAffineTransform(translationX: -view.bounds.width, y: 0))
            CATransaction.commit()
        }else{
            shown?.view.removeFromSuperview()
        }
    }
    
}
