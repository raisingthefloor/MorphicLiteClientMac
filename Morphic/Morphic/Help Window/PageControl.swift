//
//  PageControl.swift
//  Morphic
//
//  Created by Owen Shaw on 7/4/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

class PageControl: NSView {
    
    public var numberOfPages: Int = 1{
        didSet{
            invalidateIntrinsicContentSize()
            setNeedsDisplay(bounds)
        }
    }
    
    public var selectedPage: Int = -1{
        didSet{
            setNeedsDisplay(bounds)
        }
    }
    
    @IBInspectable
    public var dotColor: NSColor = .white{
        didSet{
            setNeedsDisplay(bounds)
        }
    }
    
    public var dotSize: CGFloat{
        bounds.height
    }
    
    public var dotSpacing: CGFloat{
        dotSize
    }
    
    override var intrinsicContentSize: NSSize{
        return NSSize(width: CGFloat(numberOfPages) * dotSize + CGFloat(numberOfPages - 1) * dotSpacing, height: NSView.noIntrinsicMetric)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else{
            return
        }
        context.saveGState()
        context.setFillColor(dotColor.cgColor)
        context.setStrokeColor(dotColor.cgColor)
        context.setLineWidth(1.0)
        var x: CGFloat = 0
        for i in 0..<numberOfPages{
            let rect = CGRect(x: x, y: 0, width: dotSize, height: dotSize)
            if i == selectedPage{
                context.fillEllipse(in: rect)
            }else{
                context.strokeEllipse(in: rect)
            }
            x += dotSize + dotSpacing
        }
        context.restoreGState()
    }
    
}
