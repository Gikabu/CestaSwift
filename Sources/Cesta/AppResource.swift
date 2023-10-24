//
//  AppResource.swift
//
//
//  Created by Jonathan Gikabu on 10/10/2023.
//

import UIKit

public class AppResource {
    private init() {}
}

public extension AppResource {
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
    
    static let AVATAR_ALBUM = "Album/avatar/"
    static let IMAGE_ALBUM = "Album/image/"
    static let VIDEO_ALBUM = "Album/video/"
    static let AUDIO_DIR = "General/audio/"
    static let DOCUMENTS_DIR = "General/files/"
    static let THUMBNAIL_DIR = "General/thumb/"
    static let APP_GROUP_DIR = "AppGroup/shared/"
}
