// Copyright 2020 Raising the Floor - International
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Cocoa

class QuickStripWindow: NSWindow {
    
    init(){
        super.init(contentRect: NSMakeRect(0, 0, 137, 137), styleMask: .borderless, backing: .buffered, defer: false)
        contentViewController = QuickStripViewController.init(nibName: "QuickStrip", bundle: nil)
        hasShadow = true
        isReleasedWhenClosed = false
        level = .floating
        backgroundColor = .clear
        isMovableByWindowBackground = true
        reposition()
    }
    
    override var canBecomeKey: Bool{
        return true
    }
    
    override var canBecomeMain: Bool{
        return false
    }
    
    enum Position{
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        
        func origin(for window: QuickStripWindow) -> NSPoint{
            guard let screen = window.screen else{
                return .zero
            }
            switch self{
            case .topLeft:
                return NSPoint(x: screen.visibleFrame.origin.x + window.screenInsets.left, y: screen.visibleFrame.origin.y + screen.visibleFrame.size.height - window.frame.size.height - window.screenInsets.top)
            case .topRight:
                return NSPoint(x: screen.visibleFrame.origin.x + screen.visibleFrame.size.width - window.screenInsets.right - window.frame.size.width, y: screen.visibleFrame.origin.y + screen.visibleFrame.size.height - window.frame.size.height - window.screenInsets.top)
            case .bottomLeft:
                return NSPoint(x: screen.visibleFrame.origin.x + window.screenInsets.left, y: screen.visibleFrame.origin.y + window.screenInsets.bottom)
            case .bottomRight:
                return NSPoint(x: screen.visibleFrame.origin.x + screen.visibleFrame.size.width - window.screenInsets.right - window.frame.size.width, y: screen.visibleFrame.origin.y + window.screenInsets.bottom)
            }
        }
    }
    
    var screenInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4){
        didSet{
            reposition()
        }
    }
    
    var position: Position = .topRight{
        didSet{
            reposition()
        }
    }
    
    var nearestPosition: Position{
        guard let area = screen?.visibleFrame else{
            return position
        }
        let windowCenter = frame.center
        let areaCenter = area.center
        if windowCenter.x < areaCenter.x{
            if windowCenter.y < areaCenter.y{
                return .bottomLeft
            }
            return .topLeft
        }else{
            if windowCenter.y < areaCenter.y{
                return .bottomRight
            }
            return .topRight
        }
    }
    
    private func reposition(){
        let origin = position.origin(for: self)
        setFrameOrigin(origin)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        let origin = nearestPosition.origin(for: self)
        let frame = NSRect(origin: origin, size: self.frame.size)
        setFrame(frame, display: true, animate: true)
    }

}

private extension NSRect{
    var center: NSPoint{
        return NSPoint(x: origin.x + size.width / 2.0, y: origin.y + size.height / 2.0)
    }
}
