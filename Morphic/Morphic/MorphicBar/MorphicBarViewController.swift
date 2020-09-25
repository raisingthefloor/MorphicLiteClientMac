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
import MorphicService
import MorphicSettings

/// The View Controller for a MorphicBar showing a collection of actions the user can take
public class MorphicBarViewController: NSViewController {
    
    @IBOutlet weak var captureMenuItem: NSMenuItem!
    @IBOutlet weak var loginMenuItem: NSMenuItem!
    @IBOutlet weak var logoutMenuItem: NSMenuItem!
    @IBOutlet weak var selectCommunityMenuItem: NSMenuItem!
    @IBOutlet weak var automaticallyStartMorphicAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var showMorphicBarAtStartMenuItem: NSMenuItem!
    
    // MARK: - View Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        updateConstraints()
        morphicBarView.orientation = self.orientation
        view.layer?.backgroundColor = self.getThemeBackgroundColor()?.cgColor
        view.layer?.cornerRadius = 6
        #if EDITION_BASIC
        #elseif EDITION_COMMUNITY
            self.loginMenuItem?.isHidden = (Session.shared.user != nil)
        #endif
        self.logoutMenuItem?.isHidden = (Session.shared.user == nil)
        updateMainMenu()
        NotificationCenter.default.addObserver(self, selector: #selector(MorphicBarViewController.sessionUserDidChange(_:)), name: .morphicSessionUserDidChange, object: Session.shared)
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(MorphicBarViewController.appleInterfaceThemeDidChange(_:)), name: .appleInterfaceThemeChanged, object: nil)

