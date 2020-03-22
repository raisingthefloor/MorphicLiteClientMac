//
//  Display.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 3/22/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public class Display{
    
    public enum ZoomLevel: String{
        case normal
        case percent125
        case percent150
        case percent200
    }
    
    init(id: UInt32){
        self.id = id
    }
    
    private var id: UInt32
    
    static var main: Display? = {
        if let id = MorphicDisplay.getMainDisplayId(){
            return Display(id: id)
        }
        return nil
    }()
    
    public func zoom(level: ZoomLevel) -> Bool{
        guard let mode = self.mode(for: level) else{
            return false
        }
        do{
            try MorphicDisplay.setCurrentDisplayMode(for: id, to: mode)
            return true
        }catch{
            return false
        }
    }
    
    public func mode(for zoomLevel: ZoomLevel) -> MorphicDisplay.DisplayMode?{
        guard let modes = MorphicDisplay.getAllDisplayModes(for: id) else{
            return nil
        }
        guard let currentMode = MorphicDisplay.getCurrentDisplayMode(for: id) else{
            return nil
        }
        let possibleModes = modes.filter({ $0.isUsableForDesktopGui && $0.aspectRatio == currentMode.aspectRatio && $0.integerRefresh == currentMode.integerRefresh && $0.scale == currentMode.scale }).sorted(by: <)
        // TODO: figure out which mode matches the zoom level
        return currentMode
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

