//
//  ProgressIndicator.swift
//  Morphic
//
//  Created by Owen Shaw on 7/4/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

class ProgressIndicator: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit(){
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.borderWidth = borderWidth
        layer?.borderColor = borderColor.cgColor
        layer?.cornerRadius = bounds.height / 2.0
        barLayer.backgroundColor = barColor.cgColor
        layer?.addSublayer(barLayer)
        updateBar()
    }
    
    private var barLayer = CALayer()
    
    @IBInspectable
    public var barColor: NSColor = .white{
        didSet{
            barLayer.backgroundColor = barColor.cgColor
            setNeedsDisplay(bounds)
        }
    }
    
    @IBInspectable
    public var borderColor: NSColor = .white{
        didSet{
            layer?.borderColor = borderColor.cgColor
        }
    }
    
    public var borderWidth: CGFloat = 1.0{
        didSet{
            layer?.borderWidth = borderWidth
        }
    }
    
    public var doubleValue: Double = 0.0{
        didSet{
            updateBar()
        }
    }
    
    func updateBar(){
        barLayer.frame = CGRect(x: 0, y: 0, width: bounds.width * CGFloat(doubleValue), height: bounds.height)
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        layer?.cornerRadius = bounds.height / 2.0
        updateBar()
    }
    
}
