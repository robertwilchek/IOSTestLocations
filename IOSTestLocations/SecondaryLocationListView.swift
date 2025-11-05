import SwiftUI

struct SecondaryLocationListView: View {
    @EnvironmentObject private var store: LocationStore

    var body: some View {
        LocationListView(
            title: "Secondary Locations",
            locations: store.secondaryLocations,
            authorizationStatus: store.authorizationStatus,
            lastError: store.lastErrorMessage,
            captureAction: store.captureSecondaryLocation,
            refreshAuthorization: store.refreshAuthorizationStatus,
            startContinuousUpdates: store.startContinuousUpdates,
            stopContinuousUpdates: store.stopContinuousUpdates
        )
        .navigationTitle("Secondary")
    }
}

struct SecondaryLocationListView_Previews: PreviewProvider {
    static var previews: some View {
        SecondaryLocationListView()
            .environmentObject(LocationStore())
    }
}
