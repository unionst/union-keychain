//
//  Keychain.swift
//  UnionKeychain
//
//  Created by Ben Sage on 12/22/24.
//

import Foundation
import Security

/// A type-safe interface for securely storing and retrieving sensitive data using the system keychain.
///
/// `Keychain` is a value type representing a single keychain scope, identified by its `service`. Methods on a `Keychain` instance read and write under that service. Unlike UserDefaults, keychain data persists even when the app is uninstalled and reinstalled.
///
/// For most apps, the static accessors on `Keychain` (which delegate to ``Keychain/default``) are all you need. Apps that share a keychain across an app and its extensions construct their own instance with a stable service name and reference it everywhere.
///
/// ## Default Instance
/// ```swift
/// Keychain.default.bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
///
/// if let token = Keychain.default.bearerToken {
///     headers["Authorization"] = "Bearer \(token)"
/// }
///
/// Keychain.default.setString("john_doe", forKey: "username")
/// if let username = Keychain.default.string(forKey: "username") {
///     print("Welcome back, \(username)")
/// }
/// ```
///
/// ## Static Convenience
/// The static accessors call through to ``Keychain/default``:
/// ```swift
/// Keychain.bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
/// Keychain.setString("on", forKey: "darkMode")
/// ```
///
/// ## Custom Scope (App + Extension Sharing)
/// To share a keychain across an app and its extensions, construct a `Keychain` instance with a stable service name. The targets must also share a `keychain-access-groups` entitlement.
/// ```swift
/// extension Keychain {
///     static let auth = Keychain(service: "com.example.app.auth")
/// }
///
/// // In the main app:
/// Keychain.auth.bearerToken = response.token
///
/// // In a keyboard or share extension:
/// if let token = Keychain.auth.bearerToken {
///     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
/// }
/// ```
///
/// ## Persistent Free Trial Tracking
/// Keychain data survives app uninstalls and reinstalls, making it ideal for tracking free trial usage.
/// ```swift
/// func checkTrialEligibility() {
///     if Keychain.usedFreeAccount {
///         showPaywall()
///     } else {
///         Keychain.usedFreeAccount = true
///         startFreeTrial()
///     }
/// }
/// ```
///
/// ## Property Wrappers
/// ```swift
/// class UserSession {
///     @KeychainString(key: "username")
///     var username: String?
///
///     @KeychainBool(key: "isPremium", defaultValue: false)
///     var isPremium: Bool
///
///     @KeychainData(key: "certificate")
///     var certificate: Data?
/// }
/// ```
///
/// ## Removing Values
/// ```swift
/// Keychain.default.setString(nil, forKey: "apiToken")
/// Keychain.default.setBool(nil, forKey: "isPremium")
/// Keychain.default.remove(forKey: "certificate")
/// ```
public struct Keychain: Sendable {
    /// The service identifier this keychain instance reads and writes under.
    public let service: String

    /// Creates a keychain scoped to a specific service identifier.
    ///
    /// - Parameter service: The service identifier under which items are stored.
    ///
    /// ## Example
    /// ```swift
    /// let auth = Keychain(service: "com.example.app.auth")
    /// auth.bearerToken = "..."
    /// ```
    public init(service: String) {
        self.service = service
    }

    /// The default keychain instance, scoped to the app's bundle identifier.
    ///
    /// Use this for single-target apps that don't need to share keychain data with extensions.
    ///
    /// ## Example
    /// ```swift
    /// Keychain.default.bearerToken = "..."
    /// ```
    public static let `default` = Keychain(service: Bundle.main.bundleIdentifier ?? "com.unionst.service")

    /// A convenience property for storing and retrieving an authentication bearer token under the key "UserAccount".
    ///
    /// ## Example
    /// ```swift
    /// Keychain.default.bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    ///
    /// if let token = Keychain.default.bearerToken {
    ///     headers["Authorization"] = "Bearer \(token)"
    /// }
    /// ```
    public var bearerToken: String? {
        get { string(forKey: "UserAccount") }
        nonmutating set { setString(newValue, forKey: "UserAccount") }
    }

