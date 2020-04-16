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
    
    override func view() -> QuickStripItemView? {
        switch feature{
        case .resolution:
            let segments = [
                QuickStripSegmentedButton.Segment(icon: .plus(), isPrimary: true),
                QuickStripSegmentedButton.Segment(icon: .minus(), isPrimary: false)
            ]
            let view = QuickStripSegmentedButtonItemView(title: Bundle.main.localizedString(forKey: "control.feature.resolution.title", value: nil, table: "QuickStrip"), segments: segments)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(QuickStripControlItem.zoom(_:))
            return view
        case .magnifier:
            let segments = [
                QuickStripSegmentedButton.Segment(title: Bundle.main.localizedString(forKey: "control.feature.magnifier.show", value: nil, table: "QuickStrip"), isPrimary: true),
                QuickStripSegmentedButton.Segment(title: Bundle.main.localizedString(forKey: "control.feature.magnifier.hide", value: nil, table: "QuickStrip"), isPrimary: false)
            ]
            let view = QuickStripSegmentedButtonItemView(title: Bundle.main.localizedString(forKey: "control.feature.magnifier.title", value: nil, table: "QuickStrip"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            return view
        case .reader:
            let segments = [
                QuickStripSegmentedButton.Segment(title: Bundle.main.localizedString(forKey: "control.feature.reader.on", value: nil, table: "QuickStrip"), isPrimary: true),
                QuickStripSegmentedButton.Segment(title: Bundle.main.localizedString(forKey: "control.feature.reader.off", value: nil, table: "QuickStrip"), isPrimary: false)
            ]
            let view = QuickStripSegmentedButtonItemView(title: Bundle.main.localizedString(forKey: "control.feature.reader.title", value: nil, table: "QuickStrip"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            return view
        case .volume:
            let segments = [
                QuickStripSegmentedButton.Segment(icon: .plus(), isPrimary: true),
                QuickStripSegmentedButton.Segment(icon: .minus(), isPrimary: false),
                QuickStripSegmentedButton.Segment(title: Bundle.main.localizedString(forKey: "control.feature.volume.mute", value: nil, table: "QuickStrip"), isPrimary: true)
            ]
            let view = QuickStripSegmentedButtonItemView(title: Bundle.main.localizedString(forKey: "control.feature.volume.title", value: nil, table: "QuickStrip"), segments: segments)
            return view
        case .contrast:
            let segments = [
                QuickStripSegmentedButton.Segment(title: Bundle.main.localizedString(forKey: "control.feature.contrast.on", value: nil, table: "QuickStrip"), isPrimary: true),
                QuickStripSegmentedButton.Segment(title: Bundle.main.localizedString(forKey: "control.feature.contrast.off", value: nil, table: "QuickStrip"), isPrimary: false)
            ]
            let view = QuickStripSegmentedButtonItemView(title: Bundle.main.localizedString(forKey: "control.feature.contrast.title", value: nil, table: "QuickStrip"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
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
        Session.shared.save(percentage, for: .macosDisplayZoom)
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
