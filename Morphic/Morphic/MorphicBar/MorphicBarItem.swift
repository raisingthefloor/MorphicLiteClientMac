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
import MorphicCore
import MorphicSettings
import MorphicService

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
            return createMorphicBarActionItem(interoperable: interoperable)
        default:
            return nil
        }
    }
    
    private static func createMorphicBarActionItem(interoperable: [String: Interoperable?]) -> MorphicBarItem? {
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
                MorphicBarSegmentedButton.Segment(icon: .plus(), fillColor: buttonColor, helpProvider:  QuickHelpTextSizeBiggerProvider(display: Display.main, localized: localized), accessibilityLabel: localized.string(for: "bigger.tts"), style: style),
                MorphicBarSegmentedButton.Segment(icon: .minus(), fillColor: alternateButtonColor, helpProvider: QuickHelpTextSizeSmallerProvider(display: Display.main, localized: localized), accessibilityLabel: localized.string(for: "smaller.tts"), style: style)
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
            let showHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: isOnOff ? "on.help.title" : "show.help.title"), message: localized.string(for: isOnOff ? "on.help.message" : "show.help.message")) }
            let hideHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: isOnOff ? "off.help.title" : "hide.help.title"), message: localized.string(for: isOnOff ? "off.help.message" : "hide.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: isOnOff ? "on" : "show"), fillColor: buttonColor, helpProvider: showHelpProvider, accessibilityLabel: localized.string(for: isOnOff ? "on.help.title" : "show.tts"), style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: isOnOff ? "off" : "hide"), fillColor: alternateButtonColor, helpProvider: hideHelpProvider, accessibilityLabel: localized.string(for: isOnOff ? "off.help.title" : "hide.tts"), style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.magnifier(_:))
            return view
        case .reader:
            let localized = LocalizedStrings(prefix: "control.feature.reader")
            let onHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "on"), fillColor: buttonColor, helpProvider: onHelpProvider, accessibilityLabel: localized.string(for: "on.tts"), style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "off"), fillColor: alternateButtonColor, helpProvider: offHelpProvider, accessibilityLabel: localized.string(for: "off.tts"), style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.reader(_:))
            return view
        case .readselected:
            let localized = LocalizedStrings(prefix: "control.feature.readselected")
            let playStopHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "playstop.help.title"), message: localized.string(for: "playstop.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "playstop"), fillColor: buttonColor, helpProvider: playStopHelpProvider, accessibilityLabel: localized.string(for: "playstop.tts"), style: style)
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
                MorphicBarSegmentedButton.Segment(icon: .plus(), fillColor: buttonColor, helpProvider: QuickHelpVolumeUpProvider(audioOutput: AudioOutput.main, localized: localized), accessibilityLabel: localized.string(for: "up.help.title"), style: style),
                MorphicBarSegmentedButton.Segment(icon: .minus(), fillColor: alternateButtonColor, helpProvider: QuickHelpVolumeDownProvider(audioOutput: AudioOutput.main, localized: localized), accessibilityLabel: localized.string(for: "down.help.title"), style: style)
            ]
            if feature == .volume {
                segments.append(
                    MorphicBarSegmentedButton.Segment(title: localized.string(for: "mute"), fillColor: buttonColor, helpProvider: QuickHelpVolumeMuteProvider(audioOutput: AudioOutput.main, localized: localized), accessibilityLabel: localized.string(for: "mute.help.title"), style: style)
                )
            }
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.volume(_:))
            return view
        case .contrast:
            let localized = LocalizedStrings(prefix: "control.feature.contrast")
            let onHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "on"), fillColor: buttonColor, helpProvider: onHelpProvider, accessibilityLabel: localized.string(for: "on.help.title"), style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "off"), fillColor: alternateButtonColor, helpProvider: offHelpProvider, accessibilityLabel: localized.string(for: "off.help.title"), style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.contrast(_:))
            return view
        case .contrastcolordarknight:
            let localized = LocalizedStrings(prefix: "control.feature.contrastcolordarknight")
            let contrastHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "contrast.help.title"), message: localized.string(for: "contrast.help.message")) }
            let colorHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "color.help.title"), message: localized.string(for: "color.help.message")) }
            let darkHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "dark.help.title"), message: localized.string(for: "dark.help.message")) }
            let nightHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "night.help.title"), message: localized.string(for: "night.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "contrast"), fillColor: buttonColor, helpProvider: contrastHelpProvider, accessibilityLabel: localized.string(for: "contrast.tts"), style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "color"), fillColor: alternateButtonColor, helpProvider: colorHelpProvider, accessibilityLabel: localized.string(for: "color.tts"), style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "dark"), fillColor: buttonColor, helpProvider: darkHelpProvider, accessibilityLabel: localized.string(for: "dark.tts"), style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "night"), fillColor: alternateButtonColor, helpProvider: nightHelpProvider, accessibilityLabel: localized.string(for: "night.tts"), style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.contrastcolordarknight(_:))
            view.segmentedButton.rightClickAction = #selector(MorphicBarControlItem.contrastcolordarknightMenu(_:))
            return view
        case .nightshift:
            let localized = LocalizedStrings(prefix: "control.feature.nightshift")
            let onHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "on"), fillColor: buttonColor, helpProvider: onHelpProvider, accessibilityLabel: localized.string(for: "on.help.title"), style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "off"), fillColor: alternateButtonColor, helpProvider: offHelpProvider, accessibilityLabel: localized.string(for: "off.help.title"), style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.nightShift(_:))
            return view
        case .copypaste:
            let localized = LocalizedStrings(prefix: "control.feature.copypaste")
            let copyHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "copy.help.title"), message: localized.string(for: "copy.help.message")) }
            let pasteHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "paste.help.title"), message: localized.string(for: "paste.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "copy"), fillColor: buttonColor, helpProvider: copyHelpProvider, accessibilityLabel: localized.string(for: "copy.help.title"), style: style),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "paste"), fillColor: alternateButtonColor, helpProvider: pasteHelpProvider, accessibilityLabel: localized.string(for: "paste.help.title"), style: style)
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.copyPaste(_:))
            return view
        case .screensnip:
            let localized = LocalizedStrings(prefix: "control.feature.screensnip")
            let copyHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "copy.help.title"), message: localized.string(for: "copy.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "copy"), fillColor: buttonColor, helpProvider: copyHelpProvider, accessibilityLabel: localized.string(for: "copy.tts"), style: style)
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
        if segment == 0 {
            percentage = display.percentage(zoomingIn: 1)
        } else {
            percentage = display.percentage(zoomingOut: 1)
        }
        _ = display.zoom(to: percentage)
    }
    
    @objc
    func volume(_ sender: Any?) {
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
        } else if segment == 2 {
            _ = output.setMuted(true)
        }
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
        let keyCode: CGKeyCode = CGKeyCode(kVK_ANSI_4)
        let keyOptions: MorphicInput.KeyOptions = [
            .withCommandKey,
            .withShiftKey
        ]
        
        guard MorphicInput.sendKey(keyCode: keyCode, keyOptions: keyOptions) == true else {
            NSLog("Could not send 'screen snip' hotkey to the keyboard input stream")
            return
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
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        switch segment {
        case 0:
            // contrast (increase contrast enabled)
            
            // capture the current "contrast enabled" setting
            SettingsManager.shared.capture(valueFor: .macosDisplayContrastEnabled) {
                value in
                guard let valueAsBoolean = value as? Bool else {
                    // could not get current setting
                    return
                }
                // calculate the inverse state
                let newValue = !valueAsBoolean
                // apply the inverse state
                Session.shared.apply(newValue, for: .macosDisplayContrastEnabled) {
                    success in
                    // we do not currently have a mechanism to report success/failure
                }
            }
        case 1:
            // color (color filter)
            
            // capture the current "color filter enabled" setting
            SettingsManager.shared.capture(valueFor: .macosColorFilterEnabled) {
                value in
                guard let valueAsBoolean = value as? Bool else {
                    // could not get current setting
                    return
                }
                // calculate the inverse state
                let newValue = !valueAsBoolean
                // apply the inverse state
                Session.shared.apply(newValue, for: .macosColorFilterEnabled) {
                    success in
                    // we do not currently have a mechanism to report success/failure
                }
            }
        case 2:
            // dark
            
            switch NSApp.effectiveAppearance.name {
            case .darkAqua,
                 .vibrantDark,
                 .accessibilityHighContrastDarkAqua,
                 .accessibilityHighContrastVibrantDark:
                let lightAppearanceCheckboxUIAutomation = LightAppearanceUIAutomation()
                lightAppearanceCheckboxUIAutomation.apply(true) {
                    success in
                    // we do not currently have a mechanism to report success/failure
                }
            case .aqua,
                 .vibrantLight,
                 .accessibilityHighContrastAqua,
                 .accessibilityHighContrastVibrantLight:
                let darkAppearanceCheckboxUIAutomation = DarkAppearanceUIAutomation()
                darkAppearanceCheckboxUIAutomation.apply(true) {
                    success in
                    // we do not currently have a mechanism to report success/failure
                }
            default:
                // unknown appearance
                break
            }
        case 3:
            // night
            
            let nightShiftEnabled = MorphicNightShift.getEnabled()
            MorphicNightShift.setEnabled(!nightShiftEnabled)
        default:
            fatalError("impossible code branch")
        }
    }
    
    //
    
    @objc
    func contrastcolordarknightMenu(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        switch segment {
        case 0:
            // contrast (increase contrast enabled)
            break
        case 1:
            // color (color filter)
            
            let learnMoreMenuItem = NSMenuItem(title: "Learn more", action: #selector(self.colorFilterLearnMore), keyEquivalent: "")
            learnMoreMenuItem.target = self
            let quickDemoVideoMenuItem = NSMenuItem(title: "Quick Demo video", action: #selector(self.colorFilterQuickDemoVideo), keyEquivalent: "")
            quickDemoVideoMenuItem.target = self
            let settingsMenuItem = NSMenuItem(title: "Settings", action: #selector(self.colorFilterSettings), keyEquivalent: "")
            settingsMenuItem.target = self
            //
            let rightClickMenu = NSMenu()
            rightClickMenu.addItem(learnMoreMenuItem)
            rightClickMenu.addItem(quickDemoVideoMenuItem)
            rightClickMenu.addItem(settingsMenuItem)
            
            rightClickMenu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        case 2:
            // dark
            
            break
        case 3:
            // night
            
            break
        default:
            fatalError("impossible code branch")
        }
    }
    
    // TODO: this is a temporary function; refactor this function (or reorganize, generally)
    @objc
    func colorFilterLearnMore(_ sender: Any?) {
	//
    }

    // TODO: this is a temporary function; refactor this function (or reorganize, generally)
    @objc
    func colorFilterQuickDemoVideo(_ sender: Any?) {
	//
    }

    // TODO: this is a temporary function; refactor this function (or reorganize, generally)
    @objc
    func colorFilterSettings(_ sender: Any?) {
        let accessibilityUIAutomation = AccessibilityUIAutomation(hideSystemPreferences: true)
        accessibilityUIAutomation.showAccessibilityDisplayPreferences(tab: "Color Filters") {
            accessibilityPreferencesElement in
         
            guard let _ = accessibilityPreferencesElement else {
                // if we could not successfully launch System Preferences and navigate to this pane, log the error
                // NOTE for future enhancement: notify the user of any errors here (and retry or try different methods)
                NSLog("Could not open settings panel")
                return
            }

            // show System Preferences and raise it to the top of the application window stack
            guard let systemPreferencesApplication = NSRunningApplication.runningApplications(withBundleIdentifier: SystemPreferencesElement.bundleIdentifier).first else {
                return
            }
            systemPreferencesApplication.activate(options: .activateIgnoringOtherApps)
        }
    }
    
    //

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
            let keyValuesToSet: [(Preferences.Key, Interoperable?)] = [
                (.macosZoomStyle, 1)
            ]
            let preferences = Preferences(identifier: "__magnifier__")
            let capture = CaptureSession(settingsManager: session.settings, preferences: preferences)
            capture.keys = keyValuesToSet.map{ $0.0 }
            capture.captureDefaultValues = true
            capture.run {
                session.storage.save(record: capture.preferences) {
                    _ in
                    let apply = ApplySession(settingsManager: session.settings, keyValueTuples: keyValuesToSet)
                    apply.add(key: .macosZoomEnabled, value: true)
                    apply.run {
                    }
                }
            }
        } else {
            session.storage.load(identifier: "__magnifier__") {
                (_, preferences: Preferences?) in
                if let preferences = preferences {
                    let apply = ApplySession(settingsManager: session.settings, preferences: preferences)
                    apply.addFirst(key: .macosZoomEnabled, value: false)
                    apply.run {
                    }
                } else {
                    session.apply(false, for: .macosZoomEnabled){
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

fileprivate class QuickHelpDynamicTextProvider: QuickHelpContentProvider{
    
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
        if step >= 0{
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
