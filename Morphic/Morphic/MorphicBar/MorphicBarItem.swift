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

public class MorphicBarItem{
    
    var interoperable: [String: Interoperable?]
    
    public init(interoperable: [String: Interoperable?]){
        self.interoperable = interoperable
    }
    
    func view() -> MorphicBarItemView?{
        return nil
    }
    
    public static func items(from interoperables: [Interoperable?]) -> [MorphicBarItem]{
        var items = [MorphicBarItem]()
        for i in 0..<interoperables.count{
            if let dict = interoperables.dictionary(at: i){
                if let item_ = item(from: dict){
                    items.append(item_)
                }
            }
        }
        return items
    }
    
    public static func item(from interoperable: [String: Interoperable?]) -> MorphicBarItem?{
        switch interoperable.string(for: "type"){
        case "control":
            return MorphicBarControlItem(interoperable: interoperable)
        default:
            return nil
        }
    }
    
}

class MorphicBarControlItem: MorphicBarItem{
    
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
    
    override func view() -> MorphicBarItemView? {
        switch feature{
        case .resolution:
            let localized = LocalizedStrings(prefix: "control.feature.resolution")
            let segments = [
                MorphicBarSegmentedButton.Segment(icon: .plus(), isPrimary: true, helpProvider: QuickHelpTextSizeBiggerProvider(display: Display.main, localized: localized)),
                MorphicBarSegmentedButton.Segment(icon: .minus(), isPrimary: false, helpProvider: QuickHelpTextSizeSmallerProvider(display: Display.main, localized: localized))
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.zoom(_:))
            return view
        case .magnifier:
            let localized = LocalizedStrings(prefix: "control.feature.magnifier")
            let showHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "show.help.title"), message: localized.string(for: "show.help.message")) }
            let hideHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "hide.help.title"), message: localized.string(for: "hide.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "show"), isPrimary: true, helpProvider: showHelpProvider),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "hide"), isPrimary: false, helpProvider: hideHelpProvider)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.magnifier(_:))
            return view
        case .reader:
            let localized = LocalizedStrings(prefix: "control.feature.reader")
            let onHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "on"), isPrimary: true, helpProvider: onHelpProvider),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "off"), isPrimary: false, helpProvider: offHelpProvider)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.reader(_:))
            return view
        case .volume:
            let localized = LocalizedStrings(prefix: "control.feature.volume")
            let segments = [
                MorphicBarSegmentedButton.Segment(icon: .plus(), isPrimary: true, helpProvider: QuickHelpVolumeUpProvider(audioOutput: AudioOutput.main, localized: localized)),
                MorphicBarSegmentedButton.Segment(icon: .minus(), isPrimary: false, helpProvider: QuickHelpVolumeDownProvider(audioOutput: AudioOutput.main, localized: localized)),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "mute"), isPrimary: true, helpProvider: QuickHelpVolumeMuteProvider(audioOutput: AudioOutput.main, localized: localized))
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.volume(_:))
            return view
        case .contrast:
            let localized = LocalizedStrings(prefix: "control.feature.contrast")
            let onHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "on"), isPrimary: true, helpProvider: onHelpProvider),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "off"), isPrimary: false, helpProvider: offHelpProvider)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.contrast(_:))
            return view
        default:
            return nil
        }
    }
    
    @objc
    func zoom(_ sender: Any?){
        guard let segment = (sender as? MorphicBarSegmentedButton)?.integerValue else{
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
        _ = display.zoom(to: percentage)
    }
    
    @objc
    func volume(_ sender: Any?){
        guard let segment = (sender as? MorphicBarSegmentedButton)?.integerValue else{
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
        guard let segment = (sender as? MorphicBarSegmentedButton)?.integerValue else{
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
    
    @objc
    func reader(_ sender: Any?){
        guard let segment = (sender as? MorphicBarSegmentedButton)?.integerValue else{
            return
        }
        if segment == 0{
            Session.shared.apply(true, for: .macosVoiceOverEnabled){
                _ in
            }
        }else{
            Session.shared.apply(false, for: .macosVoiceOverEnabled){
                _ in
            }
        }
    }
    
    @objc
    func magnifier(_ sender: Any?){
        guard let segment = (sender as? MorphicBarSegmentedButton)?.integerValue else{
            return
        }
        let session = Session.shared
        if segment == 0{
            let keyValuesToSet: [(Preferences.Key, Interoperable?)] = [
                (.macosZoomStyle, 1)
            ]
            let preferences = Preferences(identifier: "__magnifier__")
            let capture = CaptureSession(settingsManager: session.settings, preferences: preferences)
            capture.keys = keyValuesToSet.map{ $0.0 }
            capture.captureDefaultValues = true
            capture.run {
                session.storage.save(record: capture.preferences){
                    _ in
                    let apply = ApplySession(settingsManager: session.settings, keyValueTuples: keyValuesToSet)
                    apply.add(key: .macosZoomEnabled, value: true)
                    apply.run {
                    }
                }
            }
        }else{
            session.storage.load(identifier: "__magnifier__"){
                (preferences: Preferences?) in
                if let preferences = preferences{
                    let apply = ApplySession(settingsManager: session.settings, preferences: preferences)
                    apply.addFirst(key: .macosZoomEnabled, value: false)
                    apply.run {
                    }
                }else{
                    session.apply(false, for: .macosZoomEnabled){
                        _ in
                    }
                }
            }
        }
    }
    
}

fileprivate struct LocalizedStrings{
    
    var prefix: String
    var table = "MorphicBarViewController"
    var bundle = Bundle.main
    
    init(prefix: String){
        self.prefix = prefix
    }
    
    func string(for suffix: String) -> String{
        return bundle.localizedString(forKey: prefix + "." + suffix, value: nil, table: table)
    }
}

fileprivate class QuickHelpDynamicTextProvider: QuickHelpContentProvider{
    
    var textProvider: () -> (String, String)?
    
    init(textProvider: @escaping () -> (String, String)?){
        self.textProvider = textProvider
    }
    
    func quickHelpViewController() -> NSViewController? {
        guard let strings = textProvider() else{
            return nil
        }
        let viewController = QuickHelpViewController(nibName: "QuickHelpViewController", bundle: nil)
        viewController.titleText = strings.0
        viewController.messageText = strings.1
        return viewController
    }
}

fileprivate class QuickHelpTextSizeBiggerProvider: QuickHelpContentProvider{
    
    init(display: Display?, localized: LocalizedStrings){
        self.display = display
        self.localized = localized
    }
    
    var display: Display?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let viewController = QuickHelpStepViewController(nibName: "QuickHelpStepViewController", bundle: nil)
        let total = display?.numberOfSteps ?? 1
        var step = display?.currentStep ?? -1
        if step >= 0{
            step = total - 1 - step
        }
        viewController.numberOfSteps = total
        viewController.step = step
        if step == total - 1{
            viewController.titleText = localized.string(for: "bigger.limit.help.title")
            viewController.messageText = localized.string(for: "bigger.limit.help.message")
        }else{
            viewController.titleText = localized.string(for: "bigger.help.title")
            viewController.messageText = localized.string(for: "bigger.help.message")
        }
        return viewController
    }
}

fileprivate class QuickHelpTextSizeSmallerProvider: QuickHelpContentProvider{
    
    init(display: Display?, localized: LocalizedStrings){
        self.display = display
        self.localized = localized
    }
    
    var display: Display?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let viewController = QuickHelpStepViewController(nibName: "QuickHelpStepViewController", bundle: nil)
        let total = display?.numberOfSteps ?? 1
        var step = display?.currentStep ?? -1
        if step >= 0{
            step = total - 1 - step
        }
        viewController.numberOfSteps = total
        viewController.step = step
        if step == 0{
            viewController.titleText = localized.string(for: "smaller.limit.help.title")
            viewController.messageText = localized.string(for: "smaller.limit.help.message")
        }else{
            viewController.titleText = localized.string(for: "smaller.help.title")
            viewController.messageText = localized.string(for: "smaller.help.message")
        }
        return viewController
    }
}

fileprivate class QuickHelpVolumeUpProvider: QuickHelpContentProvider{
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings){
        output = audioOutput
        self.localized = localized
    }
    
    var output: AudioOutput?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let level = output?.volume ?? 0.0
        let muted = output?.isMuted ?? false
        let viewController = QuickHelpVolumeViewController(nibName: "QuickHelpVolumeViewController", bundle: nil)
        viewController.volumeLevel = level
        viewController.muted = muted
        if muted{
            viewController.titleText = localized.string(for: "up.muted.help.title")
            viewController.messageText = localized.string(for: "up.muted.help.message")
        }else{
            if level >= 0.99{
                viewController.titleText = localized.string(for: "up.limit.help.title")
                viewController.messageText = localized.string(for: "up.limit.help.message")
            }else{
                viewController.titleText = localized.string(for: "up.help.title")
                viewController.messageText = localized.string(for: "up.help.message")
            }
        }
        return viewController
    }
    
}

