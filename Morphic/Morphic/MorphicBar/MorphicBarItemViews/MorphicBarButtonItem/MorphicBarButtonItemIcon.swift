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

enum MorphicBarButtonItemIcon: String {
    case calendar = "calendar$calendar"
    case comments = "comments"
    case envelope_open = "email$envelopeopen"
    case envelope_open_text = "email$envelopeopentext"
    case envelope_outline = "email$envelopeoutline"
    case envelope_outline_open = "email$envelopeoutlineopen"
    case globe = "globe"
    
    var pathToImage: String {
        get {
            let fileName = self.translateImageUrlToFileName(self.rawValue)
            return Bundle.main.path(forResource: fileName, ofType: "pdf")!
        }
    }
    
    // NOTE: the image_url values we get back from the v1 API do not always represent the filename, so we need to map them here
    func translateImageUrlToFileName(_ imageUrl: String) -> String {
        switch imageUrl {
        case "calendar$calendar":
            return "calendar"
        case "email$envelopeopen":
            return "envelope_open"
        case "email$envelopeopentext":
            return "envelope_open_text"
        case "email$envelopeoutline":
            return "envelope_outline"
        case "email$envelopeoutlineopen":
            return "envelope_outline_open"
        default:
            return imageUrl
        }
    }
}
