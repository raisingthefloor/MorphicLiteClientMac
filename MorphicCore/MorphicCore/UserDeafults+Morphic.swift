//
//  UserDeafults+Morphic.swift
//  MorphicCore
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public extension UserDefaults {
    static var morphic = UserDefaults(suiteName: "org.raisingthefloor.MorphicLite")!
    
    func morphicUsername(for userIdentifier: String) -> String?{
        let usernamesByIdentifier = dictionary(forKey: .morphicDefaultsKeyUsernamesByIdentifier)
        return usernamesByIdentifier?[userIdentifier] as? String
    }
    
    func set(morphicUsername: String, for userIdentifier: String){
        var usernamesByIdentifier = dictionary(forKey: .morphicDefaultsKeyUsernamesByIdentifier) ?? [String: Any]()
        usernamesByIdentifier[userIdentifier] = morphicUsername
        setValue(usernamesByIdentifier, forKey: .morphicDefaultsKeyUsernamesByIdentifier)
    }
}

public extension String{
    static var morphicDefaultsKeyUserIdentifier = "userIdentifier"
    static var morphicDefaultsKeyUsernamesByIdentifier = "usernamesByIdentifier"
}
