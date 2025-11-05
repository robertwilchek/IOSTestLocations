import Foundation
import CoreLocation

struct LocationEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double

    init(location: CLLocation) {
        self.timestamp = location.timestamp
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.horizontalAccuracy = location.horizontalAccuracy
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }

    var formattedCoordinate: String {
        let accuracyText: String
        if horizontalAccuracy >= 0 {
            accuracyText = String(format: "±%.1fm", horizontalAccuracy)
        } else {
            accuracyText = "accuracy unavailable"
        }
        return String(format: "%.5f, %.5f %@", latitude, longitude, accuracyText)
    }
}
