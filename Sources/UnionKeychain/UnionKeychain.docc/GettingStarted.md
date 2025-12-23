# Getting Started with UnionKeychain

Store and retrieve sensitive data securely using the system keychain.

## Overview

This guide walks you through the basics of using UnionKeychain to store authentication tokens, user preferences, and other sensitive data. Unlike UserDefaults, data stored in the keychain is encrypted and persists even when your app is uninstalled.

## Installation

Add UnionKeychain to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/union-keychain.git", from: "1.0.0")
]
```

Then import it in your Swift files:

```swift
import UnionKeychain
```

## Storing Strings

The most common use case is storing authentication tokens and other string values:

```swift
Keychain.setString("secret_token", forKey: "apiToken")

if let token = Keychain.getString(forKey: "apiToken") {
    print("Retrieved token: \(token)")
}
```

### Quick Access with Convenience Properties

For authentication tokens, use the built-in ``Keychain/bearerToken`` property:

```swift
Keychain.bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

func makeAuthenticatedRequest() {
    guard let token = Keychain.bearerToken else {
        showLoginScreen()
        return
    }
    
    var request = URLRequest(url: apiURL)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}
```

## Storing Booleans

Store boolean flags for user preferences and feature toggles:

```swift
Keychain.setBool(true, forKey: "hasCompletedOnboarding")

if Keychain.getBool(forKey: "hasCompletedOnboarding") == true {
    showMainInterface()
} else {
    showOnboarding()
}
```

## Storing Binary Data

Store images, certificates, or any binary data:

```swift
let imageData = UIImage(named: "avatar")?.jpegData(compressionQuality: 0.8)
Keychain.setData(imageData, forKey: "profileImage")

if let data = Keychain.getData(forKey: "profileImage") {
    profileImageView.image = UIImage(data: data)
}
```

## Removing Values

Set any value to `nil` to remove it from the keychain:

```swift
Keychain.setString(nil, forKey: "apiToken")
Keychain.setBool(nil, forKey: "isPremium")
Keychain.setData(nil, forKey: "certificate")
```

All set methods return a boolean indicating success:

```swift
let success = Keychain.setString("value", forKey: "key")
if !success {
    print("Failed to save to keychain")
}
```

## Custom Service Names

By default, UnionKeychain uses your app's bundle identifier as the service name. You can specify custom service names to organize keychain items:

```swift
Keychain.setString("value", forKey: "key", service: "com.myapp.tokens")
let value = Keychain.getString(forKey: "key", service: "com.myapp.tokens")
```

This is useful for:
- Organizing different types of credentials
- Sharing keychain data between apps (with proper keychain sharing entitlements)
- Migrating from legacy keychain implementations

## Next Steps

- Learn about <doc:PropertyWrappers> for declarative storage
- Discover <doc:FreeTrialTracking> techniques that survive app reinstalls

