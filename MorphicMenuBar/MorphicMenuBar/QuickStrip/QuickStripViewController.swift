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

class QuickStripViewController: NSViewController {
    
    @IBOutlet var mainMenu: NSMenu!
    
    @IBAction
    func showMainMenu(_ sender: Any?){
        guard let button = sender as? NSButton else{
            return
        }
        mainMenu.popUp(positioning: nil, at: NSPoint(x: button.bounds.origin.x, y: button.bounds.origin.y + button.bounds.size.height), in: button)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = .white
        view.layer?.cornerRadius = 6
//        populteDisplayModeButton()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction
    func openConfigurator(_ sender: Any?){
        AppDelegate.shared.launchConfigurator(nil)
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
        let zoomRawValue = Session.shared.string(for: "zoom", in: "com.apple.macos.display") ?? "normal"
        let currentLevel = Display.ZoomLevel(rawValue: zoomRawValue)
        var i = 0
        for level in zoomLevels{
            displayModeButton.addItem(withTitle: level.label)
            if level == currentLevel{
                displayModeButton.selectItem(at: i)
            }
            i += 1
        }
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
