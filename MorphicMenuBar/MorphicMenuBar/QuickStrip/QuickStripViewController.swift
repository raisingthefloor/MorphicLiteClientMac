//
//  QuickStripViewController.swift
//  MorphicMenuBar
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
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
        Morphic.shared.launchConfigurator()
        view.window?.close()
    }
    
    @IBOutlet weak var displayModeButton: NSPopUpButton!
    
    private var displayId: UInt32?
    private var displayModes = [MorphicDisplay.DisplayMode]()
    
    private func populteDisplayModeButton(){
        displayModeButton.removeAllItems()
        displayId = MorphicDisplay.getMainDisplayId()
        if let main = displayId{
            if let modes = MorphicDisplay.getAllDisplayModes(for: main){
                if let currentMode = MorphicDisplay.getCurrentDisplayMode(for: main){
                    displayModes = modes.filter({ $0.isUsableForDesktopGui && $0.aspectRatio == currentMode.aspectRatio && $0.integerRefresh == currentMode.integerRefresh && $0.scale == currentMode.scale }).sorted(by: <)
                    for i in (1..<displayModes.count).reversed(){
                        if (displayModes[i] == displayModes[i - 1]){
                            displayModes.remove(at: i)
                        }
                    }
                    for mode in displayModes{
                        let item = displayModeButton.menu?.addItem(withTitle: mode.stringRepresentation, action: nil, keyEquivalent: "")
                        item?.tag = Int(mode.ioDisplayModeId)
                    }
                    displayModeButton.selectItem(withTag: Int(currentMode.ioDisplayModeId))
                }
            }
        }
    }

    @IBAction
    func changeDisplayMode(_ sender: Any?){
        let index = displayModeButton.indexOfSelectedItem
        guard displayModes.count > 0 && index >= 0 && displayId != nil else{
            return
        }
        let mode = displayModes[index]
        do{
            try MorphicDisplay.setCurrentDisplayMode(for: displayId!, to: mode)
        }catch{
            print("Error setting display mode: \(error)")
        }
        (NSApplication.shared.delegate as? AppDelegate)?.toggleQuickStrip(nil)
    }

}

private extension MorphicDisplay.DisplayMode{
    
    var stringRepresentation: String{
        var str = "\(widthInVirtualPixels)x\(heightInVirtualPixels)"
        if widthInPixels != widthInVirtualPixels || heightInPixels != heightInPixels{
            str += " (\(widthInPixels)x\(heightInPixels))"
        }
        if let refresh = integerRefresh{
            str += " @\(refresh)Hz"
        }
        return str
    }
    
    static func <(_ a: MorphicDisplay.DisplayMode, _ b: MorphicDisplay.DisplayMode) -> Bool{
        var diff = a.widthInVirtualPixels - b.widthInVirtualPixels
        if diff == 0{
            diff = a.widthInPixels - b.widthInPixels
            if diff == 0{
                diff = Int(a.refreshRateInHertz ?? 0) - Int(b.refreshRateInHertz ?? 0)
                if diff == 0{
                    diff = Int(a.ioDisplayModeId) - Int(b.ioDisplayModeId)
                }
            }
        }
        return diff < 0
    }
    
    var integerRefresh: Int?{
        guard let refresh = refreshRateInHertz else{
            return nil
        }
        return Int(refresh)
    }
    
    struct AspectRatio{
        
        public var width: Int
        public var height: Int
        
        init(width: Int, height: Int){
            self.width = width
            self.height = height
        }
        
        public var value: Double{
            return Double(width) / Double(height)
        }
        
        static func ==(_ a: AspectRatio, _ b: AspectRatio) -> Bool{
            return abs(a.value - b.value) < 0.1
        }
    }
    
    var aspectRatio: AspectRatio{
        return AspectRatio(width: widthInVirtualPixels, height: heightInVirtualPixels)
    }
    
    var scale: Int{
        return widthInVirtualPixels / widthInPixels
    }
    
}
