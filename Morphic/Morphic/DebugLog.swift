// Copyright 2023 Raising the Floor - US, Inc.
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

struct MorphicDebugLog {
    static func writeToDebugLog(_ text: String) {
        let text = String(format: "%.2f", Date().timeIntervalSince1970) + " | " + text + "\n"
        
        guard let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("ERROR: COULD NOT GET APPLICATION SUPPORT DIRECTORY")
            return
        }
        
        let pathAsUrl = applicationSupportDirectory.appendingPathComponent("morphic_debug.log")
        guard let fileHandle = try? FileHandle(forWritingTo: pathAsUrl) else {
            do {
                print("ERROR: COULD NOT GET A FILE HANDLE TO THE DEBUG LOG; WRITING A NEW FILE INSTEAD")
                try text.write(to: pathAsUrl, atomically: true, encoding: .utf8)
            } catch {
                print("ERROR: COULD NOT GET A FILE HANDLE TO THE DEBUG LOG, AND ALSO COULD NOT WRITE OUT A NEW FILE")
            }
            return
        }

        defer {
            do {
                try fileHandle.close()
            } catch {
                print("ERROR: COULD NOT CLOSE FILE HANDLE")
            }
        }
        
        if #available(macOS 10.15.4, *) {
            guard let _ = try? fileHandle.seekToEnd() else {
                print("ERROR: COULD NOT SEEK TO END OF FILE")
                return
            }
        } else {
            // Fallback on earlier versions
            let currentData = fileHandle.readDataToEndOfFile()
            fileHandle.write(currentData)
        }
        fileHandle.write(text.data(using: .utf8)!)
    }
}
