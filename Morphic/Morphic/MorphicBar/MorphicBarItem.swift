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

import Carbon.HIToolbox
import Cocoa
import Countly
import MorphicCore
import MorphicSettings
import MorphicService
import OSLog

public class MorphicBarItem {
    
    var interoperable: [String: Interoperable?]
    
    public init(interoperable: [String: Interoperable?]) {
        self.interoperable = interoperable
    }
    
    func view() -> MorphicBarItemViewProtocol? {
        return nil
    }
    
    public static func items(from interoperables: [Interoperable?]) -> [MorphicBarItem] {
        var items = [MorphicBarItem]()
        for i in 0..<interoperables.count {
            if let dict = interoperables.dictionary(at: i) {
                if let item_ = item(from: dict) {
                    items.append(item_)
                }
            }
        }
        return items
    }

    internal static func items(from extraItems: [AppDelegate.MorphicBarExtraItem]) -> [MorphicBarItem] {
        var items = [MorphicBarItem]()
        for extraItem in extraItems {
            // convert our extra item into a dictionary
            var itemAsDictionary: [String: Interoperable?] = [:]
            itemAsDictionary["type"] = extraItem.type
            itemAsDictionary["label"] = extraItem.label
            itemAsDictionary["tooltipHeader"] = extraItem.tooltipHeader
            itemAsDictionary["tooltipText"] = extraItem.tooltipText
            // for type: link
            itemAsDictionary["url"] = extraItem.url
            // for type: action (from config.json file, not from custom bar web app schema)
            itemAsDictionary["function"] = extraItem.function

            if let item_ = item(from: itemAsDictionary) {
                items.append(item_)
            }
        }
        return items
    }

    public static func item(from interoperable: [String: Interoperable?]) -> MorphicBarItem? {
        switch interoperable.string(for: "type") {
        case "control":
            return MorphicBarControlItem(interoperable: interoperable)
        case "link":
            return MorphicBarLinkItem(interoperable: interoperable)
        case "application":
            let morphicBarApplicationItem = MorphicBarApplicationItem(interoperable: interoperable)
            // NOTE: we do not support "EXE" buttons on macOS, so only show items with a supported 'default' application
            if morphicBarApplicationItem.default != nil {
                return morphicBarApplicationItem
            } else {
                return nil
            }
        case "action":
            if let _ = interoperable["function"] {
                // config.json (Windows-compatible) action item
                defer {
                    Countly.sharedInstance().recordEvent("morphicBarExtraItem")
                }
                return MorphicBarActionItem(interoperable: interoperable)
            } else {
                // Morphic for macOS-style action (control) item
                return createMorphicBarActionControlItem(interoperable: interoperable)
            }
        default:
            return nil
        }
    }
    
    private static func createMorphicBarActionControlItem(interoperable: [String: Interoperable?]) -> MorphicBarItem? {
        // NOTE: argument 'label' should never be nil, but it was nil in all API call test results; as a practical matter this does not matter as we are not using the parameter in our implementation
                
        guard let identifier = interoperable["identifier"] as? String else {
            return nil
        }
                
        // map the community action items to traditional control items (by mapping their interoperable data)
        
        var transformedInteroperable: [String: Interoperable?] = [:]
        
        transformedInteroperable["color"] = interoperable["color"] as? String

        switch identifier {
        case "copy-paste":
            transformedInteroperable["feature"] = "copypaste"
        case "magnify":
            transformedInteroperable["feature"] = "magnifieronoff"
        case "screen-zoom":
            transformedInteroperable["feature"] = "resolution"
        case "volume":
            transformedInteroperable["feature"] = "volumewithoutmute"
        default:
            // no other action items are supported
            break
        }

        let morphicBarControlItem = MorphicBarControlItem(interoperable: transformedInteroperable)
        morphicBarControlItem.style = .fixedWidth(segmentWidth: 49.25)
        
        return morphicBarControlItem
    }
}

class MorphicBarSeparatorItem: MorphicBarItem {
    override func view() -> MorphicBarItemViewProtocol? {
        let view = MorphicBarSeparatorItemView()
        view.target = self
        return view
    }
}

class MorphicBarLinkItem: MorphicBarItem {
    var label: String
    var color: NSColor?
    var imageUrl: String?
    var url: URL?
     
    override init(interoperable: [String : Interoperable?]) {
        // NOTE: argument 'label' should never be nil, but we use an empty string as a backup
        label = interoperable.string(for: "label") ?? ""
        //
        if let colorAsString = interoperable.string(for: "color") {
            color = NSColor.createFromRgbHexString(colorAsString)
        } else {
            color = nil
        }
        //
        imageUrl = interoperable.string(for: "imageUrl")
        //
        // NOTE: argument 'url' should never be nil, but we use an empty string as a backup
        if let urlAsString = interoperable.string(for: "url") {
            // NOTE: if the url was malformed, that may result in a "nil" URL
            // SECURITY NOTE: we should strongly consider filtering urls by scheme (or otherwise) here
            url = URL(string: urlAsString)
        } else {
            url = nil
        }
        
        super.init(interoperable: interoperable)
    }

    override func view() -> MorphicBarItemViewProtocol? {
        var icon: MorphicBarButtonItemIcon? = nil
        if let imageUrl = self.imageUrl {
            icon = MorphicBarButtonItemIcon(rawValue: imageUrl)
        }
        
        let view = MorphicBarButtonItemView(label: label, labelColor: nil, fillColor: color, icon: icon, iconColor: nil)
        view.target = self
        view.action = #selector(MorphicBarLinkItem.openLink(_:))
        return view
    }
    
    @objc
    func openLink(_ sender: Any?) {
        if let url = self.url {
            NSWorkspace.shared.open(url)
        }
    }
}

enum MorphicBarActionItemFunction: String {
    case signOut
}
class MorphicBarActionItem: MorphicBarItem {
    var label: String
    var color: NSColor?
    var function: MorphicBarActionItemFunction?
     
    // NOTE: realistically these should be failable initializers (which can return nil)
    override init(interoperable: [String : Interoperable?]) {
        // NOTE: argument 'label' should never be nil, but we use an empty string as a backup
        label = interoperable.string(for: "label") ?? ""
        //
        if let colorAsString = interoperable.string(for: "color") {
            color = NSColor.createFromRgbHexString(colorAsString)
        } else {
            color = nil
        }
        //
        // NOTE: argument 'function' should never be nil
        if let functionAsString = interoperable.string(for: "function") {
            function = MorphicBarActionItemFunction(rawValue: functionAsString)
        } else {
            function = nil
        }
        
        super.init(interoperable: interoperable)
    }

    override func view() -> MorphicBarItemViewProtocol? {
        let view = MorphicBarButtonItemView(label: label, labelColor: nil, fillColor: color, icon: nil, iconColor: nil)
        view.target = self
        view.action = #selector(MorphicBarActionItem.callFunction(_:))
        return view
    }
    
