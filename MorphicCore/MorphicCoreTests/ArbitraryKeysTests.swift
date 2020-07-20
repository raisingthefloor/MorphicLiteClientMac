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
//  ArbitraryKeysTests.swift
//  MorphicCoreTests
//
//  Created by Joseph on 2020-07-17.

import XCTest
@testable import MorphicCore

class ArbitraryKeysTests: XCTestCase {
    
    var aKeyGivenInt: ArbitraryKeys!
    var aKeyGivenString: ArbitraryKeys!
    
    let testInt = 42
    let testString = "stringKey"

    override func setUpWithError() throws {
        try super.setUpWithError()
        aKeyGivenInt = ArbitraryKeys(intValue: testInt)
        aKeyGivenString = ArbitraryKeys(stringValue: testString)
    }
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        aKeyGivenInt = nil
        aKeyGivenString = nil
    }

    func testInits() throws {
        XCTAssert(aKeyGivenInt.intValue == testInt, "ArbitraryKey created with integer")
        XCTAssert(aKeyGivenString.stringValue == testString, "Arbitrary key created with string")
    }
}
