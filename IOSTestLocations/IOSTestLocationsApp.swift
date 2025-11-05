import SwiftUI

@main
struct IOSTestLocationsApp: App {
    @StateObject private var store = LocationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