    @objc
    func callFunction(_ sender: Any?) {
        if let function = self.function {
            switch function {
            case .signOut:
                MorphicProcess.logOutUserViaOsaScriptWithConfirmation()
            }
        }
    }
}
enum MorphicBarApplicationDefaultOption: String {
    case email
}
//
class MorphicBarApplicationItem: MorphicBarItem {
    var label: String
    var color: NSColor?
    var imageUrl: String?
    var `default`: MorphicBarApplicationDefaultOption?
    var exe: String?

    override init(interoperable: [String : Interoperable?]) {
        // NOTE: argument 'label' should never be nil, but we use an empty string as a backup
        label = interoperable.string(for: "label") ?? ""
        //
        if let colorAsString = interoperable.string(for: "color") {
            color = NSColor.createFromRgbHexString(colorAsString)
        } else {
            color = nil
        }
        //
        imageUrl = interoperable.string(for: "imageUrl")
        //
        // NOTE: either argument "default" (application type) or "exe" should always be populated, but we assign a nil application and exe as a backup
        if let `default` = interoperable.string(for: "default") {
            // NOTE: this function call will either return a known 'default' application option...or it will return nil (if the application isn't supported on macOS)
            self.default = MorphicBarApplicationDefaultOption(rawValue: `default`)
        } else {
            self.default = nil
        }
        //
        // NOTE: we do not currently support EXE on macOS, so ignore this option
//        if let exe = interoperable.string(for: "exe") {
//            self.exe = exe
//        } else {
            self.exe = nil
//        }
        
        super.init(interoperable: interoperable)
    }

    override func view() -> MorphicBarItemViewProtocol? {
        var icon: MorphicBarButtonItemIcon? = nil
        if let imageUrl = self.imageUrl {
            icon = MorphicBarButtonItemIcon(rawValue: imageUrl)
        }
        
        let view = MorphicBarButtonItemView(label: label, labelColor: nil, fillColor: color, icon: icon, iconColor: nil)
        view.target = self
        // NOTE: generally, we should give preference to opening an executable directly ("exe") over opening the default application by type ("default")
        if self.exe != nil {
            view.action = #selector(MorphicBarApplicationItem.openExe(_:))
        } else {
            view.action = #selector(MorphicBarApplicationItem.openDefault(_:))
        }
        return view
    }
    
    @objc
    func openDefault(_ sender: Any?) {
        if let `default` = self.default {
            switch `default` {
            case .email:
                NSWorkspace.shared.open(URL(string: "mailto:")!)
            }
        }
    }
    
    @objc
    func openExe(_ sender: Any?) {
        if let _ = self.exe {
            fatalError("Opening EXEs is not supported on macOS")
        }
    }
}

enum MorphicBarControlItemStyle {
    case autoWidth
    case fixedWidth(segmentWidth: CGFloat)
}
//
class MorphicBarControlItem: MorphicBarItem {
    
    enum Feature: String {
        case resolution
        case magnifier
        case magnifieronoff
        case reader
        case readselected
        case volume
        case volumewithoutmute
        case contrast
        case contrastcolordarknight
        case nightshift
        case copypaste
        case screensnip
        case unknown
        
        init(string: String?) {
            if let known = Feature(rawValue: string ?? "") {
                self = known
            } else {
                self = .unknown
            }
        }
    }

    // NOTE: these string should always be specified (in case the enum cases get renamed during refactoring) as they are used in URL paths
    enum ButtonCategory: String {
        case assistMac = "assist-mac"
        case colorvision = "colorvision"
        case contrast = "contrast"
        case copypaste = "copypaste"
        case darkmode = "darkmode"
        case logoff = "logoff"
        case magnifier = "magnifier"
        case nightmode = "nightmode"
        case readselMac = "readsel-mac"
        case snip = "snip"
        case textsize = "textsize"
        case volmute = "volmute"
    }
    
    static func learnMoreUrl(for buttonCategory: ButtonCategory) -> URL? {
        let learnMoreUrlPrefix = "https://morphic.org/rd/"
        let buttonCategoryTag = buttonCategory.rawValue
        return URL(string: learnMoreUrlPrefix + buttonCategoryTag)
    }
    
    static func quickDemoVideoUrl(for buttonCategory: ButtonCategory) -> URL? {
        let buttonCategoryUrlPrefix = "https://morphic.org/rd/"
        let buttonCategoryUrlSuffix = "-vid"
        let buttonCategoryTag = buttonCategory.rawValue
        return URL(string: buttonCategoryUrlPrefix + buttonCategoryTag + buttonCategoryUrlSuffix)
    }
    
    var feature: Feature
    var fillColor: NSColor? = nil 
    
    var style: MorphicBarControlItemStyle = .autoWidth
    
    override init(interoperable: [String : Interoperable?]) {
        feature = Feature(string: interoperable.string(for: "feature"))
        if let colorAsString = interoperable.string(for: "color") {
            fillColor = NSColor.createFromRgbHexString(colorAsString)
        } else {
            fillColor = nil
        }
        super.init(interoperable: interoperable)
    }
    
