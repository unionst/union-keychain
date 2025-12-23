# ``UnionKeychain``

A lightweight, type-safe Swift keychain wrapper for iOS and macOS.

## Overview

UnionKeychain provides a simple, modern API for securely storing sensitive data in the system keychain. Unlike UserDefaults, keychain data persists even when users uninstall and reinstall your app, making it perfect for authentication tokens, free trial tracking, and other sensitive data.

## Features

- **Type-Safe API** - Store and retrieve strings, booleans, and binary data with dedicated methods
- **Persistent Storage** - Data survives app uninstalls and reinstalls
- **Property Wrappers** - Declarative storage with `@KeychainString`, `@KeychainBool`, and `@KeychainData`
- **Convenience Properties** - Quick access to common values like `bearerToken` and `usedFreeAccount`
- **Custom Service Names** - Organize keychain items by service identifier

## Quick Start

Store and retrieve a string:

```swift
Keychain.setString("secret_token", forKey: "apiToken")
if let token = Keychain.getString(forKey: "apiToken") {
    print("Token: \(token)")
}
```

Use convenience properties for common scenarios:

```swift
Keychain.bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

if let token = Keychain.bearerToken {
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}
```

Track free trial usage with persistent storage:

```swift
if !Keychain.usedFreeAccount {
    Keychain.usedFreeAccount = true
    startFreeTrial()
}
```

## Topics

### Essentials

- ``Keychain``
- <doc:GettingStarted>

### Property Wrappers

- ``KeychainString``
- ``KeychainBool``
- ``KeychainData``

### Guides

- <doc:FreeTrialTracking>
- <doc:PropertyWrappers>

