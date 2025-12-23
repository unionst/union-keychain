//
//  KeychainProperty.swift
//  UnionKeychain
//
//  Created by Ben Sage on 12/22/24.
//

import Foundation

/// A property wrapper for storing optional string values in the keychain.
///
/// Use `@KeychainString` to automatically persist string properties to the keychain with minimal boilerplate.
///
/// ## Example
/// ```swift
/// class UserSession {
///     @KeychainString(key: "authToken")
///     var authToken: String?
///
///     @KeychainString(key: "refreshToken", service: "com.myapp.tokens")
///     var refreshToken: String?
/// }
///
/// let session = UserSession()
/// session.authToken = "abc123"
/// print(session.authToken)
/// ```
@propertyWrapper
public struct KeychainString {
    private let key: String
    private let service: String
    
    /// Creates a keychain string property wrapper.
    ///
    /// - Parameters:
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to `Keychain.defaultService`.
    public init(key: String, service: String = Keychain.defaultService) {
        self.key = key
        self.service = service
    }
    
    /// The string value stored in the keychain.
    ///
    /// Setting this to `nil` removes the item from the keychain.
    public var wrappedValue: String? {
        get {
            Keychain.getString(forKey: key, service: service)
        }
        set {
            Keychain.setString(newValue, forKey: key, service: service)
        }
    }
}

/// A property wrapper for storing boolean values in the keychain with a fallback default.
///
/// Use `@KeychainBool` to automatically persist boolean properties to the keychain. Unlike `KeychainString`, this wrapper always returns a non-optional boolean using the provided default value when no stored value exists.
///
/// ## Example
/// ```swift
/// class AppSettings {
///     @KeychainBool(key: "isDarkMode", defaultValue: false)
///     var isDarkMode: Bool
///
///     @KeychainBool(key: "hasSeenTutorial", defaultValue: false)
///     var hasSeenTutorial: Bool
///
///     @KeychainBool(key: "isPremium", defaultValue: false, service: "com.myapp.premium")
///     var isPremium: Bool
/// }
///
/// let settings = AppSettings()
/// settings.isDarkMode = true
/// print(settings.isDarkMode)
/// ```
@propertyWrapper
public struct KeychainBool {
    private let key: String
    private let service: String
    private let defaultValue: Bool
    
    /// Creates a keychain boolean property wrapper.
    ///
    /// - Parameters:
    ///   - key: The account identifier for the keychain item.
    ///   - defaultValue: The value to return when no stored value exists. Defaults to `false`.
    ///   - service: The service identifier. Defaults to `Keychain.defaultService`.
    public init(key: String, defaultValue: Bool = false, service: String = Keychain.defaultService) {
        self.key = key
        self.defaultValue = defaultValue
        self.service = service
    }
    
    /// The boolean value stored in the keychain, or the default value if none exists.
    public var wrappedValue: Bool {
        get {
            Keychain.getBool(forKey: key, service: service) ?? defaultValue
        }
        set {
            Keychain.setBool(newValue, forKey: key, service: service)
        }
    }
}

/// A property wrapper for storing optional binary data in the keychain.
///
/// Use `@KeychainData` to automatically persist data properties to the keychain. This is useful for storing images, certificates, or any other binary data.
///
/// ## Example
/// ```swift
/// class UserProfile {
///     @KeychainData(key: "profileImage")
///     var profileImageData: Data?
///
///     @KeychainData(key: "certificate", service: "com.myapp.security")
///     var certificateData: Data?
///
///     var profileImage: UIImage? {
///         get {
///             guard let data = profileImageData else { return nil }
///             return UIImage(data: data)
///         }
///         set {
///             profileImageData = newValue?.pngData()
///         }
///     }
/// }
///
/// let profile = UserProfile()
/// profile.profileImage = UIImage(named: "avatar")
/// ```
@propertyWrapper
public struct KeychainData {
    private let key: String
    private let service: String
    
    /// Creates a keychain data property wrapper.
    ///
    /// - Parameters:
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to `Keychain.defaultService`.
    public init(key: String, service: String = Keychain.defaultService) {
        self.key = key
        self.service = service
    }
    
    /// The binary data stored in the keychain.
    ///
    /// Setting this to `nil` removes the item from the keychain.
    public var wrappedValue: Data? {
        get {
            Keychain.getData(forKey: key, service: service)
        }
        set {
            Keychain.setData(newValue, forKey: key, service: service)
        }
    }
} 