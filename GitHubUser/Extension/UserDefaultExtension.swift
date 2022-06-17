//
//  UserDefaultExtension.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import Foundation

public extension UserDefaults {
    static func get<T>(_ key: String) -> T? {
        return UserDefaults.standard.object(forKey: key) as? T
    }
    
    static func set(_ object: AnyClass?, _ key: String) {
        UserDefaults.standard.setValue(object, forKey: key)
    }
    
    static func setValue(_ value: Any?, _ key: String) {
        if let _value = value {
            UserDefaults.standard.setValue(_value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    static func getValue(_ key: String) -> Any? {
        return UserDefaults.standard.value(forKey: key)
    }
    
    static func clear(_ key: String) {
        UserDefaults.set(nil, key)
    }
}

