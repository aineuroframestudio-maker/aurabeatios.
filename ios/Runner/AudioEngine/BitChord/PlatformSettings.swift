//
//  PlatformSettings.swift
//  Runner
//
//  BitChord 1.0.8 — Platform Settings & UserDefaults Bridge
//

import Foundation

@objc public final class PlatformSettings: NSObject {
    @objc public static let shared = PlatformSettings()
    private let defaults = UserDefaults.standard

    public func getBoolean(key: String, default defaultValue: Bool = false) -> Bool {
        return defaults.object(forKey: key) != nil ? defaults.bool(forKey: key) : defaultValue
    }

    public func putBoolean(key: String, value: Bool) {
        defaults.set(value, forKey: key)
    }

    public func getString(key: String, default defaultValue: String = "") -> String {
        return defaults.string(forKey: key) ?? defaultValue
    }

    public func putString(key: String, value: String) {
        defaults.set(value, forKey: key)
    }

    public func getInt(key: String, default defaultValue: Int32 = 0) -> Int32 {
        return defaults.object(forKey: key) != nil ? Int32(defaults.integer(forKey: key)) : defaultValue
    }

    public func putInt(key: String, value: Int32) {
        defaults.set(Int(value), forKey: key)
    }

    public func getLong(key: String, default defaultValue: Int64 = 0) -> Int64 {
        if let val = defaults.object(forKey: key) as? NSNumber {
            return val.int64Value
        }
        return defaultValue
    }

    public func putLong(key: String, value: Int64) {
        defaults.set(NSNumber(value: value), forKey: key)
    }

    public func getFloat(key: String, default defaultValue: Float = 0.0) -> Float {
        return defaults.object(forKey: key) != nil ? defaults.float(forKey: key) : defaultValue
    }

    public func putFloat(key: String, value: Float) {
        defaults.set(value, forKey: key)
    }

    public func getSecret(key: String) -> String? {
        return defaults.string(forKey: "secret_\(key)")
    }
}
