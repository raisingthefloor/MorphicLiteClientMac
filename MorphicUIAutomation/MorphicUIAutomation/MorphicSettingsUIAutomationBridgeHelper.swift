// Copyright 2020-2023 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/raisingthefloor/morphic-macos/blob/master/LICENSE.txt
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
import MorphicSettings

public class MorphicSettingsUIAutomationBridgeHelper {
    public static func setupUIAutomationSetSettingProxies() {
        // Display
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: IncreaseConstrastUIAutomationSetSettingProxy.self, for: .macosDisplayContrastEnabled)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: IncreaseColorsUIAutomationSetSettingProxy.self, for: .macosDisplayInvertColors)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: InvertClassicUIAutomationSetSettingProxy.self, for: .macosDisplayClassicInvert)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: ReduceMotionUIAutomationSetSettingProxy.self, for: .macosDisplayReduceMotion)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: ReduceTransparencyUIAutomationSetSettingProxy.self, for: .macosDisplayReduceTransparency)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: DifferentiateWithoutColorUIAutomationSetSettingProxy.self, for: .macosDisplayDifferentiateWithoutColor)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: CursorShakeUIAutomationSetSettingProxy.self, for: .macosCursorShake)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: CursorSizeUIAutomationSetSettingProxy.self, for: .macosCursorSize)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: ColorFilterEnabledUIAutomationSetSettingProxy.self, for: .macosColorFilterEnabled)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: ColorFilterTypeUIAutomationSetSettingProxy.self, for: .macosColorFilterType)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: ColorFilterIntensityUIAutomation.self, for: .macosColorFilterIntensity)
        
        // Speech
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: SpeakSelectedTextEnabledUIAutomation.self, for: .macosSpeakSelectedTextEnabled)
        
        // VoiceOver
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: VoiceOverUIAutomation.self, for: .macosVoiceOverEnabled)
        
        // Zoom
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: ZoomEnabledUIAutomation.self, for: .macosZoomEnabled)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: ScrollToZoomEnabledUIAutomation.self, for: .macosScrollToZoomEnabled)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: HoverTextEnabledUIAutomation.self, for: .macosHoverTextEnabled)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: TouchbarZoomEnabledUIAutomation.self, for: .macosTouchbarZoomEnabled)
        DefaultsReadUIWriteSettingHandler.register(uiAutomationSetSettingProxy: ZoomStyleUIAutomation.self, for: .macosZoomStyle)
    }
}
