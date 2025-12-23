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
/// `Keychain` provides methods for storing strings, booleans, and binary data, along with convenient property wrappers for declarative storage and built-in properties for common use cases like authentication tokens. Unlike UserDefaults, keychain data persists even when the app is uninstalled and reinstalled.
///
/// ## Basic Storage
/// ```swift
/// Keychain.setString("secret_token", forKey: "apiToken")
/// if let token = Keychain.getString(forKey: "apiToken") {
///     print("Token: \(token)")
/// }
///
/// Keychain.setBool(true, forKey: "hasCompletedOnboarding")
/// if Keychain.getBool(forKey: "hasCompletedOnboarding") == true {
///     showMainInterface()
/// }
///
/// let imageData = UIImage(named: "avatar")?.jpegData(compressionQuality: 0.8)
/// Keychain.setData(imageData, forKey: "profileImage")
/// if let data = Keychain.getData(forKey: "profileImage") {
///     let image = UIImage(data: data)
/// }
/// ```
///
/// ## Convenience Properties
/// ```swift
/// Keychain.bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
/// 
/// if let token = Keychain.bearerToken {
///     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
/// }
///
/// if !Keychain.usedFreeAccount {
///     Keychain.usedFreeAccount = true
///     presentFreeTrial()
/// }
/// ```
///
/// ## Persistent Free Trial Tracking
///
/// Keychain data survives app uninstalls and reinstalls, making it ideal for tracking free trial usage.
///
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
///
/// let session = UserSession()
/// session.username = "john_doe"
/// session.isPremium = true
/// ```
///
/// ## Custom Service Names
/// ```swift
/// Keychain.setString("value", forKey: "key", service: "com.myapp.custom")
/// let value = Keychain.getString(forKey: "key", service: "com.myapp.custom")
/// ```
///
/// ## Removing Values
/// ```swift
/// Keychain.setString(nil, forKey: "apiToken")
/// Keychain.setBool(nil, forKey: "isPremium")
/// Keychain.setData(nil, forKey: "certificate")
/// ```
public enum Keychain {
    /// The default service identifier used for keychain items.
    ///
    /// This property uses the app's bundle identifier by default. You can override it to customize the keychain service name for your app.
    ///
    /// ## Example
    /// ```swift
    /// print(Keychain.defaultService)
    /// ```
    public static let defaultService = Bundle.main.bundleIdentifier ?? "com.unionst.service"
    
    /// A convenience property for storing and retrieving an authentication bearer token.
    ///
    /// This property provides quick access to a commonly-used authentication token stored under the key "UserAccount".
    ///
    /// ## Example
    /// ```swift
    /// Keychain.bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    ///
    /// if let token = Keychain.bearerToken {
    ///     headers["Authorization"] = "Bearer \(token)"
    /// }
    /// ```
    public static var bearerToken: String? {
        get { getString(forKey: "UserAccount") }
        set { setString(newValue, forKey: "UserAccount") }
    }
    
    /// A convenience property for tracking whether the user has consumed their free account.
    ///
    /// This boolean property is stored under the key "UsedFreeAccount" and defaults to `false` if not set.
    ///
    /// ## Example
    /// ```swift
    /// if !Keychain.usedFreeAccount {
    ///     Keychain.usedFreeAccount = true
    ///     showFreeTrialWelcome()
    /// }
    /// ```
    public static var usedFreeAccount: Bool {
        get { 
            guard let value = getString(forKey: "UsedFreeAccount"),
                  let bool = Bool(value) else {
                return false
            }
            return bool
        }
        set {
            let value = newValue ? "true" : "false"
            if !setString(value, forKey: "UsedFreeAccount") {
                print("Failed to save usedFreeAccount to Keychain.")
            }
        }
    }
    
    /// Retrieves a string value from the keychain.
    ///
    /// - Parameters:
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to `defaultService`.
    /// - Returns: The stored string value, or `nil` if the item doesn't exist.
    ///
    /// ## Example
    /// ```swift
    /// if let username = Keychain.getString(forKey: "username") {
    ///     print("Welcome back, \(username)")
    /// }
    /// ```
    public static func getString(forKey key: String, service: String = defaultService) -> String? {
        fetch(service: service, account: key)
    }
    