    override func view() -> MorphicBarItemViewProtocol? {
        let buttonColor: NSColor = fillColor ?? .morphicPrimaryColor
        let alternateButtonColor: NSColor = fillColor ?? .morphicPrimaryColor
        // NOTE: to alternate the color of button segments, uncomment the following line instead
        //let alternateButtonColor: NSColor = fillColor ?? .morphicPrimaryColorLightend

        switch feature {
        case .resolution:
            let localized = LocalizedStrings(prefix: "control.feature.resolution")
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "bigger"), fillColor: buttonColor, helpProvider:  QuickHelpTextSizeBiggerProvider(display: Display.main, localized: localized), accessibilityLabel: localized.string(for: "bigger.tts"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .textsize), learnMoreTelemetryCategory: "textSize", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .textsize), quickDemoVideoTelemetryCategory: "textSize", settingsBlock: nil, style: .fixedWidth(segmentWidth: 31)),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "smaller"), fillColor: alternateButtonColor, helpProvider: QuickHelpTextSizeSmallerProvider(display: Display.main, localized: localized), accessibilityLabel: localized.string(for: "smaller.tts"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .textsize), learnMoreTelemetryCategory: "textSize", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .textsize), quickDemoVideoTelemetryCategory: "textSize", settingsBlock: nil, style: .fixedWidth(segmentWidth: 31))
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.zoom(_:))
            return view
        case .magnifier,
             .magnifieronoff:
            // NOTE: magnifieronoff is identical to magnifier but shows "on/off" buttons instead of "show/hide" buttons
            let isOnOff = (feature == .magnifieronoff)
            //
            let localized = LocalizedStrings(prefix: "control.feature.magnifier")
            let showHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: isOnOff ? "on.help.title" : "show.help.title"), message: localized.string(for: isOnOff ? "on.help.message" : "show.help.message")) }
            let hideHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: isOnOff ? "off.help.title" : "hide.help.title"), message: localized.string(for: isOnOff ? "off.help.message" : "hide.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: isOnOff ? "on" : "show"), fillColor: buttonColor, helpProvider: showHelpProvider, accessibilityLabel: localized.string(for: isOnOff ? "on.help.title" : "show.tts"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .magnifier), learnMoreTelemetryCategory: "magnifier", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .magnifier), quickDemoVideoTelemetryCategory: "magnifier", settingsBlock: { SettingsLinkActions.openSystemPreferencesPaneWithTelemetry(.accessibilityZoom, category: "magnifier") }, style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: isOnOff ? "off" : "hide"), fillColor: alternateButtonColor, helpProvider: hideHelpProvider, accessibilityLabel: localized.string(for: isOnOff ? "off.help.title" : "hide.tts"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .magnifier), learnMoreTelemetryCategory: "magnifier", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .magnifier), quickDemoVideoTelemetryCategory: "magnifier", settingsBlock: { SettingsLinkActions.openSystemPreferencesPaneWithTelemetry(.accessibilityZoom, category: "magnifier") }, style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.magnifier(_:))
            return view
        case .reader:
            let localized = LocalizedStrings(prefix: "control.feature.reader")
            let onHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "on"), fillColor: buttonColor, helpProvider: onHelpProvider, accessibilityLabel: localized.string(for: "on.tts"), learnMoreUrl: nil, learnMoreTelemetryCategory: nil, quickDemoVideoUrl: nil, quickDemoVideoTelemetryCategory: nil, settingsBlock: nil, style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "off"), fillColor: alternateButtonColor, helpProvider: offHelpProvider, accessibilityLabel: localized.string(for: "off.tts"), learnMoreUrl: nil, learnMoreTelemetryCategory: nil, quickDemoVideoUrl: nil, quickDemoVideoTelemetryCategory: nil, settingsBlock: nil, style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.reader(_:))
            return view
        case .readselected:
            let localized = LocalizedStrings(prefix: "control.feature.readselected")
            let playStopHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "playstop.help.title"), message: localized.string(for: "playstop.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "playstop"), fillColor: buttonColor, helpProvider: playStopHelpProvider, accessibilityLabel: localized.string(for: "playstop.tts"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .readselMac), learnMoreTelemetryCategory: "readAloud", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .readselMac), quickDemoVideoTelemetryCategory: "readAloud", settingsBlock: { SettingsLinkActions.openSystemPreferencesPaneWithTelemetry(.accessibilitySpeech, category: "readAloud") }, style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.readselected)
            return view
        case .volume,
             .volumewithoutmute:
            let localized = LocalizedStrings(prefix: "control.feature.volume")
            var segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "up"), fillColor: buttonColor, helpProvider: QuickHelpVolumeUpProvider(audioOutput: AudioOutput.main, localized: localized), accessibilityLabel: localized.string(for: "up.help.title"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .volmute), learnMoreTelemetryCategory: "volume", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .volmute), quickDemoVideoTelemetryCategory: "volume", settingsBlock: nil, style: .fixedWidth(segmentWidth: 31)),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "down"), fillColor: alternateButtonColor, helpProvider: QuickHelpVolumeDownProvider(audioOutput: AudioOutput.main, localized: localized), accessibilityLabel: localized.string(for: "down.help.title"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .volmute), learnMoreTelemetryCategory: "volume", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .volmute), quickDemoVideoTelemetryCategory: "volume", settingsBlock: nil, style: .fixedWidth(segmentWidth: 31))
            ]
            if feature == .volume {
                // create and add mute segment
                var muteSegment = MorphicBarSegmentedButton.Segment(title: localized.string(for: "mute"), fillColor: buttonColor, helpProvider: QuickHelpVolumeMuteProvider(audioOutput: AudioOutput.main, localized: localized), accessibilityLabel: localized.string(for: "mute.help.title"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .volmute), learnMoreTelemetryCategory: "volume", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .volmute), quickDemoVideoTelemetryCategory: "volume", settingsBlock: nil, style: style)
                muteSegment.getStateBlock = {
                    guard let defaultAudioDeviceId = MorphicAudio.getDefaultAudioDeviceId() else {
                        // default: return false
                        return false
                    }
                    guard let muteState = MorphicAudio.getMuteState(for: defaultAudioDeviceId) else {
                        // default: return false
                        return false
                    }
                    return muteState
                }
                muteSegment.stateUpdatedNotification = MorphicBarSegmentedButton.Segment.StateUpdateNotificationInfo(
                    notificationName: NSNotification.Name.morphicAudioMuteStateChanged,
                    stateKey: "muteState"
                )
                muteSegment.accessibilityLabelByState = [
                    .on: localized.string(for: "mute.tts.muted"),
                    .off: localized.string(for: "mute.tts.unmuted")
                ]
                //
                // enable muteState change notifications
                if let defaultAudioDeviceId = MorphicAudio.getDefaultAudioDeviceId() {
                    do {
                        try MorphicAudio.enableMuteStateChangeNotifications(for: defaultAudioDeviceId)
                    } catch {
                        NSLog("Could not subscribe to mute state change notifications")
                    }
                }
                //
                segments.append(
                    muteSegment
                )
            }
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.volume(_:))
            return view
        case .contrast:
            let localized = LocalizedStrings(prefix: "control.feature.contrast")
            let onHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "on"), fillColor: buttonColor, helpProvider: onHelpProvider, accessibilityLabel: localized.string(for: "on.help.title"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .contrast), learnMoreTelemetryCategory: "highContrast", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .contrast), quickDemoVideoTelemetryCategory: "highContrast", settingsBlock: { SettingsLinkActions.openSystemPreferencesPaneWithTelemetry(.accessibilityDisplayDisplay, category: "highContrast") }, style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "off"), fillColor: alternateButtonColor, helpProvider: offHelpProvider, accessibilityLabel: localized.string(for: "off.help.title"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .contrast), learnMoreTelemetryCategory: "highContrast", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .contrast), quickDemoVideoTelemetryCategory: "highContrast", settingsBlock: { SettingsLinkActions.openSystemPreferencesPane(.accessibilityDisplayDisplay) }, style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.contrast(_:))
            return view
        case .contrastcolordarknight:
            let localized = LocalizedStrings(prefix: "control.feature.contrastcolordarknight")
            
            let contrastHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "contrast.help.title"), message: localized.string(for: "contrast.help.message")) }
            var contrastSegment = MorphicBarSegmentedButton.Segment(title: localized.string(for: "contrast"), fillColor: buttonColor, helpProvider: contrastHelpProvider, accessibilityLabel: localized.string(for: "contrast.tts"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .contrast), learnMoreTelemetryCategory: "highContrast", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .contrast), quickDemoVideoTelemetryCategory: "highContrast", settingsBlock: { SettingsLinkActions.openSystemPreferencesPaneWithTelemetry(.accessibilityDisplayDisplay, category: "highContrast") }, style: style)
            contrastSegment.getStateBlock = {
                if #available(macOS 10.15, *) {
                    return MorphicDisplayAccessibilitySettings.increaseContrastEnabled
                } else {
                    guard let displayDefaults = UserDefaults(suiteName: "com.apple.universalaccess") else {
                        NSLog("Could not access defaults domain: \"com.apple.universalaccess\"")
                        return false // NOTE: ideally we'd return nil
                    }
                    guard let contrastEnabled = displayDefaults.value(forKey: "increaseContrast") as? Bool else {
                        return false // NOTE: ideally we'd return nil
                    }

                    return contrastEnabled
                }
            }
            contrastSegment.accessibilityLabelByState = [
                .on: localized.string(for: "contrast.tts.enabled"),
                .off: localized.string(for: "contrast.tts.disabled")
            ]
            //
            // enable contrast state change notifications
            AppDelegate.shared.enableContrastChangeNotifications()
            contrastSegment.stateUpdatedNotification = MorphicBarSegmentedButton.Segment.StateUpdateNotificationInfo(
                notificationName: NSNotification.Name.morphicFeatureContrastEnabledChanged,
                stateKey: "enabled"
            )
            //
            let colorHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "color.help.title"), message: localized.string(for: "color.help.message")) }
            var colorSegment = MorphicBarSegmentedButton.Segment(title: localized.string(for: "color"), fillColor: alternateButtonColor, helpProvider: colorHelpProvider, accessibilityLabel: localized.string(for: "color.tts"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .colorvision), learnMoreTelemetryCategory: "colorFilter", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .colorvision), quickDemoVideoTelemetryCategory: "colorFilter", settingsBlock: { SettingsLinkActions.openSystemPreferencesPaneWithTelemetry(.accessibilityDisplayColorFilters, category: "colorFilter") }, style: style)
            colorSegment.getStateBlock = {
                return MorphicDisplayAccessibilitySettings.colorFiltersEnabled
            }
            colorSegment.accessibilityLabelByState = [
                .on: localized.string(for: "color.tts.enabled"),
                .off: localized.string(for: "color.tts.disabled")
            ]
            //
            // enable color filters enabled change notifications
            AppDelegate.shared.enableColorFiltersEnabledChangeNotifications()
            colorSegment.stateUpdatedNotification = MorphicBarSegmentedButton.Segment.StateUpdateNotificationInfo(
                notificationName: NSNotification.Name.morphicFeatureColorFiltersEnabledChanged,
                stateKey: "enabled"
            )
            //
            let darkHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "dark.help.title"), message: localized.string(for: "dark.help.message")) }
            var darkSegment = MorphicBarSegmentedButton.Segment(title: localized.string(for: "dark"), fillColor: buttonColor, helpProvider: darkHelpProvider, accessibilityLabel: localized.string(for: "dark.tts"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .darkmode), learnMoreTelemetryCategory: "darkMode", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .darkmode), quickDemoVideoTelemetryCategory: "darkMode", settingsBlock: { SettingsLinkActions.openSystemPreferencesPaneWithTelemetry(.general, category: "darkMode") }, style: style)
            darkSegment.getStateBlock = {
                let currentAppearanceTheme = MorphicDisplayAppearance.currentAppearanceTheme
                switch currentAppearanceTheme {
                case .dark:
                    return true
                case .light:
                    return false
                }
            }
            darkSegment.accessibilityLabelByState = [
                .on: localized.string(for: "dark.tts.enabled"),
                .off: localized.string(for: "dark.tts.disabled")
            ]
            //
            // enable dark mode (appearance) change notifications
            AppDelegate.shared.enableDarkAppearanceEnabledChangeNotifications()
            darkSegment.stateUpdatedNotification = MorphicBarSegmentedButton.Segment.StateUpdateNotificationInfo(
                notificationName: NSNotification.Name.morphicFeatureInterfaceThemeChanged,
                stateKey: nil // NOTE: the button will query for the theme in real-time
            )
            //
            let nightHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "night.help.title"), message: localized.string(for: "night.help.message")) }
            var nightSegment = MorphicBarSegmentedButton.Segment(title: localized.string(for: "night"), fillColor: alternateButtonColor, helpProvider: nightHelpProvider, accessibilityLabel: localized.string(for: "night.tts"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .nightmode), learnMoreTelemetryCategory: "nightMode", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .nightmode), quickDemoVideoTelemetryCategory: "nightMode", settingsBlock: { SettingsLinkActions.openSystemPreferencesPaneWithTelemetry(.displaysNightShift, category: "nightMode") }, style: style)
            nightSegment.getStateBlock = {
                return MorphicNightShift.getEnabled()
            }
            nightSegment.accessibilityLabelByState = [
                .on: localized.string(for: "night.tts.enabled"),
                .off: localized.string(for: "night.tts.disabled")
            ]
            //
            // enable night shift enabled change notifications
            MorphicNightShift.enableStatusChangeNotifications()
            nightSegment.stateUpdatedNotification = MorphicBarSegmentedButton.Segment.StateUpdateNotificationInfo(
                notificationName: NSNotification.Name.morphicFeatureNightShiftEnabledChanged,
                stateKey: "enabled"
            )
            //
            let segments = [
                contrastSegment,
                colorSegment,
                darkSegment,
                nightSegment
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.contrastcolordarknight(_:))
            return view
        case .nightshift:
            let localized = LocalizedStrings(prefix: "control.feature.nightshift")
            let onHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "on"), fillColor: buttonColor, helpProvider: onHelpProvider, accessibilityLabel: localized.string(for: "on.help.title"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .nightmode), learnMoreTelemetryCategory: "nightMode", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .nightmode), quickDemoVideoTelemetryCategory: "nightMode", settingsBlock: nil, style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "off"), fillColor: alternateButtonColor, helpProvider: offHelpProvider, accessibilityLabel: localized.string(for: "off.help.title"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .nightmode), learnMoreTelemetryCategory: "nightMode", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .nightmode), quickDemoVideoTelemetryCategory: "nightMode", settingsBlock: { SettingsLinkActions.openSystemPreferencesPaneWithTelemetry(.displaysNightShift, category: "nightMode") }, style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.nightShift(_:))
            return view
        case .copypaste:
            let localized = LocalizedStrings(prefix: "control.feature.copypaste")
            let copyHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "copy.help.title"), message: localized.string(for: "copy.help.message")) }
            let pasteHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "paste.help.title"), message: localized.string(for: "paste.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "copy"), fillColor: buttonColor, helpProvider: copyHelpProvider, accessibilityLabel: localized.string(for: "copy.help.title"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .copypaste), learnMoreTelemetryCategory: "copyPaste", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .copypaste), quickDemoVideoTelemetryCategory: "copyPaste", settingsBlock: nil, style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "paste"), fillColor: alternateButtonColor, helpProvider: pasteHelpProvider, accessibilityLabel: localized.string(for: "paste.help.title"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .copypaste), learnMoreTelemetryCategory: "copyPaste", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .copypaste), quickDemoVideoTelemetryCategory: "copyPaste", settingsBlock: nil, style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.copyPaste(_:))
            return view
        case .screensnip:
            let localized = LocalizedStrings(prefix: "control.feature.screensnip")
            let copyHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "copy.help.title"), message: localized.string(for: "copy.help.message")) }
            var snipSegment = MorphicBarSegmentedButton.Segment(title: localized.string(for: "copy"), fillColor: buttonColor, helpProvider: copyHelpProvider, accessibilityLabel: localized.string(for: "copy.tts"), learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .snip), learnMoreTelemetryCategory: "screenSnip", quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .snip), quickDemoVideoTelemetryCategory: "screenSnip", settingsBlock: { SettingsLinkActions.openSystemPreferencesPaneWithTelemetry(.keyboardShortcutsScreenshots, category: "screenSnip") }, style: style)
            snipSegment.settingsMenuItemTitle = "Other Screenshot Shortcuts"
            let segments = [
                snipSegment
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.screensnip)
            return view
        default:
            return nil
        }
    }
    
    @objc
    func zoom(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        guard let display = Display.main else {
            return
        }
        var percentage: Double
        var isZoomingIn: Bool
        var zoomToStep: Int?
        let currentStepOffsetFromNormalMode = display.currentStepOffsetFromNormalMode
        if segment == 0 {
            percentage = display.percentage(zoomingIn: 1)
            zoomToStep = currentStepOffsetFromNormalMode != nil ? currentStepOffsetFromNormalMode! + 1 : nil
            isZoomingIn = true
        } else {
            percentage = display.percentage(zoomingOut: 1)
            zoomToStep = currentStepOffsetFromNormalMode != nil ? currentStepOffsetFromNormalMode! - 1 : nil
            isZoomingIn = false
        }
        //
        defer {
            var segmentation: [String: String] = [:]
            segmentation["scalePercent"] =  String(Int(percentage * 100))
            if let zoomToStep = zoomToStep {
                segmentation["dotOffset"] = String(zoomToStep)
            }
            if isZoomingIn == true {
                Countly.sharedInstance().recordEvent("textSizeIncrease", segmentation: segmentation)
            } else {
                Countly.sharedInstance().recordEvent("textSizeDecrease", segmentation: segmentation)
            }
        }
        //
        _ = display.zoom(to: percentage)
    }
    
    @objc
    func volume(_ sender: Any?) {
        guard let senderAsSegmentedButton = sender as? MorphicBarSegmentedButton else {
            return
        }
        let segment = senderAsSegmentedButton.selectedSegmentIndex
        guard let output = AudioOutput.main else {
            return
        }
        if segment == 0 {
            if output.isMuted {
                _ = output.setMuted(false)
            } else {
                _ = output.setVolume(output.volume + 0.05)
            }
        } else if segment == 1 {
            if output.isMuted {
                _ = output.setMuted(false)
            } else {
                _ = output.setVolume(output.volume - 0.05)
            }
        } else if segment == 2 {
            let currentMuteState = output.isMuted
            let newMuteState = !currentMuteState
            _ = output.setMuted(newMuteState)
        }

        // update the state of the mute button
        senderAsSegmentedButton.setButtonState(index: 2, stateAsBool: output.isMuted)
    }

    @objc
    func volumeWithoutMute(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        guard let output = AudioOutput.main else {
            return
        }
        if segment == 0 {
            if output.isMuted {
                _ = output.setMuted(false)
            } else {
                _ = output.setVolume(output.volume + 0.05)
            }
        } else if segment == 1 {
            if output.isMuted {
                _ = output.setMuted(false)
            } else {
                _ = output.setVolume(output.volume - 0.05)
            }
        }
    }

    @objc
    func copyPaste(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }

        // verify that we have accessibility permissions (since UI automation and sendKeys will not work without them)
        // NOTE: this function call will prompt the user for authorization if they have not already granted it
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: true) == true else {
            NSLog("User had not granted 'accessibility' authorization; user now prompted")
            return
        }

        let keyCode: CGKeyCode
        if segment == 0 {
            // copy
            keyCode = CGKeyCode(kVK_ANSI_C)
        } else if segment == 1 {
            // paste
            keyCode = CGKeyCode(kVK_ANSI_V)
        } else {
            // invalid segment
            return
        }
        let keyOptions = MorphicInput.KeyOptions.withCommandKey
        
        // get the window ID of the topmost window
        guard let (_ /* topmostWindowOwnerName */, topmostProcessId) = MorphicWindow.getWindowOwnerNameAndProcessIdOfTopmostWindow() else {
            NSLog("Could not get ID of topmost window")
            return
        }

        // capture a reference to the topmost application
        guard let topmostApplication = NSRunningApplication(processIdentifier: pid_t(topmostProcessId)) else {
            NSLog("Could not get reference to application owning the topmost window")
            return
        }

        // activate the topmost application
        guard topmostApplication.activate(options: .activateIgnoringOtherApps) == true else {
            NSLog("Could not activate the topmost window")
            return
        }

        AsyncUtils.wait(atMost: 2.0, for: { topmostApplication.isActive == true }) {
            success in
            if success == false {
                NSLog("Could not activate topmost application within two seconds")
            }
            
            // send the appropriate hotkey to the system
            guard MorphicInput.sendKey(keyCode: keyCode, keyOptions: keyOptions) == true else {
                NSLog("Could not send copy/paste hotkey to the keyboard input stream")
                return
            }
        }
    }

    @objc
    func screensnip(_ sender: Any?) {
        defer {
            Countly.sharedInstance().recordEvent("screenSnip")
        }

        // verify that we have accessibility permissions (since UI automation and sendKeys will not work without them)
        // NOTE: this function call will prompt the user for authorization if they have not already granted it
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: true) == true else {
            NSLog("User had not granted 'accessibility' authorization; user now prompted")
            return
        }

        var keyCode: CGKeyCode
        var keyOptions: MorphicInput.KeyOptions
        var hotKeyEnabled: Bool
        //
        if let hotKeyInfo = MorphicInput.hotKeyForSystemKeyboardShortcut(.copyPictureOfSelectedAreaToTheClipboard) {
            keyCode = hotKeyInfo.keyCode
            keyOptions = hotKeyInfo.keyOptions
            hotKeyEnabled = hotKeyInfo.enabled
        } else {
            // NOTE: in macOS 10.14+ (tested through 10.15), the hotkeys are not written out to the appropriate .plist file until one of them is changed (including disabling the enabled-by-default feature); the current strategy is to assume the default key combo in this scenario, but in the future we may want to consider reverse engineering the HI libraries or Keyboard system preferences pane to find another way to get this data
            
            // default values
            keyCode = CGKeyCode(kVK_ANSI_4)
            keyOptions = [
                .withShiftKey,
                .withControlKey,
                .withCommandKey
            ]
            hotKeyEnabled = true
        }
        
        guard hotKeyEnabled == true else {
            NSLog("Screen snip feature is currently disabled")
            return
        }
        
        // hide the QuickHelp window
        QuickHelpWindow.hide(withoutDelay: true) {
            // after we hide the QuickHelp window, send our key
            
            guard MorphicInput.sendKey(keyCode: keyCode, keyOptions: keyOptions) == true else {
                NSLog("Could not send 'screen snip' hotkey to the keyboard input stream")
                return
            }
        }
    }
    
    @objc
    func contrast(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        if segment == 0 {
            Session.shared.apply(true, for: .macosDisplayContrastEnabled) {
                _ in
            }
        } else {
            Session.shared.apply(false, for: .macosDisplayContrastEnabled) {
                _ in
            }
        }
    }
    
    @objc
    func contrastcolordarknight(_ sender: Any?) {
        guard let senderAsSegmentedButton = sender as? MorphicBarSegmentedButton else {
            return
        }
        let segment = senderAsSegmentedButton.selectedSegmentIndex
        switch segment {
        case 0:
            // contrast (increase contrast enabled)
            
            // NOTE: this alternate implementation (compatible with macOS 10.15+) is failing to change the system-wide contrast in macOS 10.15.7, so we've reverted to the original (macOS 10.14+) ui automation approach
//            if #available(macOS 10.15, *) {
//                let increaseContrastEnabled = MorphicDisplayAccessibilitySettings.increaseContrastEnabled
//                let newIncreaseContrastEnabled = !increaseContrastEnabled
//                MorphicDisplayAccessibilitySettings.setIncreaseContrastEnabled(newIncreaseContrastEnabled)
//                //
//                let verifyIncreaseContrastEnabled = MorphicDisplayAccessibilitySettings.increaseContrastEnabled
//                senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: verifyIncreaseContrastEnabled)
//            } else {
                // macOS 10.14
             
                // capture the current "contrast enabled" setting
                let increaseContrastEnabled = MorphicDisplayAccessibilitySettings.increaseContrastEnabled
                // calculate the inverse state
                let newIncreaseContrastEnabled = !increaseContrastEnabled
                //
                defer {
                    Countly.sharedInstance().recordEvent(newIncreaseContrastEnabled ? "highContrastOn" : "highContrastOff")
                }
                // apply the inverse state
                Session.shared.apply(newIncreaseContrastEnabled, for: .macosDisplayContrastEnabled) {
                    success in
                    // we do not currently have a mechanism to report success/failure

                    let verifyIncreaseContrastEnabled = MorphicDisplayAccessibilitySettings.increaseContrastEnabled
                    senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: verifyIncreaseContrastEnabled)
                }
//            }
        case 1:
            // color (color filter)
            
            if #available(macOS 10.15, *) {
                // capture the current "color filter enabled" setting
                SettingsManager.shared.capture(valueFor: .macosColorFilterEnabled) {
                    value in
                    guard let valueAsBoolean = value as? Bool else {
                        // could not get current setting
                        return
                    }
                    // calculate the inverse state
                    let newValue = !valueAsBoolean
                    
                    defer {
                        Countly.sharedInstance().recordEvent(newValue ? "colorFiltersOn" : "colorFiltersOff")
                    }
                    
                    // if the inverse state is "enabled", then make sure we've set the initial color filter type
                    if newValue == true {
                        // set the default color filter type (if it hasn't already been set)
                        let didSetInitialColorFilterType = Session.shared.bool(for: .morphicDidSetInitialColorFilterType) ?? false
                        if didSetInitialColorFilterType == false {
                            // NOTE: we get no "success/failure" from the following function, so we just have to assume success
                            AppDelegate.shared.setInitialColorFilterType()
                        }
                    }
                    
                    // apply the inverse state
                    //
                    // NOTE: due to current limitations in our implementation, we are unable to disable "invert colors" (which is the desired effect when enabling color filters); this is unlikely to be a common scenario, but if we run into it then we need to use the backup UI automation mechanism
                    // NOTE: in the future, we should rework the settings handlers so that they can call native code which can launch a UI automation (instead of being either/or)...and then move this logic to the settings handler code
                    if newValue == true && MorphicDisplayAccessibilitySettings.invertColorsEnabled == true {
                        Session.shared.apply(newValue, for: .macosColorFilterEnabled) {
                            success in
                            
                            // we do not currently have a mechanism to report success/failure
                            SettingsManager.shared.capture(valueFor: .macosColorFilterEnabled) {
                                verifyValue in
                                guard let verifyValueAsBoolean = verifyValue as? Bool else {
                                    // could not get current setting
                                    return
                                }
                                senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: verifyValueAsBoolean)
                            }
                        }
                    } else {
                        MorphicDisplayAccessibilitySettings.setColorFiltersEnabled(newValue)
                        //
                        let verifyColorFiltersEnabled = MorphicDisplayAccessibilitySettings.colorFiltersEnabled
                        senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: verifyColorFiltersEnabled)
                    }
                }
            } else {
                // macOS 10.14
                
                let alert = NSAlert()
                alert.messageText = "Color Vision filters not available."
                alert.informativeText = "Color Vision filters (including color blindness filters) are not available in this older version of macOS.\n\nPlease upgrade to macOS 10.15 (Catalina) or newer to use this feature."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                _ = alert.runModal()
            }
        case 2:
            // dark
            
            // NOTE: unlike System Preferences, we do not copy the current screen and then "fade" it into the new theme once the theme has switched; if we need that kind of behavior then we'll need screen capture permissions or we'll need to use the alternate (UI automation) code below.  There may also be other alternatives.
            let newDarkModeEnabled: Bool
            switch MorphicDisplayAppearance.currentAppearanceTheme {
            case .dark:
                newDarkModeEnabled = false
            case .light:
                newDarkModeEnabled = true
            }
            //
            defer {
                Countly.sharedInstance().recordEvent(newDarkModeEnabled ? "darkModeOn" : "darkModeOff")
            }
            //
            switch newDarkModeEnabled {
            case true:
                MorphicDisplayAppearance.setCurrentAppearanceTheme(.dark)
            case false:
                MorphicDisplayAppearance.setCurrentAppearanceTheme(.light)
            }
            //
            let verifyCurrentAppearanceTheme = MorphicDisplayAppearance.currentAppearanceTheme
            let verifyButtonState: Bool
            switch verifyCurrentAppearanceTheme {
            case .dark:
                verifyButtonState = false
            case .light:
                verifyButtonState = true
            }
            senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: verifyButtonState)

