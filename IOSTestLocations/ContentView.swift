import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: LocationStore

    var body: some View {
        NavigationView {
            LocationListView(
                title: "Primary Locations",
                locations: store.mainLocations,
                authorizationStatus: store.authorizationStatus,
                lastError: store.lastErrorMessage,
                captureAction: store.captureMainLocation,
                refreshAuthorization: store.refreshAuthorizationStatus,
                startContinuousUpdates: store.startContinuousUpdates,
                stopContinuousUpdates: store.stopContinuousUpdates
            )
            .navigationTitle("Location Capture")
            .toolbar {
                NavigationLink(destination: SecondaryLocationListView()) {
                    Text("Secondary")
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LocationStore())
    }
}