    /// Stores a string value in the keychain, or removes it if `nil`.
    ///
    /// - Parameters:
    ///   - value: The string to store, or `nil` to remove the item.
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to `defaultService`.
    /// - Returns: `true` if the operation succeeded, `false` otherwise.
    ///
    /// ## Example
    /// ```swift
    /// let success = Keychain.setString("john_doe", forKey: "username")
    /// if success {
    ///     print("Username saved successfully")
    /// }
    ///
    /// Keychain.setString(nil, forKey: "username")
    /// ```
    @discardableResult
    public static func setString(_ value: String?, forKey key: String, service: String = defaultService) -> Bool {
        guard let value else {
            return remove(service: service, account: key)
        }
        return save(service: service, account: key, token: value)
    }
    
    /// Retrieves binary data from the keychain.
    ///
    /// - Parameters:
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to `defaultService`.
    /// - Returns: The stored data, or `nil` if the item doesn't exist.
    ///
    /// ## Example
    /// ```swift
    /// if let imageData = Keychain.getData(forKey: "profileImage") {
    ///     let image = UIImage(data: imageData)
    /// }
    /// ```
    public static func getData(forKey key: String, service: String = defaultService) -> Data? {
        fetchData(service: service, account: key)
    }
    
    /// Stores binary data in the keychain, or removes it if `nil`.
    ///
    /// - Parameters:
    ///   - value: The data to store, or `nil` to remove the item.
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to `defaultService`.
    /// - Returns: `true` if the operation succeeded, `false` otherwise.
    ///
    /// ## Example
    /// ```swift
    /// let certificateData = try Data(contentsOf: certURL)
    /// let success = Keychain.setData(certificateData, forKey: "certificate")
    ///
    /// Keychain.setData(nil, forKey: "certificate")
    /// ```
    @discardableResult
    public static func setData(_ value: Data?, forKey key: String, service: String = defaultService) -> Bool {
        guard let value else {
            return remove(service: service, account: key)
        }
        return saveData(service: service, account: key, data: value)
    }
    
    /// Retrieves a boolean value from the keychain.
    ///
    /// - Parameters:
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to `defaultService`.
    /// - Returns: The stored boolean value, or `nil` if the item doesn't exist or is invalid.
    ///
    /// ## Example
    /// ```swift
    /// if Keychain.getBool(forKey: "isDarkMode") == true {
    ///     enableDarkMode()
    /// }
    /// ```
    public static func getBool(forKey key: String, service: String = defaultService) -> Bool? {
        guard let value = getString(forKey: key, service: service) else { return nil }
        return value == "true" ? true : (value == "false" ? false : nil)
    }
    
    /// Stores a boolean value in the keychain, or removes it if `nil`.
    ///
    /// - Parameters:
    ///   - value: The boolean to store, or `nil` to remove the item.
    ///   - key: The account identifier for the keychain item.
    ///   - service: The service identifier. Defaults to `defaultService`.
    /// - Returns: `true` if the operation succeeded, `false` otherwise.
    ///
    /// ## Example
    /// ```swift
    /// Keychain.setBool(true, forKey: "hasAcceptedTerms")
    ///
    /// Keychain.setBool(nil, forKey: "hasAcceptedTerms")
    /// ```
    @discardableResult
    public static func setBool(_ value: Bool?, forKey key: String, service: String = defaultService) -> Bool {
        guard let value else {
            return remove(service: service, account: key)
        }
        return setString(value ? "true" : "false", forKey: key, service: service)
    }
    
    // MARK: - Private Methods
    
    @discardableResult private static func save(service: String, account: String, token: String) -> Bool {
        let tokenData = token.data(using: .utf8)!
        return saveData(service: service, account: account, data: tokenData)
    }
    
    @discardableResult private static func saveData(service: String, account: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary) // Delete any existing item

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private static func fetch(service: String, account: String) -> String? {
        guard let data = fetchData(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private static func fetchData(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            return dataTypeRef as? Data
        }

        return nil
    }

    @discardableResult private static func remove(service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
} 