//            // NOTE: if we ever have problems with our reverse-engineered implementation (above), the below UI automation code also works (albeit very slowly)
//            switch NSApp.effectiveAppearance.name {
//            case .darkAqua,
//                 .vibrantDark,
//                 .accessibilityHighContrastDarkAqua,
//                 .accessibilityHighContrastVibrantDark:
//                let lightAppearanceCheckboxUIAutomation = LightAppearanceUIAutomation()
//                lightAppearanceCheckboxUIAutomation.apply(true) {
//                    success in
//                    // we do not currently have a mechanism to report success/failure
//                    senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: newValue)
//                }
//            case .aqua,
//                 .vibrantLight,
//                 .accessibilityHighContrastAqua,
//                 .accessibilityHighContrastVibrantLight:
//                let darkAppearanceCheckboxUIAutomation = DarkAppearanceUIAutomation()
//                darkAppearanceCheckboxUIAutomation.apply(true) {
//                    success in
//                    // we do not currently have a mechanism to report success/failure
//                    senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: newValue)
//                }
//            default:
//                // unknown appearance
//                break
//            }
        case 3:
            // night
            
            let nightShiftEnabled = MorphicNightShift.getEnabled()
            let newNightShiftEnabled = !nightShiftEnabled
            //
            defer {
                Countly.sharedInstance().recordEvent(newNightShiftEnabled ? "nightModeOn" : "nightModeOff")
            }
            //
            MorphicNightShift.setEnabled(newNightShiftEnabled)
            //
            let verifyNightShiftEnabled = MorphicNightShift.getEnabled()
            senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: verifyNightShiftEnabled)
        default:
            fatalError("impossible code branch")
        }
    }
    
    @objc
    func nightShift(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        if segment == 0 {
            MorphicNightShift.setEnabled(true)
        } else {
            MorphicNightShift.setEnabled(false)
        }
    }

    @objc
    func reader(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        if segment == 0 {
            Session.shared.apply(true, for: .macosVoiceOverEnabled) {
                _ in
            }
        } else {
            Session.shared.apply(false, for: .macosVoiceOverEnabled) {
                _ in
            }
        }
    }

    @objc
    func readselected(_ sender: Any?) {
        defer {
            Countly.sharedInstance().recordEvent("readSelectedToggle")
        }
        
        // verify that we have accessibility permissions (since UI automation and sendKeys will not work without them)
        // NOTE: this function call will prompt the user for authorization if they have not already granted it
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: true) == true else {
            NSLog("User had not granted 'accessibility' authorization; user now prompted")
            return
        }
        
        // NOTE: we retrieve system settings here which are _not_ otherwise captured by Morphic; if we decide to capture those settings in the future for broader capture/apply purposes, then we should modify this code to access those settings via Session.shared (if doing so will ensure that we are not getting cached data...rather than 'captured or set data'...since we need to check these settings every time this function is called).
        let defaultsDomain = "com.apple.speech.synthesis.general.prefs"
        guard let defaults = UserDefaults(suiteName: defaultsDomain) else {
            NSLog("Could not access defaults domain: \(defaultsDomain)")
            return
        }
        
        // NOTE: sendSpeakSelectedTextHotKey will be called synchronously or asynchronously (depending on whether we need to enable the OS feature asynchronously first)
        let sendSpeakSelectedTextHotKey = {
            // obtain any custom-specified key sequence used for activating the "speak selected text" feature in macOS (or else assume default)
            let speakSelectedTextHotKeyCombo = defaults.integer(forKey: "SpokenUIUseSpeakingHotKeyCombo")
            //
            let keyCode: CGKeyCode
            let keyOptions: MorphicInput.KeyOptions
            if speakSelectedTextHotKeyCombo != 0 {
                guard let (customKeyCode, customKeyOptions) = MorphicInput.parseDefaultsKeyCombo(speakSelectedTextHotKeyCombo) else {
                    // NOTE: while we should be able to decode any custom hotkey, this code is here to capture edge cases we have not anticipated
                    // NOTE: in the future, we should consider an informational prompt alerting the user that we could not decode their custom hotkey (so they know why the feature did not work...or at least that it intentionally did not work)
                    NSLog("Could not decode custom hotkey")
                    return
                }
                keyCode = customKeyCode
                keyOptions = customKeyOptions
            } else {
                // default hotkey is Option+Esc
                keyCode = CGKeyCode(kVK_Escape)
                keyOptions = .withAlternateKey
            }
            
            //
            
            // get the window ID of the topmost window
            guard let (_ /* topmostWindowOwnerName */, topmostProcessId) = MorphicWindow.getWindowOwnerNameAndProcessIdOfTopmostWindow() else {
                NSLog("Could not get ID of topmost window")
                return
            }

            // capture a reference to the topmost application
            guard let topmostApplication = NSRunningApplication(processIdentifier: pid_t(topmostProcessId)) else {
                NSLog("Could not get reference to application owning the topmost window")
                return
            }
            
            // activate the topmost application
            guard topmostApplication.activate(options: .activateIgnoringOtherApps) == true else {
                NSLog("Could not activate the topmost window")
                return
            }
            
            AsyncUtils.wait(atMost: 2.0, for: { topmostApplication.isActive == true }) {
                success in
                if success == false {
                    NSLog("Could not activate topmost application within two seconds")
                }
                
                // send the "speak selected text key" to the system
                guard MorphicInput.sendKey(keyCode: keyCode, keyOptions: keyOptions) == true else {
                    NSLog("Could not send 'Speak selected text' hotkey to the keyboard input stream")
                    return
                }
            }
        }
        
        // make sure the user has "speak selected text..." enabled in System Preferences
        let speakSelectedTextKeyEnabled = defaults.bool(forKey: "SpokenUIUseSpeakingHotKeyFlag")
        if speakSelectedTextKeyEnabled == false {
            // if SpokenUIUseSpeakingHotKeyFlag is false, then enable it via UI automation
            Session.shared.apply(true, for: .macosSpeakSelectedTextEnabled) {
                _ in
                // send the hotkey (asynchronously) once we have enabled macOS's "speak selected text" feature
                sendSpeakSelectedTextHotKey()
            }
        } else {
            // send the hotkey (synchronously) now
            sendSpeakSelectedTextHotKey()
        }
    }

    @objc
    func magnifier(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        let session = Session.shared
        if segment == 0 {
            defer {
                Countly.sharedInstance().recordEvent("magnifierShow")
            }
            
            // this is the code which will activate our magnifier once we have established that it is configured properly
            let activateMagnifier: () -> Void = {
                session.storage.load(identifier: "__magnifier__") {
                    (_, preferences: Preferences?) in
                    if let preferences = preferences {
                        // temporary workaround: if "style" was specified as a preference, remove it (because it's a one-time setup preference)
                        var mutablePreferences = preferences
                        if mutablePreferences.get(key: .macosZoomStyle) != nil {
                            mutablePreferences.remove(key: .macosZoomStyle)
                        }
                        
                        let apply = ApplySession(settingsManager: session.settings, preferences: mutablePreferences)
                        apply.addFirst(key: .macosZoomEnabled, value: true)
                        apply.run {
                        }
                    } else {
                        session.apply(true, for: .macosZoomEnabled) {
                            _ in
                        }
                    }
                }
            }
            
            // set the default magnifier zoom style (if it hasn't already been set)
            let didSetInitialMagnifierZoomStyle = Session.shared.bool(for: .morphicDidSetInitialMagnifierZoomStyle) ?? false
            if didSetInitialMagnifierZoomStyle == false {
                // NOTE: we get no "success/failure" from the following function, so we just have to assume success
                AppDelegate.shared.setInitialMagnifierZoomStyle() {
                    success in
                    
                    guard success == true else {
                        os_log("Cannot set initial magnifier zoom style")
                        return
                    }
                    
                    activateMagnifier()
                }
            } else {
                activateMagnifier()
            }
        } else {
            defer {
                Countly.sharedInstance().recordEvent("magnifierHide")
            }
            
            session.storage.load(identifier: "__magnifier__") {
                (_, preferences: Preferences?) in
                if let preferences = preferences {
                    // temporary workaround: if "style" was specified as a preference, remove it (because it's a one-time setup preference)
                    var mutablePreferences = preferences
                    if mutablePreferences.get(key: .macosZoomStyle) != nil {
                        mutablePreferences.remove(key: .macosZoomStyle)
                    }

                    let apply = ApplySession(settingsManager: session.settings, preferences: mutablePreferences)
                    apply.addFirst(key: .macosZoomEnabled, value: false)
                    apply.run {
                    }
                } else {
                    session.apply(false, for: .macosZoomEnabled) {
                        _ in
                    }
                }
            }
        }
    }
    
}

