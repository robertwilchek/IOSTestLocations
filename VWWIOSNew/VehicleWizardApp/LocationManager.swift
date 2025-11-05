import Foundation
import CoreLocation

enum LocationManagerError: LocalizedError {
    case authorizationDenied
    case authorizationRestricted

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Location access has been denied. Enable it in Settings to continue."
        case .authorizationRestricted:
            return "Location access is restricted on this device."
        }
    }
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager: CLLocationManager
    private var pendingCompletion: ((Result<CLLocation, Error>) -> Void)?

    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var latestLocation: CLLocation?
    @Published var lastError: Error?

    override init() {
        self.manager = CLLocationManager()
        self.authorizationStatus = self.manager.authorizationStatus
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestAuthorizationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func startContinuousUpdates() {
        manager.startUpdatingLocation()
    }

    func stopContinuousUpdates() {
        manager.stopUpdatingLocation()
    }

    func requestLocation(_ completion: @escaping (Result<CLLocation, Error>) -> Void) {
        switch manager.authorizationStatus {
        case .denied:
            completion(.failure(LocationManagerError.authorizationDenied))
            return
        case .restricted:
            completion(.failure(LocationManagerError.authorizationRestricted))
            return
        case .authorizedAlways, .authorizedWhenInUse, .notDetermined:
            break
        @unknown default:
            break
        }

        pendingCompletion = completion
        manager.requestLocation()
    }

    func currentLocationString(completion: @escaping (String?) -> Void) {
        if let latestLocation {
            completion(Self.format(location: latestLocation))
            return
        }

        requestLocation { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let location):
                    completion(Self.format(location: location))
                case .failure:
                    completion(nil)
                }
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            latestLocation = location
            lastError = nil
            pendingCompletion?(.success(location))
        }

        pendingCompletion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = error
        pendingCompletion?(.failure(error))
        pendingCompletion = nil
    }

    private static func format(location: CLLocation) -> String {
        String(format: "%.6f_%.6f", location.coordinate.latitude, location.coordinate.longitude)
    }
}
