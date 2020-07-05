//
//  CaptureViewController.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 6/24/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

protocol CaptureViewControllerDelegate{
    
    func captureDidComplete()

}

class CaptureViewController: NSViewController {
    
    @IBOutlet weak var gearImage: NSImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    var animation: CABasicAnimation!
    
    func startAnimating(){
        animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.repeatCount = .infinity
        animation.duration = 4
        gearImage.layer?.add(animation, forKey: "spin")
    }
    
    func stopAnimating(){
        gearImage.layer?.removeAnimation(forKey: "spin")
        animation = nil
    }
    
}
