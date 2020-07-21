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
    
    // MARK: - View Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = .white
        view.layer?.cornerRadius = 6
        self.logoutMenuItem?.isHidden = Session.shared.user == nil
        NotificationCenter.default.addObserver(self, selector: #selector(MorphicBarViewController.sessionUserDidChange(_:)), name: .morphicSessionUserDidChange, object: Session.shared)
    }
    
    // MARK: - Notifications
    
    @objc
    func sessionUserDidChange(_ notification: NSNotification){
        guard let session = notification.object as? Session else{
            return
        }
        self.logoutMenuItem?.isHidden = session.user == nil
    }
    
    // MARK: - Logo Button & Main Menu
    
    /// The MorphicBar's main menu, accessible via the Logo image button
    @IBOutlet var mainMenu: NSMenu!
    
    @IBOutlet var logoutMenuItem: NSMenuItem!
    
    /// The button that displays the Morphic logo
    @IBOutlet weak var logoButton: LogoButton!
    
    /// Action to show the main menu from the logo button
    @IBAction
    func showMainMenu(_ sender: Any?){
        mainMenu.popUp(positioning: nil, at: NSPoint(x: logoButton.bounds.origin.x, y: logoButton.bounds.origin.y + logoButton.bounds.size.height), in: logoButton)
    }
    
    // MARK: - Items
    
    /// The MorphicBar view managed by this controller
    @IBOutlet weak var morphicBarView: MorphicBarView!
    
    /// The items that should be shown on the MorphicBar
    public var items = [MorphicBarItem](){
        didSet{
            _ = view
            morphicBarView.removeAllItemViews()
            for item in items{
                if let itemView = item.view(){
                    itemView.showsHelp = showsHelp
                    morphicBarView.add(itemView: itemView)
                }
            }
        }
    }
    
    var showsHelp: Bool = true{
        didSet{
            logoButton.showsHelp = showsHelp
            for itemView in morphicBarView.itemViews{
                itemView.showsHelp = showsHelp
            }
        }
    }

}

class LogoButton: NSButton{
    
    private var boundsTrackingArea: NSTrackingArea!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createBoundsTrackingArea()
    }
    
    var showsHelp: Bool = true{
        didSet{
            createBoundsTrackingArea()
        }
    }
    
    @IBInspectable var helpTitle: String?
    @IBInspectable var helpMessage: String?
    
    override func mouseEntered(with event: NSEvent) {
        guard let title = helpTitle, let message = helpMessage else{
            return
        }
        let viewController = QuickHelpViewController(nibName: "QuickHelpViewController", bundle: nil)
        viewController.titleText = title
        viewController.messageText = message
        QuickHelpWindow.show(viewController: viewController)
    }
    
    override func mouseExited(with event: NSEvent) {
        QuickHelpWindow.hide()
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        createBoundsTrackingArea()
    }
    
    private func createBoundsTrackingArea(){
        if boundsTrackingArea != nil{
            removeTrackingArea(boundsTrackingArea)
        }
        if showsHelp{
            boundsTrackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
            addTrackingArea(boundsTrackingArea)
        }
    }
    
}
