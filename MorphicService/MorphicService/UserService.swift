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
import MorphicCore

/// Interface to the remote Morphic preferences server
public extension Service{
    
    // MARK: - Requests
    
    /// Fetch the preferences for the given user
    ///
    /// - parameters:
    ///   - user: The user's identifier
    ///   - completion: The block to call when the task has loaded
    ///   - user: The user, if the load was successful
    /// - returns: The URL session task that is making the remote request for user data
    func fetch(user identifier: String, completion: @escaping (_ user: User?) -> Void) -> Session.Task{
        let request = URLRequest(session: session, path: "users/\(identifier)", method: .get)
        return session.runningTask(with: request, completion: completion)
    }
    
    /// Save the preferences for the given user
    ///
    /// - parameters:
    ///   - preferences: The user to save
    ///   - user: The user to save
    ///   - completion: The block to call when the task has loaded
    ///   - success: Whether the save request succeeded
    /// - returns: The URL session task that is making the remote request for user data
    func save(_ user: User, completion: @escaping (_ success: Bool) -> Void) -> Session.Task{
        let request = URLRequest(session: session, path: "preferences/\(user.identifier)", method: .put, body: user)
        return session.runningTask(with: request, completion: completion)
    }
    
}
