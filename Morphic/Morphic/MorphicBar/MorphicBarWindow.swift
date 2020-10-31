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

import Carbon.HIToolbox
import Cocoa
import MorphicCore
import MorphicService
import MorphicSettings

/// A window that displays the MorphicBar
///
/// This class takes care of window styling, but leaves most of the work to the `MorphicBarViewController`,
/// which is installed as the window's `contentViewController`
///
/// A MorphicBar window is always on top of other windows so it's never lost, and can only occupy corner
/// locations on a screen, and will snap to the closest corner whenever the user moves the window.
public class MorphicBarWindow: NSWindow {
    
    public var morphicBarViewController: MorphicBarViewController
    
    /// Create a new MorphicBar Window with a `MorphicBarViewController` as its `contentViewController`
    public init() {
        morphicBarViewController = MorphicBarViewController.init(nibName: nil, bundle: nil)
        super.init(contentRect: NSMakeRect(0, 0, 100, 100), styleMask: .borderless, backing: .buffered, defer: false)
        contentViewController = morphicBarViewController
        hasShadow = true
        isReleasedWhenClosed = false
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces]
        if let savedPosition = Position(rawValue: Session.shared.string(for: .morphicBarPosition) ?? "") {
            position = savedPosition
        }
        setAccessibilityLabel("MorphicBar")
        updateMorphicBar()
        NotificationCenter.default.addObserver(self, selector: #selector(MorphicBarWindow.userDidChange(_:)), name: .morphicSessionUserDidChange, object: Session.shared)
    }
    
    @objc
    func userDidChange(_ notification: NSNotification) {
        updateMorphicBar()
    }
    
    var windowIsKey: Bool = false
    var currentFirstResponderChildView: NSView? = nil
    
    public override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.keyCode == kVK_ANSI_W {
            // close the window
            AppDelegate.shared.hideMorphicBar(nil)
        } else if event.modifierFlags.contains(.command) && event.keyCode == kVK_ANSI_Q {
            // quit Morphic
            AppDelegate.shared.quitApplication(nil)
        } else if event.keyCode == kVK_Escape {
            // activate the topmost window
            activateTopmostWindow()
        } else {
            super.keyDown(with: event)
        }
    }
    
    func activateTopmostWindow() {
        // get window ID of the topmost window
        guard let (_ /* topmostWindowOwnerName */, topmostProcessId) = MorphicWindow.getWindowOwnerNameAndProcessIdOfTopmostWindow() else {
            NSLog("Could not get ID of topmost window")
            return
        }

        // capture a reference to the topmost application
        guard let topmostApplication = NSRunningApplication(processIdentifier: pid_t(topmostProcessId)) else {
            NSLog("Could not get reference to application owning the topmost window")
            return
        }

        // activate the topmost application
        guard topmostApplication.activate(options: .activateIgnoringOtherApps) == true else {
            NSLog("Could not activate the topmost window")
            return
        }
    }
        
    static var showsHelpByDefault: Bool {
        #if EDITION_BASIC
            return true
        #elseif EDITION_COMMUNITY
            return false
        #endif
    }
    
    var showsHelp: Bool {
        get {
            let showsHelpByDefault = MorphicBarWindow.showsHelpByDefault
            #if EDITION_BASIC
                return Session.shared.bool(for: .morphicBarShowsHelp) ?? showsHelpByDefault
            #elseif EDITION_COMMUNITY
                // NOTE: for now, permanently surpress the help pop-up in Morphic Community
                return showsHelpByDefault
            #endif
        }
    }
    
    func setShowsHelp(_ state: Bool) {
        Session.shared.set(state, for: .morphicBarShowsHelp)
    }
    
    func updateMorphicBar() {
        morphicBarViewController.showsHelp = self.showsHelp
        
        #if EDITION_BASIC
            if let preferredItems = Session.shared.array(for: .morphicBarItems) {
                morphicBarViewController.items = MorphicBarItem.items(from: preferredItems)
            }
        #elseif EDITION_COMMUNITY
            if let communityBarsAsJson = Session.shared.dictionary(for: .morphicBarCommunityBarsAsJson),
                communityBarsAsJson.count > 0 {
                if let user = Session.shared.user {
                    let userSelectedCommunityId = UserDefaults.morphic.selectedUserCommunityId(for: user.identifier)
                    if userSelectedCommunityId != nil && communityBarsAsJson[userSelectedCommunityId!] != nil {
                        let selectedCommunityBarAsJsonString = communityBarsAsJson[userSelectedCommunityId!] as! String
                        let selectedCommunityBarAsJsonData = selectedCommunityBarAsJsonString.data(using: .utf8)!
                        let selectedCommunityBar = try! JSONDecoder().decode(Service.UserCommunityDetails.self, from: selectedCommunityBarAsJsonData)
                        
                        let encodedMorphicBarItems = selectedCommunityBar.encodeAsMorphicBarItems()
                        morphicBarViewController.items = MorphicBarItem.items(from: encodedMorphicBarItems)
                    }
                }
            }
        #endif
        morphicBarViewController.shrinkFitWindow()
        // now that we have updated the items in our bar, update the accessibility children list as well (so that left/right voiceover nav works properly)
        setAccessibilityChildren(morphicBarViewController.accessibilityChildren())
        reposition(animated: false)
    }
    
    func updateShowsHelp() {
        let showsHelp = self.showsHelp
        
        morphicBarViewController.showsHelp = showsHelp
        
        for subview in morphicBarViewController.morphicBarView.subviews {
            if let barItem = subview as? MorphicBarItemViewProtocol {
                barItem.showsHelp = showsHelp
            }
        }
    }
    
    public override var canBecomeKey: Bool {
        return true
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
    
    /// The allowed positions for the window
    public enum Position: String {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        
        /// Determine the origin for the given window at this position
        fileprivate func origin(for window: MorphicBarWindow) -> NSPoint {
            guard let screen = window.screen else{
                return .zero
            }
            switch self {
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
    
    /// How far from the screen edges the window should position itself
    public var screenInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4) {
        didSet{
            reposition(animated: false)
        }
    }
    
    /// The window's current position
    public private(set) var position: Position = .topRight
    
    /// Change the window's position, optionally animating the change
    public func setPosition(_ position: Position, animated: Bool) {
        let changed = self.position != position
        self.position = position
        reposition(animated: animated)
        if changed {
            Session.shared.set(position.rawValue, for: .morphicBarPosition)
        }
    }
    
    /// The nearst position to the window's current location
    ///
    /// Useful after a window has been moved by the user
    private var nearestPosition: Position {
        guard let area = screen?.visibleFrame else {
            return position
        }
        let windowCenter = frame.center
        let areaCenter = area.center
        if windowCenter.x < areaCenter.x {
            if windowCenter.y < areaCenter.y {
                return .bottomLeft
            }
            return .topLeft
        } else {
            if windowCenter.y < areaCenter.y {
                return .bottomRight
            }
            return .topRight
        }
    }
    
    /// Move the window to its position
    func reposition(animated: Bool) {
        layoutIfNeeded()
        morphicBarViewController.position = position
        let origin = position.origin(for: self)
        let frame = NSRect(origin: origin, size: self.frame.size)
        setFrame(frame, display: true, animate: animated)
    }
    
    public var orientation: MorphicBarOrientation = .horizontal {
        didSet {
            morphicBarViewController.orientation = self.orientation
            reposition(animated: false)
        }
    }    

    public override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        setPosition(nearestPosition, animated: true)
    }
    
    /*
    public override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        AsyncUtils.wait(atMost: 1, for: {false}, completion: {_ in
            self.morphicBarViewController.position = self.nearestPosition
        })
    }
 */
    
    /*uncomment to have tray close when you drag the bar
    public override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        if(orientation == .vertical && !morphicBarViewController.morphicTrayView.collapsed) {
            morphicBarViewController.closeTray(nil)
        }
    }
    */

}

/// Custom `NSView` that accepts first mouse to ensure proper window movement behavior
class MorphicBarWindowContentView: NSView {
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        // accept first mouse so the event propagates up to the window and we
        // can intercept mouseUp to snap the window to a corner
        return true
    }
}

