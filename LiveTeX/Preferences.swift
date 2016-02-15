//
//  Preferences.swift
//  LiveTeX
//
//  Created by Katsuma Tanaka on 2016/02/12.
//  Copyright (c) 2016 Katsuma Tanaka. All rights reserved.
//

import Foundation

class Preferences {
    
    // MARK: - Properties
    
    static let sharedInstance = Preferences()
    
    private let userDefaults = NSUserDefaults.standardUserDefaults()
    
    
    // MARK: - Initializers
    
    private init() {
        // Register defaults
        userDefaults.registerDefaults([
            "autoTypesettingEnabled": false,
            "autoTypesettingDelay": 2.0,
            "script": "platex -halt-on-error {filename}.tex\ndvipdfmx -r 2400 -z 0 {filename}.dvi"
        ])
    }
    
    
    // MARK: - Preferences
    
    var autoTypesettingEnabled: Bool {
        get {
            return userDefaults.boolForKey("autoTypesettingEnabled")
        }
        
        set {
            userDefaults.setBool(newValue, forKey: "autoTypesettingEnabled")
            userDefaults.synchronize()
        }
    }
    
    var autoTypesettingDelay: NSTimeInterval {
        get {
            return userDefaults.doubleForKey("autoTypesettingDelay")
        }
        
        set {
            userDefaults.setDouble(newValue, forKey: "autoTypesettingDelay")
            userDefaults.synchronize()
        }
    }
    
    var script: String {
        get {
            if let script = userDefaults.stringForKey("script") {
                return script
            } else {
                return ""
            }
        }
        
        set {
            userDefaults.setObject(newValue, forKey: "script")
            userDefaults.synchronize()
        }
    }
    
}