fileprivate struct LocalizedStrings {
    
    var prefix: String
    var table = "MorphicBarViewController"
    var bundle = Bundle.main
    
    init(prefix: String) {
        self.prefix = prefix
    }
    
    func string(for suffix: String) -> String {
        return bundle.localizedString(forKey: prefix + "." + suffix, value: nil, table: table)
    }
}

fileprivate class QuickHelpDynamicTextProvider: QuickHelpContentProvider {
    
    var textProvider: () -> (String, String)?
    
    init(textProvider: @escaping () -> (String, String)?) {
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

fileprivate class QuickHelpTextSizeBiggerProvider: QuickHelpContentProvider {
    
    init(display: Display?, localized: LocalizedStrings) {
        self.display = display
        self.localized = localized
    }
    
    var display: Display?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let viewController = QuickHelpStepViewController(nibName: "QuickHelpStepViewController", bundle: nil)
        let total = display?.numberOfSteps ?? 1
        var step = display?.currentStep ?? -1
        if step >= 0 {
            step = total - 1 - step
        }
        viewController.numberOfSteps = total
        viewController.step = step
        if step == total - 1 {
            viewController.titleText = localized.string(for: "bigger.limit.help.title")
            viewController.messageText = localized.string(for: "bigger.limit.help.message")
        } else {
            viewController.titleText = localized.string(for: "bigger.help.title")
            viewController.messageText = localized.string(for: "bigger.help.message")
        }
        return viewController
    }
}

fileprivate class QuickHelpTextSizeSmallerProvider: QuickHelpContentProvider {
    
    init(display: Display?, localized: LocalizedStrings) {
        self.display = display
        self.localized = localized
    }
    
    var display: Display?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let viewController = QuickHelpStepViewController(nibName: "QuickHelpStepViewController", bundle: nil)
        let total = display?.numberOfSteps ?? 1
        var step = display?.currentStep ?? -1
        if step >= 0 {
            step = total - 1 - step
        }
        viewController.numberOfSteps = total
        viewController.step = step
        if step == 0 {
            viewController.titleText = localized.string(for: "smaller.limit.help.title")
            viewController.messageText = localized.string(for: "smaller.limit.help.message")
        } else {
            viewController.titleText = localized.string(for: "smaller.help.title")
            viewController.messageText = localized.string(for: "smaller.help.message")
        }
        return viewController
    }
}

