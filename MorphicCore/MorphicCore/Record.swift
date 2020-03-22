//
//  Record.swift
//  MorphicCore
//
//  Created by Owen Shaw on 3/19/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public protocol Record {
    static var typeName: String { get }
    var identifier: String { get }
}
