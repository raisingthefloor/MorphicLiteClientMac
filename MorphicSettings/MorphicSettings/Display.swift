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

import Foundation
import MorphicCore

public class Display{
    
    init(id: UInt32){
        self.id = id
        possibleModes = findPossibleModes()
        normalMode = possibleModes.first(where: { $0.isDefault })
    }
    
    private var id: UInt32
    
    public static var main: Display? = {
        if let id = MorphicDisplay.getMainDisplayId(){
            return Display(id: id)
        }
        return nil
    }()
    
    public func zoom(to percentage: Double) -> Bool{
        guard let mode = self.mode(for: percentage) else{
            return false
        }
        do{
            try MorphicDisplay.setCurrentDisplayMode(for: id, to: mode)
            return true
        }catch{
            return false
        }
    }
    
    public func percentage(zoomingIn steps: Int) -> Double{
        guard let currentMode = currentMode, let normalMode = normalMode else{
            return 1
        }
        let target = possibleModes.reversed().first(where: { $0.widthInVirtualPixels < currentMode.widthInVirtualPixels }) ?? currentMode
        return Double(target.widthInVirtualPixels) / Double(normalMode.widthInVirtualPixels)
    }
    
    public func percentage(zoomingOut steps: Int) -> Double{
        guard let currentMode = currentMode, let normalMode = normalMode else{
            return 1
        }
        let target = possibleModes.first(where: { $0.widthInVirtualPixels > currentMode.widthInVirtualPixels }) ?? currentMode
        return Double(target.widthInVirtualPixels) / Double(normalMode.widthInVirtualPixels)
    }
    
    private var possibleModes: [MorphicDisplay.DisplayMode]!
    
    private var normalMode: MorphicDisplay.DisplayMode?
    
    private var currentMode: MorphicDisplay.DisplayMode?{
        return MorphicDisplay.getCurrentDisplayMode(for: id)
    }
    
    private func findPossibleModes() -> [MorphicDisplay.DisplayMode]{
        guard let modes = MorphicDisplay.getAllDisplayModes(for: id) else{
            return []
        }
        guard let currentMode = currentMode else{
            return []
        }
        var possibleModes = modes.filter({ $0.isUsableForDesktopGui && $0.aspectRatio == currentMode.aspectRatio && $0.integerRefresh == currentMode.integerRefresh && $0.scale == currentMode.scale }).sorted(by: <)
        for i in (1..<possibleModes.count).reversed(){
            if possibleModes[i] == possibleModes[i - 1]{
                possibleModes.remove(at: i)
            }
        }
        return possibleModes
    }
    
    private func mode(for percentage: Double) -> MorphicDisplay.DisplayMode?{
        guard let normalMode = normalMode else{
            return nil
        }
        let targetWidth = Int(round(Double(normalMode.widthInVirtualPixels) * percentage))
        let modes = possibleModes.map({ (abs($0.widthInVirtualPixels - targetWidth), $0) }).sorted(by: { $0.0 < $1.0 })
        return modes.first?.1
    }
    
}

public class DisplayZoomHandler: ClientSettingHandler{
    
    public override func apply(_ value: Interoperable?, completion: @escaping (_ success: Bool) -> Void) throws {
        guard let percentage = value as? Double else{
            completion(false)
            return
        }
        let success = Display.main?.zoom(to: percentage) ?? false
        completion(success)
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

