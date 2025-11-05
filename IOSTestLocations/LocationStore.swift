import Foundation
import Combine
import CoreLocation

@MainActor
final class LocationStore: ObservableObject {
    @Published private(set) var mainLocations: [LocationEntry] = []
    @Published private(set) var secondaryLocations: [LocationEntry] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastErrorMessage: String?

    private let locationManager: LocationManager

    init(locationManager: LocationManager = LocationManager()) {
        self.locationManager = locationManager
        self.authorizationStatus = locationManager.authorizationStatus

        locationManager.authorizationHandler = { [weak self] status in
            self?.authorizationStatus = status
        }

        locationManager.errorHandler = { [weak self] error in
            self?.lastErrorMessage = error.localizedDescription
        }

        locationManager.requestAuthorizationIfNeeded()
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
    }

    func captureMainLocation() {
        captureLocation { [weak self] entry in
            self?.mainLocations.insert(entry, at: 0)
        }
    }

    func captureSecondaryLocation() {
        captureLocation { [weak self] entry in
            self?.secondaryLocations.insert(entry, at: 0)
        }
    }

    private func captureLocation(_ handler: @escaping (LocationEntry) -> Void) {
        lastErrorMessage = nil

        locationManager.requestLocation { result in
            switch result {
            case let .success(location):
                let entry = LocationEntry(location: location)
                handler(entry)
            case let .failure(error):
                self.lastErrorMessage = error.localizedDescription
            }
        }
    }
}
