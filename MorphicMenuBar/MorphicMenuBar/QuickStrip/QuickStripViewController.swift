//
//  QuickStripViewController.swift
//  MorphicMenuBar
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import MorphicService
import MorphicSettings

class QuickStripViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = .white
        populteDisplayModeButton()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction
    func openConfigurator(_ sender: Any?){
        AppDelegate.shared.launchConfigurator()
        view.window?.close()
    }
    
    @IBOutlet weak var displayModeButton: NSPopUpButton!
    var zoomLevels: [Display.ZoomLevel] = [
        .normal,
        .percent125,
        .percent150,
        .percent200
    ]
    
    private func populteDisplayModeButton(){
        displayModeButton.removeAllItems()
    }

    @IBAction
    func changeDisplayMode(_ sender: Any?){
        let index = displayModeButton.indexOfSelectedItem
        guard zoomLevels.count > 0 && index >= 0 else{
            return
        }
        let level = zoomLevels[index]
        Session.shared.save(level.rawValue, for: "zoom", in: "com.apple.macos.display")
        AppDelegate.shared.toggleQuickStrip(nil)
    }

}

extension Display.ZoomLevel{
    
    var label: String{
        switch self{
        case .normal:
            return "Normal"
        case .percent125:
            return "125%"
        case .percent150:
            return "150%"
        case .percent200:
            return "200%"
        }
    }
}
