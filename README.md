# IOSTestLocations

An example SwiftUI application that captures your current GPS location whenever you press a button. The main view maintains its own list of captured readings and provides navigation to a secondary screen that records an independent list.

## Features

- Requests when-in-use location authorization on launch.
- Primary and secondary views can each capture the current coordinate on demand.
- Lists show the recorded latitude, longitude, and accuracy alongside a timestamp.
- Navigation lets you move between the two screens without losing stored readings.

## Building

1. Open `IOSTestLocations.xcodeproj` in Xcode 15 or newer.
2. Select the **IOSTestLocations** target.
3. Choose an iOS 15+ simulator or a physical device.
4. Build and run the app (`⌘R`).

The project already contains the required Info.plist entry (`NSLocationWhenInUseUsageDescription`). When running on a device, ensure you grant location access when prompted.
