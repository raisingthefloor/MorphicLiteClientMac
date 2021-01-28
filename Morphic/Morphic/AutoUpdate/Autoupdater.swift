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

internal struct Autoupdater {
    private static var updateAvailableWindow: UpdateAvailableWindow!
    
    internal static func startCheckingForUpdates(url: URL) {
        AppcastXmlDownloaderParser.requestAppcastXmlFile(url) {
            version, url, error in
            //
            guard error == nil else {
                // error; abort and we'll try again the next time
                return
            }

            guard let version = version,
                  let url = url else {
                // error; abort and we'll try again the next time
                return
            }

            // compare version to our current version
            guard let currentVersion = self.compositeVersion() else {
                assertionFailure("Could not create composite version tag")
                return
            }
            guard let comparisonResult = Autoupdater.compareVersions(version, currentVersion) else {
                // error (generally in string formatting); abort and we'll try again the next time
                return
            }
            
            if comparisonResult != .greaterThan {
                // no update required
                return
            }
            
            // a new version is available
            DispatchQueue.main.async {
                // prompt the user (with the version # and with a button to download the download link)
                let updateAvailableWindow = UpdateAvailableWindow()
                updateAvailableWindow.currentVersionAsString = currentVersion
                updateAvailableWindow.updatedVersionAsString = version
                updateAvailableWindow.downloadUrl = url
                Autoupdater.updateAvailableWindow = updateAvailableWindow
                //
                Autoupdater.updateAvailableWindow.showWindow(nil)
            }
        }
    }
    
    // TODO: consider moving this logic (and the version comparison functions) to a discrete class (since they might be used elsewhere in the app)
    internal static func compositeVersion() -> String? {
        // create a composite tag indicating the version of this build of our software (to match the version #s used by the autoupdate files)
        
        // version # (major.minor)
        guard let shortVersionAsString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }
        // build # (build.revision...which the build pipelines treat as minor.patch)
        guard let buildAsString = Bundle.main.infoDictionary?["CFBundleVersion" as String] as? String else {
            return nil
        }

        // capture the major version for the version #
        guard let majorVersionAsString = shortVersionAsString.split(separator: ".").first else {
            return nil
        }
        
        return majorVersionAsString + "." + buildAsString
    }
    
    private enum CompareVersionResult {
        case lessThan
        case greaterThan
        case equals
    }
    private static func compareVersions(_ lhs: String, _ rhs: String) -> CompareVersionResult? {
        let lhsComponents = lhs.split(separator: ".")
        guard lhsComponents.count > 0 else {
            return nil
        }
        let rhsComponents = rhs.split(separator: ".")
        guard rhsComponents.count > 0 else {
            return nil
        }

        var lhsComponentsAsInts: [Int] = []
        for lhsComponent in lhsComponents {
            guard let componentAsInt = Int(lhsComponent) else {
                // invalid (non-numeric) component
                return nil
            }
            lhsComponentsAsInts.append(componentAsInt)
        }
        //
        var rhsComponentsAsInts: [Int] = []
        for rhsComponent in rhsComponents {
            guard let componentAsInt = Int(rhsComponent) else {
                // invalid (non-numeric) component
                return nil
            }
            rhsComponentsAsInts.append(componentAsInt)
        }
        
        let numberOfComponentsToCompare = max(lhsComponentsAsInts.count, rhsComponentsAsInts.count)
        
        for index in 0..<numberOfComponentsToCompare {
            let lhsInt = lhsComponentsAsInts.count > index ? lhsComponentsAsInts[index] : 0
            let rhsInt = rhsComponentsAsInts.count > index ? rhsComponentsAsInts[index] : 0
            
            if lhsInt > rhsInt {
                return .greaterThan
            } else if lhsInt < rhsInt {
                return .lessThan
            }
        }
        
        // if all of the components matched, the version #s are equal
        return .equals
    }
}

fileprivate class AppcastXmlDownloaderParser: NSObject, XMLParserDelegate {
    var version: String?
    var url: URL?
    
    var inXmlElement: Bool = false
    var xmlElementContents: String? = nil
    
    public static func requestAppcastXmlFile(_ url: URL, completionHandler: @escaping (_ version: String?, _ url: URL?, _ error: Error?) -> Void) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        let downloadAppcastXmlTask = URLSession.shared.dataTask(with: urlRequest) {
            data, response, error in
            //
            guard error == nil else {
                // error; abort and we'll try again the next time
                completionHandler(nil, nil, error)
                return
            }
            let httpStatusCode = (response as? HTTPURLResponse)?.statusCode
            guard httpStatusCode == 200 else {
                // error; abort and we'll try again the next time
                // NOTE: we return a dummy NSError but would prefer to return a URLError wrapping the HTTP status code
                completionHandler(nil, nil, NSError())
                return
            }
            guard let data = data else {
                // error; abort and we'll try again the next time
                // NOTE: we return a dummy NSError but would prefer to return a URLError wrapping the HTTP status code
                completionHandler(nil, nil, NSError())
                return
            }
            
            let xmlParser = XMLParser(data: data)
            let xmlParserDelegate = AppcastXmlDownloaderParser()
            xmlParser.delegate = xmlParserDelegate
            //
            let parseSuccess = xmlParser.parse()
            guard parseSuccess == true else {
                // error; abort and we'll try again the next time
                // NOTE: we return a dummy NSError but would prefer to return a URLError wrapping the HTTP status code
                completionHandler(nil, nil, NSError())
                return
            }
            //
            DispatchQueue.main.async {
                completionHandler(xmlParserDelegate.version, xmlParserDelegate.url, xmlParser.parserError)
            }
        }
        downloadAppcastXmlTask.resume()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        self.inXmlElement = true

        // prepare to store any contents of this xml element
        self.xmlElementContents = nil
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        self.inXmlElement = false
        
        let whitespaceTrimCharacters: CharacterSet = [" ", "\r", "\n", "\t"]
        
        // capture any contents which were inside the XML element
        switch elementName {
        case "version":
            self.version = self.xmlElementContents?.trimmingCharacters(in: whitespaceTrimCharacters)
        case "url":
            if let urlAsString = self.xmlElementContents?.trimmingCharacters(in: whitespaceTrimCharacters) {
                self.url = URL(string: urlAsString)
            }
        default:
            // nothing to do
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if self.inXmlElement == true {
            // capture the contents inside the current XML Element
            self.xmlElementContents = string
        }
    }
}
