import Foundation

@propertyWrapper
public struct KeychainString {
    private let key: String
    private let service: String
    
    public init(key: String, service: String = Keychain.defaultService) {
        self.key = key
        self.service = service
    }
    
    public var wrappedValue: String? {
        get {
            Keychain.getString(forKey: key, service: service)
        }
        set {
            Keychain.setString(newValue, forKey: key, service: service)
        }
    }
}

@propertyWrapper
public struct KeychainBool {
    private let key: String
    private let service: String
    private let defaultValue: Bool
    
    public init(key: String, defaultValue: Bool = false, service: String = Keychain.defaultService) {
        self.key = key
        self.defaultValue = defaultValue
        self.service = service
    }
    
    public var wrappedValue: Bool {
        get {
            Keychain.getBool(forKey: key, service: service) ?? defaultValue
        }
        set {
            Keychain.setBool(newValue, forKey: key, service: service)
        }
    }
}

@propertyWrapper
public struct KeychainData {
    private let key: String
    private let service: String
    
    public init(key: String, service: String = Keychain.defaultService) {
        self.key = key
        self.service = service
    }
    
    public var wrappedValue: Data? {
        get {
            Keychain.getData(forKey: key, service: service)
        }
        set {
            Keychain.setData(newValue, forKey: key, service: service)
        }
    }
} 