private extension NSRect {
    
    /// The center point of the rectangle
    var center: NSPoint {
        return NSPoint(x: origin.x + size.width / 2.0, y: origin.y + size.height / 2.0)
    }
    
}

public extension Preferences.Key {
    
    /// The preference key that stores the position for the MorphicBar window on mac
    ///
    /// It is platform specific because mac controls tend to be at the top of the screen while windows
    /// controls tend to be at the bottom.  A user who works between platforms can move the MorphicBar
    /// on one platform without affecting the MorphicBar's location on the other.
    #if EDITION_BASIC
        static var morphicBarPosition = Preferences.Key(solution: "org.raisingthefloor.morphic.morphicbarbasic", preference: "position.mac")
    #elseif EDITION_COMMUNITY
        static var morphicBarPosition = Preferences.Key(solution: "org.raisingthefloor.morphic.morphicbarcommunity", preference: "position.mac")
    #endif

    /// The preference key that stores whether the MorphicBar should always appear at startup
    #if EDITION_BASIC
        static var showMorphicBarAtStart = Preferences.Key(solution: "org.raisingthefloor.morphic.morphicbarbasic", preference: "showMorphicBarAtStart")
    #elseif EDITION_COMMUNITY
        static var showMorphicBarAtStart = Preferences.Key(solution: "org.raisingthefloor.morphic.morphicbarcommunity", preference: "showMorphicBarAtStart")
    #endif

    /// The preference key that stores whether the MorphicBar should appear by default
    #if EDITION_BASIC
        static var morphicBarVisible = Preferences.Key(solution: "org.raisingthefloor.morphic.morphicbarbasic", preference: "visible")
    #elseif EDITION_COMMUNITY
        static var morphicBarVisible = Preferences.Key(solution: "org.raisingthefloor.morphic.morphicbarcommunity", preference: "visible")
    #endif
    
    /// The preference key that stores whether the MorphicBar buttons should show giant help tips
    #if EDITION_BASIC
        static var morphicBarShowsHelp = Preferences.Key(solution: "org.raisingthefloor.morphic.morphicbarbasic", preference: "showsHelp")
    #elseif EDITION_COMMUNITY
        static var morphicBarShowsHelp = Preferences.Key(solution: "org.raisingthefloor.morphic.morphicbarcommunity", preference: "showsHelp")
    #endif
    
    /// The preference key that stores which items appear on the MorphicBar (Morphic Basic personal bar)
    #if EDITION_BASIC
        static var morphicBarItems = Preferences.Key(solution: "org.raisingthefloor.morphic.morphicbarbasic", preference: "items")
    #elseif EDITION_COMMUNITY
//        static var morphicBarItems = Preferences.Key(solution: "org.raisingthefloor.morphic.morphicbarcommunity", preference: "items")
    #endif
}

public enum MorphicBarOrientation {
    case horizontal
    case vertical
}
