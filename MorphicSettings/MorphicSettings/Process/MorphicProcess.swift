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

// NOTE: the MorphicProcess class contains the functionality used by Obj-C and Swift applications

public class MorphicProcess {
    // MARK: - Process/service restarting functionality
    
    public static func restartViaLaunchctl(serviceNames: [String]) {
        // get the current user's ID
        // NOTE: in future releases of macOS we may need to consider using SCDynamicStoreCopyConsoleUser or other methods
        let userId = getuid()

        for serviceName in serviceNames {
            let domainTarget = "gui/" + String(userId) + "/" + serviceName
            MorphicProcess.restartViaLaunchctl(domainTarget: domainTarget)
        }
    }
    
    public static func restartViaLaunchctl(domainTarget: String) {
         let launchctlProcess = Process()
         launchctlProcess.launchPath = "/bin/launchctl"
         launchctlProcess.arguments = ["kickstart", "-k", domainTarget]
         launchctlProcess.launch()
     }
}
