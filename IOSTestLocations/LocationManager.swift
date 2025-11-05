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
    private var shouldResumeContinuousUpdates = false

    private(set) var latestLocation: CLLocation?

    var authorizationHandler: ((CLAuthorizationStatus) -> Void)?
    var errorHandler: ((Error) -> Void)?

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    override init() {
        self.manager = CLLocationManager()
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.pausesLocationUpdatesAutomatically = false
        self.manager.activityType = .fitness
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

    func startContinuousUpdates() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .notDetermined:
            shouldResumeContinuousUpdates = true
            manager.requestWhenInUseAuthorization()
        case .denied:
            errorHandler?(LocationManagerError.authorizationDenied)
        case .restricted:
            errorHandler?(LocationManagerError.authorizationRestricted)
        @unknown default:
            break
        }
    }

    func stopContinuousUpdates() {
        shouldResumeContinuousUpdates = false
        manager.stopUpdatingLocation()
    }

    func mostRecentLocation(maxAge: TimeInterval) -> CLLocation? {
        let candidate = latestLocation ?? manager.location
        guard let candidate else { return nil }

        if candidate.timestamp.timeIntervalSinceNow >= -maxAge {
            return candidate
        }

        return nil
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            latestLocation = location
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

        if shouldResumeContinuousUpdates,
           manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            shouldResumeContinuousUpdates = false
            manager.startUpdatingLocation()
        }
    }
}
