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

final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager: CLLocationManager
    private var completion: ((Result<CLLocation, Error>) -> Void)?

    private(set) var latestLocation: CLLocation?

    var authorizationHandler: ((CLAuthorizationStatus) -> Void)?
    var errorHandler: ((Error) -> Void)?
    var locationUpdateHandler: ((CLLocation) -> Void)?

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    override init() {
        self.manager = CLLocationManager()
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func startContinuousUpdates() {
        manager.startUpdatingLocation()
    }

    func stopContinuousUpdates() {
        manager.stopUpdatingLocation()
    }

    func requestAuthorizationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func requestLocation(_ completion: @escaping (Result<CLLocation, Error>) -> Void) {
        switch manager.authorizationStatus {
        case .denied:
            completion(.failure(LocationManagerError.authorizationDenied))
            return
        case .restricted:
            completion(.failure(LocationManagerError.authorizationRestricted))
            return
        case .authorizedWhenInUse, .authorizedAlways, .notDetermined:
            break
        @unknown default:
            break
        }

        self.completion = completion
        manager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            latestLocation = location
            locationUpdateHandler?(location)
            completion?(.success(location))
        }
        completion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorHandler?(error)
        completion?(.failure(error))
        completion = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationHandler?(manager.authorizationStatus)
    }
}
