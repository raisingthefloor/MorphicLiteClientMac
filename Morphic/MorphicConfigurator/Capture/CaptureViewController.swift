//
//  CaptureViewController.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 6/24/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import MorphicCore
import MorphicSettings
import MorphicService

protocol CaptureViewControllerDelegate: class{
    
    func capture(_ viewController: CaptureViewController, didCapture preferences: Preferences)

}

class CaptureViewController: NSViewController {
    
    @IBOutlet weak var gearImage: NSImageView!
    
    weak var delegate: CaptureViewControllerDelegate?
    
    var captureSession: CaptureSession!
    
    var minimumTimeInterval: TimeInterval = 3
    var minimumTimer: Timer?
    
    var captureComplete = false
    var miniumTimeComplete = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let preferences = Session.shared.preferences ?? Preferences(identifier: "")
        captureSession = CaptureSession(settingsManager: Session.shared.settings, preferences: preferences)
        captureSession.addAllSolutions()
        captureSession.captureDefaultValues = false
        captureSession.run {
            self.captureComplete = true
            self.notifyDelegateIfFullyComplete()
        }
        minimumTimer = Timer.scheduledTimer(withTimeInterval: minimumTimeInterval, repeats: false){
            _ in
            self.miniumTimeComplete = true
            self.notifyDelegateIfFullyComplete()
        }
    }
    
    func notifyDelegateIfFullyComplete(){
        guard miniumTimeComplete && captureComplete else{
            return
        }
        stopAnimating()
        delegate?.capture(self, didCapture: captureSession.preferences)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        startAnimating()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        stopAnimating()
    }
    
    var animation: CABasicAnimation!
    
    func startAnimating(){
        animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = -CGFloat.pi * 2
        animation.repeatCount = .infinity
        animation.duration = 7
        gearImage.layer?.add(animation, forKey: "spin")
    }
    
    func stopAnimating(){
        gearImage.layer?.removeAnimation(forKey: "spin")
        animation = nil
    }
    
}

class ImageContainerView: NSView{
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        needsLayout = true
    }
    
    override func layout() {
        let center = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        for view in subviews{
            view.layer?.bounds = CGRect(origin: .zero, size: bounds.size)
            view.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            view.layer?.position = center
        }
    }
    
}
