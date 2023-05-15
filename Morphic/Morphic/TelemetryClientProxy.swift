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

import Cocoa
import MorphicTelemetry

public class TelemetryClientProxy {
    internal private(set) static var telemetryClient: MorphicTelemetryClient? = nil
    internal private(set) static var telemetrySessionId: String? = nil

    static func configure(telemetryClient: MorphicTelemetryClient, telemetrySessionId: String) {
        self.telemetryClient = telemetryClient
        self.telemetrySessionId = telemetrySessionId
    }

    static func startSession() {
        self.telemetryClient?.startSession()
    }

    static func endSession() {
        self.telemetryClient?.endSession()
    }
    
    static func enqueueActionMessage(eventName: String, data: MorphicTelemetryClient.TelemetryEventData? = nil) {
        if ConfigurableFeatures.shared.telemetryIsEnabled == true {
            self.telemetryClient?.enqueueActionMessage(eventName: eventName, data: data)
        }
    }
}
