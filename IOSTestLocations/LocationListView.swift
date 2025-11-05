import SwiftUI
import CoreLocation

struct LocationListView: View {
    let title: String
    let locations: [LocationEntry]
    let authorizationStatus: CLAuthorizationStatus
    let lastError: String?
    let captureAction: () -> Void
    let refreshAuthorization: () -> Void

    var body: some View {
        List {
            Section(header: Text(title)) {
                authorizationBanner
                    .font(.subheadline)

                Button(action: captureAction) {
                    Label("Capture Current Location", systemImage: "location.fill")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)

                if let lastError {
                    Text(lastError)
                        .foregroundStyle(.red)
                }
            }

            Section(header: Text("Captured Points")) {
                if locations.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .imageScale(.large)
                            .foregroundStyle(.secondary)
                        Text("No locations captured yet")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Text("Tap the button above to record your current position.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                } else {
                    ForEach(locations) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.formattedCoordinate)
                                .font(.headline)
                            Text(entry.formattedTimestamp)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .onAppear(perform: refreshAuthorization)
    }

    @ViewBuilder
    private var authorizationBanner: some View {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            Label("Ready to capture", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
        case .denied, .restricted:
            Label("Location access denied", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .notDetermined:
            Label("Allow location access to capture points", systemImage: "questionmark.circle")
                .foregroundStyle(.blue)
        @unknown default:
            EmptyView()
        }
    }
}

struct LocationListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LocationListView(
                title: "Preview",
                locations: [
                    LocationEntry(location: CLLocation(latitude: 37.3349, longitude: -122.0090))
                ],
                authorizationStatus: .authorizedWhenInUse,
                lastError: nil,
                captureAction: {},
                refreshAuthorization: {}
            )
        }
    }
}
