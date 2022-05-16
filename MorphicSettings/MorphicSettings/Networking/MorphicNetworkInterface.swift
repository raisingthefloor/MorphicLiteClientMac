// Copyright 2022 Raising the Floor - US, Inc.
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
import IOKit.network
import MorphicCore

public class MorphicNetworkInterface {
    // NOTE: this function returns null if no primary (built-in) network interface is found
    // NOTE: this code is based off of Apple's example code at: https://developer.apple.com/library/archive/samplecode/GetPrimaryMACAddress/Introduction/Intro.html
    public static func macAddressOfPrimaryNetworkInterface() throws -> [UInt8]? {
        let primaryNetworkInterfaces = try MorphicNetworkInterface.macAddressesOfNetworkInterfaces(limitToPrimaryInterfacesOnly: true)
        if primaryNetworkInterfaces.count > 0 {
            return primaryNetworkInterfaces.first!
        } else {
            return nil
        }
    }

    // NOTE: this function returns null if no network interface is found
    // NOTE: this code is based off of Apple's example code at: https://developer.apple.com/library/archive/samplecode/GetPrimaryMACAddress/Introduction/Intro.html
    public static func macAddressOfFirstNetworkInterface() throws -> [UInt8]? {
        let allNetworkInterfaces = try MorphicNetworkInterface.macAddressesOfNetworkInterfaces(limitToPrimaryInterfacesOnly: false)
        if allNetworkInterfaces.count > 0 {
            return allNetworkInterfaces.first!
        } else {
            return nil
        }
    }
    
    public static func macAddressesOfNetworkInterfaces() throws -> [[UInt8]] {
        return try MorphicNetworkInterface.macAddressesOfNetworkInterfaces(limitToPrimaryInterfacesOnly: false)
    }
    
    // NOTE: this function returns null if no primary (built-in) network interface is found
    // NOTE: this code is based off of Apple's example code at: https://developer.apple.com/library/archive/samplecode/GetPrimaryMACAddress/Introduction/Intro.html
    private static func macAddressesOfNetworkInterfaces(limitToPrimaryInterfacesOnly: Bool) throws -> [[UInt8]] {
        var result = [[UInt8]]()
        
        // create a CFMutableDictionary to match services using the Ethernet interface class
        guard let matchingDictionaryAsCFDictionary = IOServiceMatching(kIOEthernetInterfaceClass) else {
            // if we could not create the matching dictionary, throw an error
            throw MorphicError()
        }
        // NOTE: Swift manages Core Foundation memory for us; in other languages, be sure to CFRelease
//        defer {
//            CFRelease(matchingDictionaryAsCFDictionary)
//        }

        // convert our matching dictionary to an NSMutableDictionary (for ease of use)
        let matchingDictionaryAsNSDictionary = matchingDictionaryAsCFDictionary as NSMutableDictionary
        //
        // if the caller has specified that we filter out the non-primary interfaces, add that property match key to the matching dictionary now
        if limitToPrimaryInterfacesOnly == true {
            // add { kIOPrimaryInterface: true } to our matchingDictionary as its property match key
            matchingDictionaryAsNSDictionary[kIOPropertyMatchKey] = [kIOPrimaryInterface: kCFBooleanTrue]
        }

        // obtain an iterator (to walk through the list of ethernet service kernel objects in the I/O Registry)
        var servicesIterator: io_iterator_t = 0 // NOTE: must be initialized to a value so that Swift can pass by reference
        // NOTE: the IOServiceGetMatchingServices function automatically releases the matching dictionary (so we do not need to CFRelease in non-Swift languages)
        if IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDictionaryAsNSDictionary, &servicesIterator) != KERN_SUCCESS {
            // if we could not get an interface iterator, throw an error
            throw MorphicError()
        }
        defer {
            IOObjectRelease(servicesIterator)
        }

        // iterate through each matching service in the I/O registry (using our interface iterator)
        var networkInterfaceService = IOIteratorNext(servicesIterator)
        while networkInterfaceService != 0 {
            do {
                defer {
                    IOObjectRelease(networkInterfaceService)
                }
                
                // NOTE: the iterator has found the IONetworkInterface, but we must get its parent (the IONetworkController) to capture the MAC address
                
                var networkControllerService: io_object_t = 0
                let getParentEntryResult = IORegistryEntryGetParentEntry(networkInterfaceService, kIOServicePlane, &networkControllerService)
                guard getParentEntryResult == KERN_SUCCESS else {
                    continue
                }
                defer {
                    IOObjectRelease(networkControllerService)
                }
                
                if let macAddressAsCFDataRef = IORegistryEntryCreateCFProperty(networkControllerService, kIOMACAddress as CFString, kCFAllocatorDefault, 0) {
//                    defer {
//                        CFRelease(macAddressAsCFDataRef)
//                    }
                    
                    let macAddressAsCFData = macAddressAsCFDataRef.takeRetainedValue() as! CFData
                    let macAddressAsData = macAddressAsCFData as Data
                    
                    // copy and capture the MAC Address as an array of bytes
                    var macAddressAsBytes = [UInt8](repeating: 0, count: Int(kIOEthernetAddressSize))
                    macAddressAsData.copyBytes(to: &macAddressAsBytes, count: macAddressAsBytes.count)
                    result.append(macAddressAsBytes)
                }
            }
            
            networkInterfaceService = IOIteratorNext(servicesIterator)
        }

        return result
    }
    
}