fileprivate class QuickHelpVolumeUpProvider: QuickHelpContentProvider {
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings) {
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
        if muted {
            viewController.titleText = localized.string(for: "up.muted.help.title")
            viewController.messageText = localized.string(for: "up.muted.help.message")
        } else {
            if level >= 0.99 {
                viewController.titleText = localized.string(for: "up.limit.help.title")
                viewController.messageText = localized.string(for: "up.limit.help.message")
            } else {
                viewController.titleText = localized.string(for: "up.help.title")
                viewController.messageText = localized.string(for: "up.help.message")
            }
        }
        return viewController
    }
    
}

fileprivate class QuickHelpVolumeDownProvider: QuickHelpContentProvider {
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings) {
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
        if muted {
            viewController.titleText = localized.string(for: "down.muted.help.title")
            viewController.messageText = localized.string(for: "down.muted.help.message")
        } else {
            if level <= 0.01{
                viewController.titleText = localized.string(for: "down.limit.help.title")
                viewController.messageText = localized.string(for: "down.limit.help.message")
            } else {
                viewController.titleText = localized.string(for: "down.help.title")
                viewController.messageText = localized.string(for: "down.help.message")
            }
        }
        return viewController
    }
    
}

fileprivate class QuickHelpVolumeMuteProvider: QuickHelpContentProvider {
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings) {
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
        if muted {
            viewController.titleText = localized.string(for: "muted.help.title")
            viewController.messageText = localized.string(for: "muted.help.message")
        } else {
            viewController.titleText = localized.string(for: "mute.help.title")
            viewController.messageText = localized.string(for: "mute.help.message")
        }
        return viewController
    }
    
}

