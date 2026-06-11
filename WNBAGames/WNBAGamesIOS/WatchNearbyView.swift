import SwiftUI
import CoreLocation
import MapKit
import UIKit

struct WatchNearbyView: View {
    let game: Game
    @StateObject private var model = NearbyModel()

    var body: some View {
        Group {
            switch model.state {
            case .idle:
                EmptyMessage(
                    icon: "mappin.and.ellipse",
                    title: "Find Sports Bars Nearby",
                    message: "We'll find the 5 closest sports bars to watch \(game.awayTeam.displayName) at \(game.homeTeam.displayName).",
                    actionTitle: "Allow Location",
                    action: { model.start() }
                )
            case .requesting, .searching:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Finding sports bars near you…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            case .denied:
                EmptyMessage(
                    icon: "location.slash",
                    title: "Location Access Off",
                    message: "Enable location for WNBA Games in Settings to find nearby sports bars.",
                    actionTitle: "Open Settings",
                    action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            case .results(let items):
                if items.isEmpty {
                    EmptyMessage(
                        icon: "mappin.slash",
                        title: "No Sports Bars Nearby",
                        message: "We couldn't find any sports bars within range.",
                        actionTitle: nil,
                        action: nil
                    )
                } else {
                    List(items) { item in
                        Button {
                            item.mapItem.openInMaps()
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if let addr = item.address {
                                        Text(addr)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(item.distanceString)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.tint)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.forward.square")
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            case .error(let msg):
                EmptyMessage(
                    icon: "exclamationmark.triangle",
                    title: "Couldn't Search",
                    message: msg,
                    actionTitle: nil,
                    action: nil
                )
            }
        }
        .navigationTitle("Watch Nearby")
        .navigationBarTitleDisplayMode(.inline)
        .task { model.start() }
    }
}

private struct EmptyMessage: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

@MainActor
final class NearbyModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    enum State {
        case idle
        case requesting
        case denied
        case searching
        case results([NearbyItem])
        case error(String)
    }

    @Published var state: State = .idle
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            state = .requesting
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            state = .denied
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        @unknown default:
            state = .denied
        }
    }

    private func requestLocation() {
        state = .searching
        manager.requestLocation()
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard let self else { return }
            if case .searching = self.state {
                self.state = .error("Location unavailable. In the Simulator, set Features → Location to a preset.")
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.requestLocation()
            case .denied, .restricted:
                self.state = .denied
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in await self.search(near: location) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in self.state = .error(message) }
    }

    private func search(near location: CLLocation) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "sports bar"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 10_000,
            longitudinalMeters: 10_000
        )
        do {
            let response = try await MKLocalSearch(request: request).start()
            let items = response.mapItems
                .compactMap { NearbyItem(mapItem: $0, origin: location) }
                .sorted { $0.distance < $1.distance }
                .prefix(5)
            state = .results(Array(items))
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

struct NearbyItem: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
    let distance: CLLocationDistance

    var name: String { mapItem.name ?? "Unknown" }

    var address: String? {
        let p = mapItem.placemark
        let parts = [p.thoroughfare, p.locality].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    var distanceString: String {
        let miles = distance / 1609.34
        return String(format: "%.1f mi away", miles)
    }

    init?(mapItem: MKMapItem, origin: CLLocation) {
        guard let coord = mapItem.placemark.location else { return nil }
        self.mapItem = mapItem
        self.distance = origin.distance(from: coord)
    }
}
