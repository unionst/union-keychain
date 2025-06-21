import Foundation
import Security

public enum Keychain {
    /// Default service name for keychain items.
    /// You should set this to your app's bundle identifier early in app initialization.
    /// Example: `Keychain.defaultService = Bundle.main.bundleIdentifier ?? "com.yourcompany.app"`
    public static let defaultService = Bundle.main.bundleIdentifier ?? "com.unionst.service"
    
    public static var bearerToken: String? {
        get { getString(forKey: "UserAccount") }
        set { setString(newValue, forKey: "UserAccount") }
    }
    
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
    
    // MARK: - Generic Methods
    
    public static func getString(forKey key: String, service: String = defaultService) -> String? {
        fetch(service: service, account: key)
    }
    
    @discardableResult
    public static func setString(_ value: String?, forKey key: String, service: String = defaultService) -> Bool {
        guard let value else {
            return remove(service: service, account: key)
        }
        return save(service: service, account: key, token: value)
    }
    
    public static func getData(forKey key: String, service: String = defaultService) -> Data? {
        fetchData(service: service, account: key)
    }
    
    @discardableResult
    public static func setData(_ value: Data?, forKey key: String, service: String = defaultService) -> Bool {
        guard let value else {
            return remove(service: service, account: key)
        }
        return saveData(service: service, account: key, data: value)
    }
    
    public static func getBool(forKey key: String, service: String = defaultService) -> Bool? {
        guard let value = getString(forKey: key, service: service) else { return nil }
        return value == "true" ? true : (value == "false" ? false : nil)
    }
    
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