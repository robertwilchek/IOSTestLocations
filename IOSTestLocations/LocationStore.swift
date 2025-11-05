import Foundation
import Combine
import CoreLocation

@MainActor
final class LocationStore: ObservableObject {
    @Published private(set) var mainLocations: [LocationEntry] = []
    @Published private(set) var secondaryLocations: [LocationEntry] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastErrorMessage: String?
    @Published private(set) var liveLocation: LocationEntry?

    private let locationManager: LocationManager
    private let maximumLocationAge: TimeInterval = 10

    init(locationManager: LocationManager = LocationManager()) {
        self.locationManager = locationManager
        self.authorizationStatus = locationManager.authorizationStatus

        locationManager.authorizationHandler = { [weak self] status in
            self?.handleAuthorizationChange(status)
        }

        locationManager.errorHandler = { [weak self] error in
            self?.lastErrorMessage = error.localizedDescription
        }

        locationManager.locationUpdateHandler = { [weak self] location in
            self?.liveLocation = LocationEntry(location: location)
        }

        handleAuthorizationChange(locationManager.authorizationStatus)
        locationManager.requestAuthorizationIfNeeded()
    }

    func refreshAuthorizationStatus() {
        handleAuthorizationChange(locationManager.authorizationStatus)
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

        if let latestLocation = locationManager.latestLocation,
           abs(latestLocation.timestamp.timeIntervalSinceNow) <= maximumLocationAge {
            let entry = LocationEntry(location: latestLocation)
            liveLocation = entry
            handler(entry)
            return
        }

        locationManager.requestLocation { [weak self] result in
            guard let self else { return }

            switch result {
            case let .success(location):
                let entry = LocationEntry(location: location)
                self.liveLocation = entry
                handler(entry)
            case let .failure(error):
                self.lastErrorMessage = error.localizedDescription
            }
        }
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        authorizationStatus = status

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startContinuousUpdates()
        case .denied, .restricted:
            liveLocation = nil
            locationManager.stopContinuousUpdates()
        case .notDetermined:
            liveLocation = nil
            locationManager.stopContinuousUpdates()
        @unknown default:
            liveLocation = nil
            locationManager.stopContinuousUpdates()
        }
    }
}
