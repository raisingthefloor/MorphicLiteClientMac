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
    case amazon = "amazon"
    case calendar = "calendar"
    case camera = "camera"
    case comment = "comment"
    case envelope = "envelope"
    case google = "google"
    case googleDrive = "google-drive"
    case images = "images"
    case link = "link"
    case music = "music"
    case newspaper = "newspaper"
    case question = "question"
    case shoppingCart = "shopping-cart"
    case skype = "skype"
    case video = "video"
    
    var pathToImage: String {
        get {
            switch self {
            case .amazon:
                return Bundle.main.path(forResource: "amazon-brands", ofType: "pdf")!
            case .calendar:
                return Bundle.main.path(forResource: "calendar-solid", ofType: "pdf")!
            case .camera:
                return Bundle.main.path(forResource: "camera-solid", ofType: "pdf")!
            case .comment:
                return Bundle.main.path(forResource: "comment-solid", ofType: "pdf")!
            case .envelope:
                return Bundle.main.path(forResource: "envelope-solid", ofType: "pdf")!
            case .google:
                return Bundle.main.path(forResource: "google-brands", ofType: "pdf")!
            case .googleDrive:
                return Bundle.main.path(forResource: "google-drive-brands", ofType: "pdf")!
            case .images:
                return Bundle.main.path(forResource: "images-solid", ofType: "pdf")!
            case .link:
                return Bundle.main.path(forResource: "link-solid", ofType: "pdf")!
            case .music:
                return Bundle.main.path(forResource: "music-solid", ofType: "pdf")!
            case .newspaper:
                return Bundle.main.path(forResource: "newspaper-solid", ofType: "pdf")!
            case .question:
                return Bundle.main.path(forResource: "question-solid", ofType: "pdf")!
            case .shoppingCart:
                return Bundle.main.path(forResource: "shopping-cart-solid", ofType: "pdf")!
            case .skype:
                return Bundle.main.path(forResource: "skype-brands", ofType: "pdf")!
            case .video:
                return Bundle.main.path(forResource: "video-solid", ofType: "pdf")!
            }
        }
    }
}