private extension NSImage {
    
    static func plus() -> NSImage {
        return NSImage(named: "SegmentIconPlus")!
    }
    
    static func minus() -> NSImage {
        return NSImage(named: "SegmentIconMinus")!
    }
    
}

private extension NSColor {
    
    // string must be formatted as #rrggbb
    static func createFromRgbHexString(_ rgbHexString: String) -> NSColor? {
        if rgbHexString.count != 7 {
            return nil
        }
        
        let hashStartIndex = rgbHexString.startIndex
        let redStartIndex = rgbHexString.index(hashStartIndex, offsetBy: 1)
        let greenStartIndex = rgbHexString.index(redStartIndex, offsetBy: 2)
        let blueStartIndex = rgbHexString.index(greenStartIndex, offsetBy: 2)
        
        let hashAsString = rgbHexString[hashStartIndex..<redStartIndex]
        guard hashAsString == "#" else {
            return nil
        }
        
        let redAsHexString = rgbHexString[redStartIndex..<greenStartIndex]
        guard let redAsInt = Int(redAsHexString, radix: 16),
            redAsInt >= 0,
            redAsInt <= 255 else {
            //
            return nil
        }
        let greenAsHexString = rgbHexString[greenStartIndex..<blueStartIndex]
        guard let greenAsInt = Int(greenAsHexString, radix: 16),
            greenAsInt >= 0,
            greenAsInt <= 255 else {
            return nil
        }
        let blueAsHexString = rgbHexString[blueStartIndex...]
        guard let blueAsInt = Int(blueAsHexString, radix: 16),
            blueAsInt >= 0,
            blueAsInt <= 255 else {
            //
            return nil
        }
        
        return NSColor(red: CGFloat(redAsInt) / 255.0, green: CGFloat(greenAsInt) / 255.0, blue: CGFloat(blueAsInt) / 255.0, alpha: 1.0)
    }
}