        logoButton.setAccessibilityLabel(logoButton.helpTitle)
    }
    
    // MARK: - Notifications
    
    @objc
    func appleInterfaceThemeDidChange(_ notification: NSNotification) {
        self.view.layer?.backgroundColor = self.getThemeBackgroundColor()?.cgColor
    }
    
    private func getThemeBackgroundColor() -> NSColor? {
        let appleInterfaceStyle = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        let isDark = (appleInterfaceStyle?.lowercased() == "dark")
        let backgroundColorName = isDark ? "MorphicBarDarkBackgroundColor" : "MorphicBarLightBackgroundColor"
        return NSColor(named: backgroundColorName)
    }
    
    @objc
    func sessionUserDidChange(_ notification: NSNotification) {
        guard let session = notification.object as? Session else {
            return
        }
        #if EDITION_BASIC
        #elseif EDITION_COMMUNITY
            self.loginMenuItem?.isHidden = (session.user != nil)
        #endif
        self.logoutMenuItem?.isHidden = (session.user == nil)
    }
    
    // MARK: - Logo Button & Main Menu
    
    /// The MorphicBar's main menu, accessible via the Logo image button
    @IBOutlet var mainMenu: NSMenu!
    
    /// The button that displays the Morphic logo
    @IBOutlet weak var logoButton: LogoButton!
    
    /// Action to show the main menu from the logo button
    @IBAction
    func showMainMenu(_ sender: Any?) {
        mainMenu.popUp(positioning: nil, at: NSPoint(x: logoButton.bounds.origin.x, y: logoButton.bounds.origin.y + logoButton.bounds.size.height), in: logoButton)
    }
    
    private func updateMainMenu() {
        #if EDITION_BASIC
            // NOTE: the default menu items are already configured for Morphic Basic
        #elseif EDITION_COMMUNITY
            // configure menu items to match the Morphic Community scheme
            captureMenuItem?.isHidden = true
            loginMenuItem?.title = "Sign In..."
            logoutMenuItem?.title = "Sign Out"
        #endif
    }

    // MARK: - Orientation and orientation-related constraints
    
    public var orientation: MorphicBarOrientation = .horizontal {
        didSet {
            updateConstraints()
            morphicBarView?.orientation = self.orientation
        }
    }

    private func updateConstraints() {
        switch orientation {
        case .horizontal:
            // deactivate the vertical constraints
            logoButtonToMorphicBarViewVerticalTopConstraint?.isActive = false
            logoButtonToViewVerticalCenterXConstraint?.isActive = false
            viewToMorphicBarViewVerticalTrailingConstraint?.isActive = false
            viewToLogoButtonVerticalBottomConstraint?.isActive = false

            // deactivate any old copies of our horizontal constraints
            logoButtonToMorphicBarViewHorizontalLeadingConstraint?.isActive = false
            logoButtonToViewHorizontalTopConstraint?.isActive = false
            viewToLogoButtonHorizontalTrailingConstraint?.isActive = false
            viewToMorphicBarViewHorizontalBottomConstraint?.isActive = false

            logoButtonToMorphicBarViewHorizontalLeadingConstraint = NSLayoutConstraint(item: logoButton!, attribute: .leading, relatedBy: .equal, toItem: morphicBarView!, attribute: .trailing, multiplier: 1, constant: 18)
            logoButtonToViewHorizontalTopConstraint = NSLayoutConstraint(item: logoButton!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 7)
            viewToLogoButtonHorizontalTrailingConstraint = NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: logoButton!, attribute: .trailing, multiplier: 1, constant: 7)
            viewToMorphicBarViewHorizontalBottomConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: morphicBarView!, attribute: .bottom, multiplier: 1, constant: 7)

            self.view.addConstraints([
                logoButtonToMorphicBarViewHorizontalLeadingConstraint!,
                logoButtonToViewHorizontalTopConstraint!,
                viewToLogoButtonHorizontalTrailingConstraint!,
                viewToMorphicBarViewHorizontalBottomConstraint!
            ])
        case .vertical:
            // deactivate the horizontal constraints
            logoButtonToMorphicBarViewHorizontalLeadingConstraint?.isActive = false
            logoButtonToViewHorizontalTopConstraint?.isActive = false
            viewToLogoButtonHorizontalTrailingConstraint?.isActive = false
            viewToMorphicBarViewHorizontalBottomConstraint?.isActive = false

            // deactivate any old copies of our vertical constraints
            logoButtonToMorphicBarViewVerticalTopConstraint?.isActive = false
            logoButtonToViewVerticalCenterXConstraint?.isActive = false
            viewToMorphicBarViewVerticalTrailingConstraint?.isActive = false
            viewToLogoButtonVerticalBottomConstraint?.isActive = false
            
            logoButtonToMorphicBarViewVerticalTopConstraint = NSLayoutConstraint(item: logoButton!, attribute: .top, relatedBy: .equal, toItem: morphicBarView!, attribute: .bottom, multiplier: 1, constant: 18)
            logoButtonToViewVerticalCenterXConstraint = NSLayoutConstraint(item: logoButton!, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
            viewToMorphicBarViewVerticalTrailingConstraint = NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: morphicBarView!, attribute: .trailing, multiplier: 1, constant: 7)
            viewToLogoButtonVerticalBottomConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: logoButton!, attribute: .bottom, multiplier: 1, constant: 7)

            self.view.addConstraints([
                logoButtonToMorphicBarViewVerticalTopConstraint!,
                logoButtonToViewVerticalCenterXConstraint!,
                viewToMorphicBarViewVerticalTrailingConstraint!,
                viewToLogoButtonVerticalBottomConstraint!
            ])
        }
    }
    
    // MARK: - Items
    
    /// The MorphicBar view managed by this controller
    @IBOutlet weak var morphicBarView: MorphicBarView!
    
    /// View constraints
    var logoButtonToMorphicBarViewHorizontalLeadingConstraint: NSLayoutConstraint?
    var logoButtonToMorphicBarViewVerticalTopConstraint : NSLayoutConstraint?
    var logoButtonToViewHorizontalTopConstraint : NSLayoutConstraint?
    var logoButtonToViewVerticalCenterXConstraint: NSLayoutConstraint?
    var viewToLogoButtonHorizontalTrailingConstraint : NSLayoutConstraint?
    var viewToLogoButtonVerticalBottomConstraint: NSLayoutConstraint?
    var viewToMorphicBarViewHorizontalBottomConstraint: NSLayoutConstraint?
    var viewToMorphicBarViewVerticalTrailingConstraint: NSLayoutConstraint?

    /// The items that should be shown on the MorphicBar
    public var items = [MorphicBarItem]() {
        didSet {
            _ = view
            morphicBarView.removeAllItemViews()
            for item in items {
                if let itemView = item.view() {
                    itemView.showsHelp = showsHelp
                    morphicBarView.add(itemView: itemView)
                }
            }
        }
    }
    
    var showsHelp: Bool = true {
        didSet {
            logoButton.showsHelp = showsHelp
            for itemView in morphicBarView.itemViews {
                itemView.showsHelp = showsHelp
            }
        }
    }

    // NOTE: we are mirroring the NSView's accessibilityChildren function here to combine and proxy the list to our owner
    public func accessibilityChildren() -> [Any]? {
        var result = [Any]()
        for itemView in morphicBarView.itemViews {
            if let children = itemView.accessibilityChildren() {
                for child in children {
                    result.append(child)
                }
            }
        }
        if let logoButton = self.logoButton {
            result.append(logoButton)
        }
        return result
    }

}

class LogoButton: NSButton {
    
    private var boundsTrackingArea: NSTrackingArea!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createBoundsTrackingArea()
    }
    
    var showsHelp: Bool = true {
        didSet {
            createBoundsTrackingArea()
        }
    }
    
    @IBInspectable var helpTitle: String?
    @IBInspectable var helpMessage: String?
    
    override func becomeFirstResponder() -> Bool {
        updateHelpWindow()
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        QuickHelpWindow.hide()
        return super.resignFirstResponder()
    }

    override func mouseEntered(with event: NSEvent) {
        updateHelpWindow()
    }
    
    override func mouseExited(with event: NSEvent) {
        QuickHelpWindow.hide()
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        createBoundsTrackingArea()
    }
    
    private func createBoundsTrackingArea() {
        if boundsTrackingArea != nil {
            removeTrackingArea(boundsTrackingArea)
        }
        if showsHelp {
            boundsTrackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
            addTrackingArea(boundsTrackingArea)
        }
    }
    
    func updateHelpWindow() {
        guard let title = helpTitle, let message = helpMessage else {
            return
        }
        if showsHelp == true {
            let viewController = QuickHelpViewController(nibName: "QuickHelpViewController", bundle: nil)
            viewController.titleText = title
            viewController.messageText = message
            QuickHelpWindow.show(viewController: viewController)
        }
    }
    
}
