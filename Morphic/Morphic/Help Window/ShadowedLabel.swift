//
//  ShadowedLabel.swift
//  Morphic
//
//  Created by Owen Shaw on 4/17/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

public class ShadowedLabel: NSTextField {
    
    @IBInspectable public var textShadowColor: NSColor = .black
    @IBInspectable public var textShadowOffset = NSSize(width: 1, height: 2)
    @IBInspectable public var textShadowBlurRadius: CGFloat = 0
    
    public override var stringValue: String{
        get{
            return super.stringValue
        }
        set{
            super.stringValue = newValue
            let attributedValue = NSMutableAttributedString(attributedString: attributedStringValue)
            attributedValue.addAttributes([.shadow: textShadow], range: NSRange(location: 0, length: newValue.count))
            attributedStringValue = attributedValue
        }
    }
    
    public var textShadow: NSShadow{
        let shadow = NSShadow()
        shadow.shadowColor = textShadowColor
        shadow.shadowOffset = textShadowOffset
        shadow.shadowBlurRadius = textShadowBlurRadius
        return shadow
    }
    
    public override var intrinsicContentSize: NSSize{
        var size = super.intrinsicContentSize
        size.height += 4
        return size
    }
    
}
