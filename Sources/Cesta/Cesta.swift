//
//  Cesta.swift
//
//
//  Created by Jonathan Gikabu on 10/10/2023.
//

import UIKit

class Cesta {
    private init() {}
}

extension Cesta {
    static var osVersion: String {
        let device = UIDevice.current
        return "\(device.systemName)-\(device.systemVersion)"
    }
    
    static var appName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "?"
    }
    
    static var appVersion: String {
        return "\(appShortVersion).\(bundleVersion)"
    }
    
    static var appShortVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
    
    static var bundleVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }
}
