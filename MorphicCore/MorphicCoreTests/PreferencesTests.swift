// Copyright 2020 Raising the Floor - International
// Copyright 2020 OCAD University
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
//
//  PreferencesTests.swift
//  MorphicCoreTests
//
//  Created by Joseph on 2020-07-20.

import XCTest
@testable import MorphicCore

class PreferencesTests: XCTestCase {

    var carlaPrefs: Preferences!

    var magFactorKey: Preferences.Key!
    let magnifierName = "Magnifier"
    let magFactorPref = "magfactor"
    let magFactorVal: Double = 2.0

    var inverseVideoKey: Preferences.Key!
    let inverseVideoPref = "inverse_video"
    let inverseVideoVal: Bool = true

    let prefsId = UUID().uuidString
    let carlaId = UUID().uuidString

    override func setUpWithError() throws {
        carlaPrefs = Preferences(identifier: prefsId)
        magFactorKey = Preferences.Key(solution: magnifierName, preference: magFactorPref)
        inverseVideoKey = Preferences.Key(solution: magnifierName, preference: inverseVideoPref)
    }

    override func tearDownWithError() throws {
        carlaPrefs = nil
        magFactorKey = nil
        inverseVideoKey = nil
    }

    func testSetGet() {
        carlaPrefs.set(nil, for: magFactorKey)
        XCTAssertNil(carlaPrefs.get(key: magFactorKey), "Test set()/get() with magnification factor of nil")

        carlaPrefs.set(magFactorVal, for: magFactorKey)
        XCTAssertEqual(magFactorVal, carlaPrefs.get(key: magFactorKey) as! Double, "Test set()/get() with magnification factor")

        carlaPrefs.set(inverseVideoVal, for: inverseVideoKey)
        XCTAssertEqual(inverseVideoVal, carlaPrefs.get(key: inverseVideoKey) as! Bool, "Test set()/get() with inverse video")
    }

    func testRemove() {
        // Check that there is no magnification factor, then initialize it, confirm
        // it is set, and then remove it.
        XCTAssertNil(carlaPrefs.get(key: magFactorKey), "Magnification factor nil before set()")

        carlaPrefs.set(magFactorVal, for: magFactorKey)
        XCTAssertNotNil(carlaPrefs.get(key: magFactorKey), "Magnification factor initialized to non-nil")

        carlaPrefs.remove(key: magFactorKey)
        XCTAssertNil(carlaPrefs.get(key: magFactorKey), "Magnification factor nil after remove()")
    }

    func testKeyValueTuples() {
        // At start, there should be no preferences
        var prefsTuples = carlaPrefs.keyValueTuples()
        XCTAssert(0 == prefsTuples.count, "Check for zero preferences")

        // Add two preferences
        carlaPrefs.set(magFactorVal, for: magFactorKey)
        carlaPrefs.set(inverseVideoVal, for: inverseVideoKey)

        // Check that the preferences were added
        prefsTuples = carlaPrefs.keyValueTuples()
        XCTAssert(2 == prefsTuples.count, "Check for two preferences")
        XCTAssertTrue(containsTuple(magFactorKey, magFactorVal, prefsTuples), "Check presence of magnification factor preference")
        XCTAssertTrue(containsTuple(inverseVideoKey, inverseVideoVal, prefsTuples), "Check presence of inverse video preference")
    }

    func containsTuple(_ aKey: Preferences.Key, _ aValue: Interoperable, _ tuplesArray: [ (Preferences.Key, Interoperable?)]) -> Bool {
        for (key, val) in tuplesArray {
            if ((aKey.solution == key.solution) &&
                (aKey.preference == key.preference) &&
                // Find a way to compare the actual values.
                (aValue != nil && val != nil)) {
                return true
            }
        }
        return false
    }
}
