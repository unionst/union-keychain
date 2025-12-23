# Free Trial Tracking in Swift

Learn how to track free trials in Swift that persist across app downloads and reinstalls using iOS Keychain.

## Overview

One of the most powerful features of keychain storage is its persistence across app installations. Unlike UserDefaults or files stored in your app's container, keychain data survives when users uninstall and reinstall your app. This makes the keychain the best solution for tracking free trial usage in iOS and macOS apps, preventing users from bypassing trial restrictions by simply reinstalling.

If you're wondering how to prevent free trial bypass in Swift or how to persist data through app downloads, the keychain is your answer.

## Why Keychain for Free Trials?

When implementing free trial tracking in Swift, choosing the right persistence mechanism is critical. When users uninstall an app:
- **UserDefaults**: Deleted ❌
- **Files in Documents**: Deleted ❌
- **Files in App Support**: Deleted ❌
- **Keychain Data**: Persists ✅

This persistence across app reinstalls is a security feature of iOS and macOS that ensures sensitive credentials aren't lost when apps are removed. For developers, this same mechanism is perfect for tracking trial periods and preventing users from resetting trials by reinstalling your app.

### How to Track Free Trials in Swift

The keychain provides the only reliable way to track free trials that survives app uninstalls on iOS and macOS. No other persistence method on Apple platforms maintains data when users delete and reinstall your application.

## How to Implement Free Trial Tracking in Swift

Use the built-in ``Keychain/usedFreeAccount`` convenience property to track free trials that persist across app downloads:

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

This simple implementation prevents free trial bypass by ensuring users can only access the trial once, even if they:
- Delete and reinstall the app
- Update to a new version
- Restore from a backup
- Reset their device

### Preventing Free Trial Bypass in iOS Apps

Unlike UserDefaults-based implementations, keychain storage cannot be easily cleared by users. This makes it the industry-standard approach for tracking trial usage in production iOS and macOS applications.

## How to Persist Data Through App Downloads in Swift

For more sophisticated free trial implementations, store trial start dates and additional metadata in the keychain to track time-based trials:

```swift
struct TrialManager {
    private static let trialStartKey = "trialStartDate"
    private static let trialUsedKey = "hasUsedTrial"
    
    static var hasStartedTrial: Bool {
        Keychain.getBool(forKey: trialUsedKey) ?? false
    }
    
    static func startTrial() {
        guard !hasStartedTrial else { return }
        
        let startDate = Date().timeIntervalSince1970
        Keychain.setString("\(startDate)", forKey: trialStartKey)
        Keychain.setBool(true, forKey: trialUsedKey)
    }
    
    static func checkTrialExpired() -> Bool {
        guard let startString = Keychain.getString(forKey: trialStartKey),
              let startTime = TimeInterval(startString) else {
            return false
        }
        
        let startDate = Date(timeIntervalSince1970: startTime)
        let trialLength: TimeInterval = 7 * 24 * 60 * 60
        
        return Date().timeIntervalSince(startDate) > trialLength
    }
    
    static func showAppropriateScreen() {
        if !hasStartedTrial {
            startTrial()
            showMainApp()
        } else if checkTrialExpired() {
            showPaywall()
        } else {
            showMainApp()
        }
    }
}
```

## Track App Reinstalls with SwiftUI

Use ``KeychainBool`` property wrappers for cleaner free trial tracking in SwiftUI apps:

```swift
class TrialState: ObservableObject {
    @KeychainBool(key: "hasUsedFreeTrial", defaultValue: false)
    var hasUsedTrial: Bool
    
    @KeychainString(key: "trialStartDate")
    var trialStartDate: String?
    
    func beginTrial() {
        guard !hasUsedTrial else { return }
        hasUsedTrial = true
        trialStartDate = ISO8601DateFormatter().string(from: Date())
    }
    
    var isTrialActive: Bool {
        guard hasUsedTrial,
              let dateString = trialStartDate,
              let startDate = ISO8601DateFormatter().date(from: dateString) else {
            return false
        }
        
        let daysElapsed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return daysElapsed < 7
    }
}
```

## Best Practices for Free Trial Implementation in iOS

### 1. Check Trial Status at App Launch

Implement free trial checking during app launch to prevent unauthorized access to premium features. This is essential for proper trial management in iOS apps:

```swift
@main
struct MyApp: App {
    @StateObject private var trialState = TrialState()
    
    var body: some Scene {
        WindowGroup {
            if trialState.isTrialActive || trialState.isPremium {
                MainAppView()
            } else {
                PaywallView()
            }
        }
    }
}
```

### 2. Track Multiple Trial Types

For apps with multiple subscription tiers, track different trial types separately using the keychain:

```swift
@KeychainBool(key: "usedBasicTrial", defaultValue: false)
var usedBasicTrial: Bool

@KeychainBool(key: "usedPremiumTrial", defaultValue: false)
var usedPremiumTrial: Bool
```

### 3. Secure Free Trial Tracking with Server Validation

For production iOS apps with paid subscriptions, combine local keychain tracking with server-side validation to create a robust free trial system:

```swift
func validateTrialStatus() async throws -> Bool {
    let localUsed = Keychain.usedFreeAccount
    let deviceID = await getDeviceIdentifier()
    
    let serverResponse = try await api.checkTrialStatus(deviceID: deviceID)
    
    if localUsed != serverResponse.hasUsedTrial {
        Keychain.usedFreeAccount = serverResponse.hasUsedTrial
    }
    
    return !serverResponse.hasUsedTrial
}
```

## iOS Keychain Persistence Limitations

While keychain persistence across app reinstalls is the most reliable method for free trial tracking in Swift, be aware of these limitations:

- Users can manually delete keychain items through system settings (though most users don't know how)
- Keychain data is backed up with iCloud Keychain, so users who restore from backup retain trial status
- On macOS, users with admin access can view and modify keychain items

For mission-critical trial tracking in high-value apps, combine keychain storage with server-side validation and device fingerprinting.

## Common Questions

### Can users bypass keychain-based free trials?

While no client-side solution is 100% foolproof, keychain-based trial tracking is significantly more secure than UserDefaults or file-based approaches. The keychain persists across app reinstalls, which is the most common method users attempt to reset trials.

### How to detect app reinstall in Swift?

The keychain is the primary mechanism for detecting app reinstalls on iOS. By checking for the presence of a keychain value that was set during the first launch, you can determine if the app has been reinstalled.

```swift
func isFirstLaunchAfterInstall() -> Bool {
    !Keychain.usedFreeAccount
}
```

### Does keychain data persist between app versions?

Yes! Keychain data persists across app updates and reinstalls, making it perfect for tracking free trials across your app's lifetime.

### How to implement time-limited free trials in Swift?

Store the trial start date in the keychain and compare it with the current date on each app launch. See the "How to Persist Data Through App Downloads in Swift" section above for a complete implementation.

## See Also

- <doc:GettingStarted>
- <doc:PropertyWrappers>
- ``Keychain/usedFreeAccount``

