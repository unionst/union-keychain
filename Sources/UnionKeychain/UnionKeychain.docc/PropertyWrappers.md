# Property Wrappers

Use declarative property wrappers for automatic keychain persistence.

## Overview

UnionKeychain provides three property wrappers that automatically persist values to the keychain. This declarative approach reduces boilerplate code and makes keychain storage feel as simple as regular properties.

## Available Property Wrappers

- ``KeychainString`` - For optional string values
- ``KeychainBool`` - For boolean values with default fallback
- ``KeychainData`` - For optional binary data

## KeychainString

Store optional string values with automatic keychain persistence:

```swift
class UserSession {
    @KeychainString(key: "username")
    var username: String?
    
    @KeychainString(key: "authToken")
    var authToken: String?
}

let session = UserSession()
session.username = "john_doe"
print(session.username)

session.authToken = nil
```

### With Custom Service

Organize keychain items by specifying a custom service name:

```swift
@KeychainString(key: "refreshToken", service: "com.myapp.tokens")
var refreshToken: String?
```

## KeychainBool

Store boolean values that always return a concrete `Bool` (never optional):

```swift
class AppSettings {
    @KeychainBool(key: "isDarkMode", defaultValue: false)
    var isDarkMode: Bool
    
    @KeychainBool(key: "hasCompletedOnboarding", defaultValue: false)
    var hasCompletedOnboarding: Bool
    
    @KeychainBool(key: "isPremium", defaultValue: false)
    var isPremium: Bool
}

let settings = AppSettings()
settings.isDarkMode = true

if settings.hasCompletedOnboarding {
    showMainInterface()
}
```

The `defaultValue` parameter determines what value is returned when nothing is stored in the keychain yet.

### SwiftUI Integration

Property wrappers work seamlessly with SwiftUI's `@Published`:

```swift
class AppState: ObservableObject {
    @Published @KeychainBool(key: "isPremium", defaultValue: false)
    var isPremium: Bool
    
    @Published @KeychainString(key: "username")
    var username: String?
}
```

## KeychainData

Store optional binary data like images or certificates:

```swift
class UserProfile {
    @KeychainData(key: "profileImage")
    var profileImageData: Data?
    
    @KeychainData(key: "encryptionKey")
    var encryptionKey: Data?
    
    var profileImage: UIImage? {
        get {
            guard let data = profileImageData else { return nil }
            return UIImage(data: data)
        }
        set {
            profileImageData = newValue?.jpegData(compressionQuality: 0.8)
        }
    }
}

let profile = UserProfile()
profile.profileImage = UIImage(named: "avatar")
```

## Building a Complete User Session

Combine multiple property wrappers for comprehensive session management:

```swift
class UserSession: ObservableObject {
    @Published @KeychainString(key: "accessToken")
    var accessToken: String?
    
    @Published @KeychainString(key: "refreshToken")
    var refreshToken: String?
    
    @Published @KeychainString(key: "userID")
    var userID: String?
    
    @Published @KeychainBool(key: "isPremium", defaultValue: false)
    var isPremium: Bool
    
    @Published @KeychainBool(key: "hasSeenWelcome", defaultValue: false)
    var hasSeenWelcome: Bool
    
    @Published @KeychainData(key: "profileImage")
    var profileImageData: Data?
    
    var isAuthenticated: Bool {
        accessToken != nil
    }
    
    func login(accessToken: String, refreshToken: String, userID: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userID = userID
    }
    
    func logout() {
        accessToken = nil
        refreshToken = nil
        userID = nil
        profileImageData = nil
    }
}
```

Use in SwiftUI:

```swift
@main
struct MyApp: App {
    @StateObject private var session = UserSession()
    
    var body: some Scene {
        WindowGroup {
            if session.isAuthenticated {
                MainTabView()
                    .environmentObject(session)
            } else {
                LoginView()
                    .environmentObject(session)
            }
        }
    }
}
```

## Advantages Over Direct API

Property wrappers provide several benefits:

### 1. Less Boilerplate

**Without property wrappers:**
```swift
var username: String? {
    get { Keychain.getString(forKey: "username") }
    set { Keychain.setString(newValue, forKey: "username") }
}
```

**With property wrappers:**
```swift
@KeychainString(key: "username")
var username: String?
```

### 2. Type Safety

The compiler enforces correct types at compile time:

```swift
@KeychainBool(key: "isPremium", defaultValue: false)
var isPremium: Bool

isPremium = "true"
```

### 3. Clear Intent

Property wrappers make it immediately obvious that a property is persisted:

```swift
class Settings {
    var temporaryFlag: Bool = false
    
    @KeychainBool(key: "permanentFlag", defaultValue: false)
    var permanentFlag: Bool
}
```

## When to Use Direct API

Property wrappers are ideal for class properties, but use the direct API when:

- Working in a struct (property wrappers only work well in classes)
- Needing the success/failure return value
- Performing one-off storage operations
- Working in static contexts

```swift
func saveTemporaryCredentials() {
    let success = Keychain.setString("temp_token", forKey: "tempAuth")
    if !success {
        showError("Failed to save credentials")
    }
}
```

## See Also

- <doc:GettingStarted>
- <doc:FreeTrialTracking>
- ``KeychainString``
- ``KeychainBool``
- ``KeychainData``

