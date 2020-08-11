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
//  UserTests.swift
//  MorphicCoreTests

import XCTest
@testable import MorphicCore

class UserTests: XCTestCase {

    var freshNewUser: User!
    var knownUserNoPrefs: User!
    var userFromJson: User!
    var userToEncode: User!
    let identifierString = UUID().uuidString
    let userAsJsonString = """
    {
        "id": "12345678-1234-4321-6789-123456789ABC",
        "preferences_id": "87654321-1234-4321-6789-123456789ABC",
        "first_name": "Pat",
        "last_name": "Jones",
        "email": "pjones@somewhere.com"
    }
    """

    override func setUpWithError() throws {
        try super.setUpWithError()

        freshNewUser = User()
        knownUserNoPrefs = User(identifier: identifierString)

        let userAsJsonData = userAsJsonString.data(using: .utf8)
        userFromJson = try JSONDecoder().decode(User.self, from: userAsJsonData!)
        // userFromJson = User(

        userToEncode = User(identifier: "12345678-1234-4321-6789-123456789ABC")
        userToEncode.firstName = "Sandy"
        userToEncode.lastName = "Smith"
        userToEncode.email = "sandys@thebeach.com"
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        freshNewUser = nil
        knownUserNoPrefs = nil
        userFromJson = nil
        userToEncode = nil
    }

    func testInits() throws {
        XCTAssert((UUID(uuidString: freshNewUser.identifier) != nil) && (UUID(uuidString: freshNewUser.preferencesId) != nil), "Create new User")

        XCTAssert((UUID(uuidString: knownUserNoPrefs.identifier) != nil) && knownUserNoPrefs.preferencesId == nil, "Create User with identifier only")
        
        // test init(from: decoder)
        let msg = "User decoded from JSON"
        XCTAssert(UUID(uuidString: userFromJson.identifier) != nil, msg + " identifier")
        XCTAssert(UUID(uuidString: userFromJson.preferencesId) != nil, msg + " preferencesId")
        XCTAssert(userFromJson.firstName != nil, msg + " firstName")
        XCTAssert(userFromJson.lastName != nil, msg + " lastName")
        XCTAssert(userFromJson.email != nil, msg + " email")
    }

    func testEncode() throws {
        let jsonData = try JSONEncoder().encode(userToEncode)
        let decodedUser = try JSONDecoder().decode(User.self, from: jsonData)
        let msg = "User encode(),"
        XCTAssert(userToEncode.identifier == decodedUser.identifier, msg + " identifier")
        XCTAssert(userToEncode.preferencesId == decodedUser.preferencesId, msg + " preferencesId")
        XCTAssert(userToEncode.firstName == decodedUser.firstName, msg + " firstName")
        XCTAssert(userToEncode.lastName == decodedUser.lastName, msg + " lastName")
        XCTAssert(userToEncode.email == decodedUser.email, msg + " email")
    }
}
