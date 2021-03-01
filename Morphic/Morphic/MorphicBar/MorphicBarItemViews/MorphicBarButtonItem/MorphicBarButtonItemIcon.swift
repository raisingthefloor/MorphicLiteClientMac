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
    case aol = "aolold"
    case box = "box"
    case calendar = "calendar$calendar"
    case cnn = "cnn"
    case comments = "comments"
    case dropbox = "dropbox"
    case envelope = "email$envelope"
    case envelopeOpen = "email$envelopeopen"
    case envelopeOpenText = "email$envelopeopentext"
    case envelopeOutline = "email$envelopeoutline"
    case envelopeOutlineOpen = "email$envelopeoutlineopen"
    case facebook = "facebook"
    case foxnews1 = "faviconfoxnews"
    case foxnews2 = "foxnews"
    case globe = "globe"
    case gmail = "gmail"
    case googleDrive = "googledrive"
    case googleNews = "googlenews"
    case icloud = "icloud"
    case imgur = "imgur"
    case instagram = "instagram"
    case linkedin = "linkedin"
//    case mail = "mail"
    case newspaper = "news$newspaper"
    case newYorkTimes = "newyorktimes"
    case nextdoor = "nextdoor"
    case onedrive = "onedrive"
    case outlook = "outlook"
    case pinterest = "pinterest"
    case reddit = "reddit"
    case skype = "skype"
    case tumblr = "tumblr"
    case twitter = "twitter"
    case washingtonPost = "washingtonpost"
    case window_maximize = "windowmaximize"
    case yahoo = "yahoo"
    case yahooMail = "yahoomail"
    
    var pathToImage: String {
        get {
            let fileName = self.translateImageUrlToFileName(self.rawValue)
            // NOTE: once we add JPG support, uncomment this section (and also the mail entry above and below)
            
/*            if let jpgPath = Bundle.main.path(forResource: fileName, ofType: "jpg") {
//                return jpgPath
//            } else */ if let pdfPath = Bundle.main.path(forResource: fileName, ofType: "pdf") {
                return pdfPath
            } else {
                fatalError("File path to built-in image is invalid")
            }
        }
    }
    
    // NOTE: the image_url values we get back from the v1 API do not always represent the filename, so we need to map them here
    //       in the (very-near-term) future, we must standardize on URLs or another form via the API; manual mapping is not sustainable
    func translateImageUrlToFileName(_ imageUrl: String) -> String {
        switch imageUrl {
        case "aolold":
            return "logo_aolOld"
        case "box":
            return "logo_box"
        case "calendar$calendar":
            return "calendar"
        case "cnn":
            return "logo_cnn"
        case "dropbox":
            return "logo_dropbox"
        case "email$envelope":
            return "envelope"
        case "email$envelopeopen":
            return "envelope_open"
        case "email$envelopeopentext":
            return "envelope_open_text"
        case "email$envelopeoutline":
            return "envelope_outline"
        case "email$envelopeoutlineopen":
            return "envelope_outline_open"
        case "facebook":
            return "logo_facebook"
        case "faviconfoxnews":
            return "favicon_foxNews"
        case "foxnews":
            return "logo_foxNews"
        case "gmail":
            return "logo_gmail"
        case "googledrive":
            return "logo_googleDrive"
        case "googlenews":
            return "logo_googleNews"
        case "icloud":
            return "logo_icloud"
        case "imgur":
            return "logo_imgur"
        case "instagram":
            return "logo_instagram"
        case "linkedin":
            return "logo_linkedIn"
//        case "mail":
//            return "logo_mail"
        case "news$newspaper":
            return "newspaper"
        case "newyorktimes":
            return "logo_newYorkTimes"
        case "nextdoor":
            return "logo_nextdoor"
        case "onedrive":
            return "logo_onedrive"
        case "outlook":
            return "logo_outlook"
        case "pinterest":
            return "logo_pinterest"
        case "reddit":
            return "logo_reddit"
        case "skype":
            return "logo_skype"
        case "twitter":
            return "logo_twitter"
        case "tumblr":
            return "logo_tumblr"
        case "washingtonpost":
            return "logo_washingtonPost"
        case "windowmaximize":
            return "window_maximize"
        case "yahoo":
            return "logo_yahoo"
        case "yahoomail":
            return "logo_yahoomail"
        default:
            return imageUrl
        }
    }
}