    /// A convenience property for tracking whether the user has consumed their free account, stored under the key "UsedFreeAccount". Defaults to `false` if unset.
    ///
    /// ## Example
    /// ```swift
    /// if !Keychain.default.usedFreeAccount {
    ///     Keychain.default.usedFreeAccount = true
    ///     showFreeTrialWelcome()
    /// }
    /// ```
    public var usedFreeAccount: Bool {
        get { bool(forKey: "UsedFreeAccount") ?? false }
        nonmutating set { setBool(newValue, forKey: "UsedFreeAccount") }
    }

    /// Retrieves a string value from this keychain.
    ///
    /// - Parameter key: The account identifier for the keychain item.
    /// - Returns: The stored string, or `nil` if the item doesn't exist.
    ///
    /// ## Example
    /// ```swift
    /// if let username = Keychain.default.string(forKey: "username") {
    ///     print("Welcome back, \(username)")
    /// }
    /// ```
    public func string(forKey key: String) -> String? {
        guard let data = data(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Stores a string value in this keychain, or removes it if `nil`.
    ///
    /// - Parameters:
    ///   - value: The string to store, or `nil` to remove the item.
    ///   - key: The account identifier for the keychain item.
    /// - Returns: `true` if the operation succeeded.
    ///
    /// ## Example
    /// ```swift
    /// Keychain.default.setString("john_doe", forKey: "username")
    /// Keychain.default.setString(nil, forKey: "username")
    /// ```
    @discardableResult
    public func setString(_ value: String?, forKey key: String) -> Bool {
        guard let value else { return remove(forKey: key) }
        return setData(Data(value.utf8), forKey: key)
    }

    /// Retrieves binary data from this keychain.
    ///
    /// - Parameter key: The account identifier for the keychain item.
    /// - Returns: The stored data, or `nil` if the item doesn't exist.
    ///
    /// ## Example
    /// ```swift
    /// if let imageData = Keychain.default.data(forKey: "profileImage") {
    ///     let image = UIImage(data: imageData)
    /// }
    /// ```
    public func data(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var ref: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &ref)
        return status == errSecSuccess ? (ref as? Data) : nil
    }

    /// Stores binary data in this keychain, or removes it if `nil`.
    ///
    /// - Parameters:
    ///   - value: The data to store, or `nil` to remove the item.
    ///   - key: The account identifier for the keychain item.
    /// - Returns: `true` if the operation succeeded.
    ///
    /// ## Example
    /// ```swift
    /// let certificateData = try Data(contentsOf: certURL)
    /// Keychain.default.setData(certificateData, forKey: "certificate")
    /// Keychain.default.setData(nil, forKey: "certificate")
    /// ```
    @discardableResult
    public func setData(_ value: Data?, forKey key: String) -> Bool {
        guard let value else { return remove(forKey: key) }
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(baseQuery as CFDictionary)
        var attrs = baseQuery
        attrs[kSecValueData as String] = value
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(attrs as CFDictionary, nil) == errSecSuccess
    }

    /// Retrieves a boolean value from this keychain.
    ///
    /// - Parameter key: The account identifier for the keychain item.
    /// - Returns: The stored boolean, or `nil` if the item doesn't exist or is invalid.
    ///
    /// ## Example
    /// ```swift
    /// if Keychain.default.bool(forKey: "isDarkMode") == true {
    ///     enableDarkMode()
    /// }
    /// ```
    public func bool(forKey key: String) -> Bool? {
        guard let s = string(forKey: key) else { return nil }
        if s == "true" { return true }
        if s == "false" { return false }
        return nil
    }

    /// Stores a boolean value in this keychain, or removes it if `nil`.
    ///
    /// - Parameters:
    ///   - value: The boolean to store, or `nil` to remove the item.
    ///   - key: The account identifier for the keychain item.
    /// - Returns: `true` if the operation succeeded.
    ///
    /// ## Example
    /// ```swift
    /// Keychain.default.setBool(true, forKey: "hasAcceptedTerms")
    /// Keychain.default.setBool(nil, forKey: "hasAcceptedTerms")
    /// ```
    @discardableResult
    public func setBool(_ value: Bool?, forKey key: String) -> Bool {
        guard let value else { return remove(forKey: key) }
        return setString(value ? "true" : "false", forKey: key)
    }

    /// Removes any item stored under `key` in this keychain.
    ///
    /// - Parameter key: The account identifier for the keychain item.
    /// - Returns: `true` if an item was removed.
    ///
    /// ## Example
    /// ```swift
    /// Keychain.default.remove(forKey: "apiToken")
    /// ```
    @discardableResult
    public func remove(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}

public extension Keychain {
    /// The service identifier of ``Keychain/default``, retained for callers that referenced the previous static API.
    static var defaultService: String { `default`.service }

    /// A convenience accessor that delegates to ``Keychain/default``'s ``Keychain/bearerToken``.
    static var bearerToken: String? {
        get { `default`.bearerToken }
        set { `default`.bearerToken = newValue }
    }

    /// A convenience accessor that delegates to ``Keychain/default``'s ``Keychain/usedFreeAccount``.
    static var usedFreeAccount: Bool {
        get { `default`.usedFreeAccount }
        set { `default`.usedFreeAccount = newValue }
    }

    /// Retrieves a string value from a keychain.
    ///
    /// - Parameters:
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to ``Keychain/default``'s service.
    /// - Returns: The stored string, or `nil` if the item doesn't exist.
    static func getString(forKey key: String, service: String = `default`.service) -> String? {
        Keychain(service: service).string(forKey: key)
    }

    /// Stores a string value in a keychain, or removes it if `nil`.
    ///
    /// - Parameters:
    ///   - value: The string to store, or `nil` to remove the item.
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to ``Keychain/default``'s service.
    /// - Returns: `true` if the operation succeeded.
    @discardableResult
    static func setString(_ value: String?, forKey key: String, service: String = `default`.service) -> Bool {
        Keychain(service: service).setString(value, forKey: key)
    }

    /// Retrieves binary data from a keychain.
    ///
    /// - Parameters:
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to ``Keychain/default``'s service.
    /// - Returns: The stored data, or `nil` if the item doesn't exist.
    static func getData(forKey key: String, service: String = `default`.service) -> Data? {
        Keychain(service: service).data(forKey: key)
    }

    /// Stores binary data in a keychain, or removes it if `nil`.
    ///
    /// - Parameters:
    ///   - value: The data to store, or `nil` to remove the item.
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to ``Keychain/default``'s service.
    /// - Returns: `true` if the operation succeeded.
    @discardableResult
    static func setData(_ value: Data?, forKey key: String, service: String = `default`.service) -> Bool {
        Keychain(service: service).setData(value, forKey: key)
    }

    /// Retrieves a boolean value from a keychain.
    ///
    /// - Parameters:
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to ``Keychain/default``'s service.
    /// - Returns: The stored boolean, or `nil` if the item doesn't exist or is invalid.
    static func getBool(forKey key: String, service: String = `default`.service) -> Bool? {
        Keychain(service: service).bool(forKey: key)
    }

    /// Stores a boolean value in a keychain, or removes it if `nil`.
    ///
    /// - Parameters:
    ///   - value: The boolean to store, or `nil` to remove the item.
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to ``Keychain/default``'s service.
    /// - Returns: `true` if the operation succeeded.
    @discardableResult
    static func setBool(_ value: Bool?, forKey key: String, service: String = `default`.service) -> Bool {
        Keychain(service: service).setBool(value, forKey: key)
    }
}
