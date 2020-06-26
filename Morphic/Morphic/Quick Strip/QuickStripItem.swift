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
import MorphicCore
import MorphicSettings
import MorphicService

public class QuickStripItem{
    
    var interoperable: [String: Interoperable?]
    
    public init(interoperable: [String: Interoperable?]){
        self.interoperable = interoperable
    }
    
    func view() -> QuickStripItemView?{
        return nil
    }
    
    public static func items(from interoperables: [Interoperable?]) -> [QuickStripItem]{
        var items = [QuickStripItem]()
        for i in 0..<interoperables.count{
            if let dict = interoperables.dictionary(at: i){
                if let item_ = item(from: dict){
                    items.append(item_)
                }
            }
        }
        return items
    }
    
    public static func item(from interoperable: [String: Interoperable?]) -> QuickStripItem?{
        switch interoperable.string(for: "type"){
        case "control":
            return QuickStripControlItem(interoperable: interoperable)
        default:
            return nil
        }
    }
    
}

class QuickStripControlItem: QuickStripItem{
    
    enum Feature: String{
        case resolution
        case magnifier
        case reader
        case volume
        case contrast
        case unknown
        
        init(string: String?){
            if let known = Feature(rawValue: string ?? ""){
                self = known
            }else{
                self = .unknown
            }
        }
    }
    
    var feature: Feature
    
    override init(interoperable: [String : Interoperable?]) {
        feature = Feature(string: interoperable.string(for: "feature"))
        super.init(interoperable: interoperable)
    }
    
    struct LocalizedStrings{
        
        var prefix: String
        var table = "QuickStripViewController"
        var bundle = Bundle.main
        
        init(prefix: String){
            self.prefix = prefix
        }
        
        func string(for suffix: String) -> String{
            return bundle.localizedString(forKey: prefix + "." + suffix, value: nil, table: table)
        }
    }
    
    override func view() -> QuickStripItemView? {
        switch feature{
        case .resolution:
            let localized = LocalizedStrings(prefix: "control.feature.resolution")
            let segments = [
                QuickStripSegmentedButton.Segment(icon: .plus(), helpTitle: localized.string(for: "bigger.help.title"), helpMessage: localized.string(for: "bigger.help.message"), isPrimary: true),
                QuickStripSegmentedButton.Segment(icon: .minus(), helpTitle: localized.string(for: "smaller.help.title"), helpMessage: localized.string(for: "smaller.help.message"), isPrimary: false)
            ]
            let view = QuickStripSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(QuickStripControlItem.zoom(_:))
            return view
        case .magnifier:
            let localized = LocalizedStrings(prefix: "control.feature.magnifier")
            let segments = [
                QuickStripSegmentedButton.Segment(title: localized.string(for: "show"), helpTitle: localized.string(for: "show.help.title"), helpMessage: localized.string(for: "show.help.message"), isPrimary: true),
                QuickStripSegmentedButton.Segment(title: localized.string(for: "hide"), helpTitle: localized.string(for: "hide.help.title"), helpMessage: localized.string(for: "hide.help.message"), isPrimary: false)
            ]
            let view = QuickStripSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            return view
        case .reader:
            let localized = LocalizedStrings(prefix: "control.feature.reader")
            let segments = [
                QuickStripSegmentedButton.Segment(title: localized.string(for: "on"), helpTitle: localized.string(for: "on.help.title"), helpMessage: localized.string(for: "on.help.message"),  isPrimary: true),
                QuickStripSegmentedButton.Segment(title: localized.string(for: "off"), helpTitle: localized.string(for: "off.help.title"), helpMessage: localized.string(for: "off.help.message"),  isPrimary: false)
            ]
            let view = QuickStripSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            return view
        case .volume:
            let localized = LocalizedStrings(prefix: "control.feature.volume")
            let segments = [
                QuickStripSegmentedButton.Segment(icon: .plus(), helpTitle: localized.string(for: "up.help.title"), helpMessage: localized.string(for: "up.help.message"), isPrimary: true),
                QuickStripSegmentedButton.Segment(icon: .minus(), helpTitle: localized.string(for: "down.help.title"), helpMessage: localized.string(for: "down.help.message"), isPrimary: false),
                QuickStripSegmentedButton.Segment(title: localized.string(for: "mute"), helpTitle: localized.string(for: "mute.help.title"), helpMessage: localized.string(for: "mute.help.message"), isPrimary: true)
            ]
            let view = QuickStripSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(QuickStripControlItem.volume(_:))
            return view
        case .contrast:
            let localized = LocalizedStrings(prefix: "control.feature.contrast")
            let segments = [
                QuickStripSegmentedButton.Segment(title: localized.string(for: "on"), helpTitle: localized.string(for: "on.help.title"), helpMessage: localized.string(for: "on.help.message"), isPrimary: true),
                QuickStripSegmentedButton.Segment(title: localized.string(for: "off"), helpTitle: localized.string(for: "off.help.title"), helpMessage: localized.string(for: "off.help.message"), isPrimary: false)
            ]
            let view = QuickStripSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(QuickStripControlItem.contrast(_:))
            return view
        default:
            return nil
        }
    }
    
    @objc
    func zoom(_ sender: Any?){
        guard let segment = (sender as? QuickStripSegmentedButton)?.integerValue else{
            return
        }
        guard let display = Display.main else{
            return
        }
        var percentage: Double
        if segment == 0{
            percentage = display.percentage(zoomingIn: 1)
        }else{
            percentage = display.percentage(zoomingOut: 1)
        }
        Session.shared.set(percentage, for: .macosDisplayZoom)
    }
    
    @objc
    func volume(_ sender: Any?){
        guard let segment = (sender as? QuickStripSegmentedButton)?.integerValue else{
            return
        }
        guard let output = AudioOutput.main else{
            return
        }
        if segment == 0{
            if output.isMuted{
                _ = output.setMuted(false)
            }else{
                _ = output.setVolume(output.volume + 0.1)
            }
        }else if segment == 1{
            if output.isMuted{
                _ = output.setMuted(false)
            }else{
                _ = output.setVolume(output.volume - 0.1)
            }
        }else if segment == 2{
            _ = output.setMuted(true)
        }
    }
    
    @objc
    func contrast(_ sender: Any?){
        guard let segment = (sender as? QuickStripSegmentedButton)?.integerValue else{
            return
        }
        if segment == 0{
            Session.shared.apply(true, for: .macosDisplayContrastEnabled){
                _ in
            }
        }else{
            Session.shared.apply(false, for: .macosDisplayContrastEnabled){
                _ in
            }
        }
    }
    
}

private extension NSImage{
    
    static func plus() -> NSImage{
        return NSImage(named: "SegmentIconPlus")!
    }
    
    static func minus() -> NSImage{
        return NSImage(named: "SegmentIconMinus")!
    }
    
}
