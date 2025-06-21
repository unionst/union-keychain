# UnionKeychain

A lightweight, easy-to-use Swift keychain wrapper for iOS 17+.

## Features

- Simple static API for quick access to common keychain values
- Generic methods for storing various data types
- Property wrappers for seamless integration with your models
- Modern Swift API with async/await support

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/yourusername/UnionKeychain.git", from: "1.0.0")
```

Or add it directly in Xcode using File → Add Packages...

## Usage

### Important: App Isolation

When multiple apps on the same device use this package, each app must use its own service name to avoid security issues. Set this in your AppDelegate or early in app initialization:

```swift
// In AppDelegate.swift or early in app setup
Keychain.defaultService = Bundle.main.bundleIdentifier ?? "com.yourcompany.app"
```

### Basic Usage

```swift
// Store a token
Keychain.bearerToken = "your-token-string"

// Retrieve a token
if let token = Keychain.bearerToken {
    print("Token: \(token)")
}

// Remove a token
Keychain.bearerToken = nil
```

### Generic Methods

```swift
// Store a string
Keychain.setString("some-value", forKey: "custom-key")

// Retrieve a string
let value = Keychain.getString(forKey: "custom-key")

// Store a boolean
Keychain.setBool(true, forKey: "feature-enabled")

// Store data
let data = "Hello World".data(using: .utf8)!
Keychain.setData(data, forKey: "some-data")
```

### Property Wrappers

```swift
class UserSettings {
    @KeychainString(key: "user-token")
    var token: String?
    
    @KeychainBool(key: "is-premium", defaultValue: false)
    var isPremium: Bool
    
    @KeychainData(key: "user-avatar")
    var avatarData: Data?
}

// Usage
let settings = UserSettings()
settings.token = "new-token"
settings.isPremium = true
```

### Cross-App Keychain Sharing

If you need to share keychain items between apps:

1. Enable keychain sharing in your app's entitlements
2. Use the same access group for both apps
3. Use a custom service name that's the same in both apps:

```swift
// App 1 and App 2 both use this same service name
let sharedService = "com.yourcompany.shared-keychain"

// Store data in App 1
Keychain.setString("shared-secret", forKey: "shared-key", service: sharedService)

// Access same data in App 2
let sharedValue = Keychain.getString(forKey: "shared-key", service: sharedService)
```

## License

[Your License] 