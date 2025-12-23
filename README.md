# UnionKeychain

A lightweight, type-safe Swift keychain wrapper for iOS 17+ and macOS 14+.

## Features

- Simple static API for quick access to keychain storage
- Type-safe methods for strings, booleans, and binary data
- Property wrappers for declarative storage
- Persistent storage that survives app uninstalls
- Perfect for free trial tracking and authentication tokens

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/yourusername/union-keychain.git", from: "1.0.0")
```

Or add it directly in Xcode using **File → Add Packages...**

## Usage

### Basic Storage

```swift
import UnionKeychain

Keychain.setString("secret_token", forKey: "apiToken")
if let token = Keychain.getString(forKey: "apiToken") {
    print("Token: \(token)")
}

Keychain.setBool(true, forKey: "hasCompletedOnboarding")
if Keychain.getBool(forKey: "hasCompletedOnboarding") == true {
    showMainInterface()
}

let imageData = UIImage(named: "avatar")?.jpegData(compressionQuality: 0.8)
Keychain.setData(imageData, forKey: "profileImage")
if let data = Keychain.getData(forKey: "profileImage") {
    let image = UIImage(data: data)
}
```

### Convenience Properties

```swift
Keychain.bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

if let token = Keychain.bearerToken {
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}

if !Keychain.usedFreeAccount {
    Keychain.usedFreeAccount = true
    presentFreeTrial()
}
```

### Property Wrappers

```swift
class UserSession {
    @KeychainString(key: "username")
    var username: String?
    
    @KeychainBool(key: "isPremium", defaultValue: false)
    var isPremium: Bool
    
    @KeychainData(key: "certificate")
    var certificate: Data?
}

let session = UserSession()
session.username = "john_doe"
session.isPremium = true
```

### Persistent Free Trial Tracking

Unlike UserDefaults, keychain data persists even when the app is uninstalled and reinstalled. This makes it perfect for tracking free trial usage:

```swift
func checkTrialEligibility() {
    if Keychain.usedFreeAccount {
        showPaywall()
    } else {
        Keychain.usedFreeAccount = true
        startFreeTrial()
    }
}
```

Users cannot bypass trial restrictions by simply reinstalling your app.

### Custom Service Names

```swift
Keychain.setString("value", forKey: "key", service: "com.myapp.custom")
let value = Keychain.getString(forKey: "key", service: "com.myapp.custom")
```

### Removing Values

Set any value to `nil` to remove it from the keychain:

```swift
Keychain.setString(nil, forKey: "apiToken")
Keychain.setBool(nil, forKey: "isPremium")
Keychain.setData(nil, forKey: "certificate")
```

## API Reference

### Static Methods

- `getString(forKey:service:) -> String?`
- `setString(_:forKey:service:) -> Bool`
- `getData(forKey:service:) -> Data?`
- `setData(_:forKey:service:) -> Bool`
- `getBool(forKey:service:) -> Bool?`
- `setBool(_:forKey:service:) -> Bool`

### Static Properties

- `defaultService: String` - The default service identifier
- `bearerToken: String?` - Convenience property for auth tokens
- `usedFreeAccount: Bool` - Convenience property for trial tracking

### Property Wrappers

- `@KeychainString` - Optional string storage
- `@KeychainBool` - Boolean storage with default value
- `@KeychainData` - Optional binary data storage

## License

MIT License
