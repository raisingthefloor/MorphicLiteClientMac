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
//  StorageTests.swift
//  MorphicCoreTests
//
//  Created by Joseph on 2020-07-23.

import XCTest
@testable import MorphicCore

class StorageTests: XCTestCase {

    public private(set) var storage = Storage.shared

    var prefsToStore: Preferences!
    let prefsId = UUID().uuidString
    let userId = UUID().uuidString

    let magnifierName = "Magnifier"
    let magFactorPref = "magfactor"
    let magFactorVal: Double = 2.5
    let magFactorKey = Preferences.Key(solution: "Magnifier", preference: "magFactor")

    let inverseVideoPref = "inverse_video"
    let inverseVideoVal: Bool = true
    let inverseVideoKey = Preferences.Key(solution: "Magnifier", preference: "inverse_video")

    override func setUpWithError() throws {
        prefsToStore = Preferences(identifier: prefsId)
        prefsToStore.userId = userId
        prefsToStore.set(magFactorVal, for: magFactorKey)
        prefsToStore.set(inverseVideoVal, for: inverseVideoKey)
    }

    override func tearDownWithError() throws {
        prefsToStore.remove(key: magFactorKey)      // necessary?
        prefsToStore.remove(key: inverseVideoKey)   // necessary?
        prefsToStore = nil
    }

    func testSaveLoad() {
        storage.save(record: prefsToStore, completion: runLoadTest)
    }

    func runLoadTest(_ saveSuccessful: Bool) {
        XCTAssertTrue(saveSuccessful, "Test storing preferences")
        storage.load(identifier: prefsId, completion: checkLoadedPrefs)
    }

    func checkLoadedPrefs(_ actual: Preferences?) {
        if actual != nil {
            XCTAssertEqual(actual!.userId, userId, "Test loaded preferences user id")
            let loadedMagFactor: Double = actual!.get(key: magFactorKey) as! Double
            XCTAssertEqual(loadedMagFactor, magFactorVal, "Test loaded magnification factor")
            let loadedInverseVideo: Bool = actual!.get(key: inverseVideoKey) as! Bool
            XCTAssertEqual(loadedInverseVideo, inverseVideoVal, "Test loaded inverse video")
        } else {
            XCTFail("Test loading preferences: failed to load")
        }
    }

    func testContains() {
        storage.save(record: prefsToStore, completion: checkContains)
    }

    func checkContains(_ succeeded: Bool) {
        if succeeded {
            XCTAssertTrue(storage.contains(identifier: prefsId, type: Preferences.self), "Test store contains known preferences")
        } else {
            XCTFail("Test store for known preferences: failure to save preferences")
        }
    }
}
