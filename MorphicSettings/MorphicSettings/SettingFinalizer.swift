//
//  SettingFinalizer.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/23/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore

/// A setting finalizer runs once at the end of an `ApplySession` to perform an operation needed by one or more settings.
///
/// For example, a finalizer might be used to restart a process or perform a system call that refreshes some
/// UI components.  Rather than do this operation after each setting changes, finalizers provide a way to
/// perform the operation only once after all the settings have been updated.
public class SettingFinalizer{
    
    /// Create a finalizer from the given description
    public required init(description: SettingFinalizerDescription){
        self.description = description
    }
    
    public let description: SettingFinalizerDescription
    
    /// Run the finalizer's operation
    public func run(completion: @escaping (_ success: Bool) -> Void){
        completion(false)
    }
    
    public static func create(from description: SettingFinalizerDescription) -> SettingFinalizer?{
        switch description.type{
        case .notImplemented:
            return nil
        }
    }
    
}

/// A data model describing the finalizer's behavior
public protocol SettingFinalizerDescription{
    
    var type: Setting.FinalizerType { get }
    
    var uniqueRepresentation: String { get }
    
}