fileprivate class QuickHelpVolumeDownProvider: QuickHelpContentProvider{
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings){
        output = audioOutput
        self.localized = localized
    }
    
    var output: AudioOutput?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let level = output?.volume ?? 0.0
        let muted = output?.isMuted ?? false
        let viewController = QuickHelpVolumeViewController(nibName: "QuickHelpVolumeViewController", bundle: nil)
        viewController.volumeLevel = level
        viewController.muted = muted
        if muted{
            viewController.titleText = localized.string(for: "down.muted.help.title")
            viewController.messageText = localized.string(for: "down.muted.help.message")
        }else{
            if level <= 0.01{
                viewController.titleText = localized.string(for: "down.limit.help.title")
                viewController.messageText = localized.string(for: "down.limit.help.message")
            }else{
                viewController.titleText = localized.string(for: "down.help.title")
                viewController.messageText = localized.string(for: "down.help.message")
            }
        }
        return viewController
    }
    
}

fileprivate class QuickHelpVolumeMuteProvider: QuickHelpContentProvider{
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings){
        output = audioOutput
        self.localized = localized
    }
    
    var output: AudioOutput?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let level = output?.volume ?? 0.0
        let muted = output?.isMuted ?? false
        let viewController = QuickHelpVolumeViewController(nibName: "QuickHelpVolumeViewController", bundle: nil)
        viewController.volumeLevel = level
        viewController.muted = muted
        if muted{
            viewController.titleText = localized.string(for: "muted.help.title")
            viewController.messageText = localized.string(for: "muted.help.message")
        }else{
            viewController.titleText = localized.string(for: "mute.help.title")
            viewController.messageText = localized.string(for: "mute.help.message")
        }
        return viewController
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
