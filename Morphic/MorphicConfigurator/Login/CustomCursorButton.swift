//
//  CustomCursorButton.swift
//  MorphicConfigurator
//
//  Created by Owen Shaw on 7/4/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa

class CustomCursorButton: NSButton {

    public var cursor: NSCursor?{
        didSet{
            window?.invalidateCursorRects(for: self)
        }
    }
    
    override func resetCursorRects() {
        if let cursor = cursor{
            addCursorRect(bounds, cursor: cursor)
        }else{
            super.resetCursorRects()
        }
    }
}
