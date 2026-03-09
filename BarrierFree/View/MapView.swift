//
//  MapView.swift
//  BarrierFree
//
//  Created by TA616 on 18.01.26.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var heading: Double = 0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .automotiveNavigation
        manager.distanceFilter = 10
        manager.headingFilter = 5
        authorizationStatus = manager.authorizationStatus
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            print("📍 Standort: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading.trueHeading
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            print("🔐 Berechtigung: \(manager.authorizationStatus.rawValue)")
        }
    }
}

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .userLocation(
        followsHeading: false,
        fallback: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 50.5841, longitude: 8.6784),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        )
    )
    @State private var searchQuery = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var routeOverlay: MKPolyline?
    @State private var currentRoute: MKRoute?
    @State private var isNavigating = false
    @State private var remainingDistance: CLLocationDistance = 0
    @State private var remainingTime: TimeInterval = 0
    @State private var estimatedArrival: Date?
    @State private var showLocationAlert = false
    @FocusState private var isSearchFocused: Bool
    @State private var visibleRegion: MKCoordinateRegion?

    var body: some View {
        ZStack {
            Map(position: $position) {
                UserAnnotation()
                
                ForEach(searchResults, id: \.placemark) { item in
                    Marker(item: item)
                }
                
                // Route in ROT (wie Apple Maps)
                if let overlay = routeOverlay {
                    MapPolyline(overlay)
                        .stroke(.red, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                }
            }
            .mapStyle(.standard)
            .mapControls {
                MapCompass()
                MapUserLocationButton()
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Suchleiste
                if !isNavigating {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                        
                        TextField("Suche Orte, Städte ...", text: $searchQuery)
                            .font(.title3)
                            .focused($isSearchFocused)
                            .onSubmit {
                                Task { await performSearch() }
                            }
                            .submitLabel(.search)
                        
                        if !isSearchFocused {
                            Button(action: {
                                print("Konto geöffnet")
                            }) {
                                Image(systemName: "person.circle")
                                    .font(.title2)
                                    .foregroundStyle(.gray)
                            }
                        }
                        
                        if !searchQuery.isEmpty {
                            Button("Löschen") {
                                withAnimation {
                                    searchQuery = ""
                                    searchResults = []
                                    routeOverlay = nil
                                    currentRoute = nil
                                    isNavigating = false
                                    isSearchFocused = false
                                }
                            }
                            .foregroundStyle(.secondary)
                            .font(.title3)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30))
                    .padding(.horizontal, 20)
                    .padding(.top, 5)
                }
                
                // Route Info Card (Apple-Style)
                if let route = currentRoute, !isNavigating {
                    VStack(spacing: 14) {
                        HStack(alignment: .top) {
                            // Route Symbol
                            Image(systemName: "car.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .padding(12)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(formatTime(route.expectedTravelTime))
                                        .font(.system(size: 28, weight: .bold))
                                    Text("(\(Int(route.distance / 1000)) km)")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if let destination = searchResults.first?.name {
                                    Text("Nach \(destination)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Los") {
                                startNavigation()
                            }
                            .font(.headline)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                        
                        Divider()
                        
                        // Alternativ-Routen Info
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Schnellste Route über A5")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                        }
                    }
                    .padding(18)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.12), radius: 15, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // Live-Navigationsleiste WÄHREND Navigation
                if isNavigating {
                    VStack(spacing: 10) {
                        HStack(spacing: 18) {
                            // Verbleibende Zeit
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatTime(remainingTime))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(.green)
                                Text("Verbleibend")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Divider()
                                .frame(height: 45)
                            
                            // Verbleibende Distanz
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(String(format: "%.1f", remainingDistance / 1000)) km")
                                    .font(.system(size: 26, weight: .semibold))
                                Text("Noch zu fahren")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            // Ankunftszeit
                            VStack(alignment: .trailing, spacing: 2) {
                                if let eta = estimatedArrival {
                                    Text(eta, style: .time)
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundStyle(.blue)
                                    Text("ETA")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        
                        // Navigation beenden Button
                        Button(action: {
                            stopNavigation()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Beenden")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                            .padding(.vertical, 10)
                        }
                        .padding(.bottom, 12)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.15), radius: 12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Untere Buttons
                if !isNavigating {
                    HStack(spacing: 0) {
                        Button(action: {
                            position = .userLocation(fallback: .region(
                                MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: 50.5841, longitude: 8.6784),
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                )
                            ))
                            routeOverlay = nil
                            currentRoute = nil
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                Text("Explore")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            print("Saved gedrückt")
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "bookmark.fill")
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                Text("Saved")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onMapCameraChange { context in
            visibleRegion = context.region
        }
        .onReceive(locationManager.$userLocation) { newLocation in
            if isNavigating, let location = newLocation {
                updateNavigationProgress(userLocation: location)
            }
        }
        .alert("Standortzugriff erforderlich", isPresented: $showLocationAlert) {
            Button("Einstellungen") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Aktiviere Ortungsdienste für Navigation.")
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func performSearch() async {
        guard !searchQuery.isEmpty else { return }
        
        print("🔍 Suche nach: \(searchQuery)")
        
        // Prüfe Standortberechtigung
        if locationManager.authorizationStatus == .denied {
            showLocationAlert = true
            return
        }
        
        var request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.resultTypes = [.address, .pointOfInterest]
        
        // Große Region für Städte wie Berlin
        request.region = MKCoordinateRegion(
            center: locationManager.userLocation ?? CLLocationCoordinate2D(latitude: 50.5841, longitude: 8.6784),
            span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
        )
        
        do {
            let response = try await MKLocalSearch(request: request).start()
            
            if response.mapItems.isEmpty {
                print("❌ Keine Ergebnisse für '\(searchQuery)'")
                return
            }
            
            withAnimation {
                searchResults = response.mapItems
            }
            
            if let firstItem = response.mapItems.first {
                print("✅ Gefunden: \(firstItem.name ?? "Unbekannt") - \(firstItem.placemark.locality ?? "")")
                await calculateRoute(to: firstItem)
            }
        } catch {
            print("❌ Suchfehler: \(error.localizedDescription)")
        }
    }
    
    private func calculateRoute(to destination: MKMapItem) async {
        // Nutze echten Standort oder Fallback (Gießen)
        let userCoord = locationManager.userLocation ?? CLLocationCoordinate2D(latitude: 50.5841, longitude: 8.6784)
        
        print("🚗 Route von \(userCoord.latitude), \(userCoord.longitude) nach \(destination.placemark.coordinate.latitude), \(destination.placemark.coordinate.longitude)")
        
        let sourcePlacemark = MKPlacemark(coordinate: userCoord)
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        
        var request = MKDirections.Request()
        request.source = sourceItem
        request.destination = destination
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        do {
            let response = try await MKDirections(request: request).calculate()
            
            if let route = response.routes.first {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentRoute = route
                    routeOverlay = route.polyline
                    remainingDistance = route.distance
                    remainingTime = route.expectedTravelTime
                    estimatedArrival = Date().addingTimeInterval(route.expectedTravelTime)
                }
                
                print("✅ Route: \(Int(route.distance/1000))km in \(Int(route.expectedTravelTime/60))min")
                
                // Zoom auf Route
                let rect = route.polyline.boundingMapRect
                let span = MKCoordinateSpan(
                    latitudeDelta: rect.size.height / 111000.0 * 1.4,
                    longitudeDelta: rect.size.width / 111000.0 * 1.4
                )
                let center = MKMapPoint(x: rect.midX, y: rect.midY).coordinate
                
                withAnimation(.easeInOut(duration: 1.0)) {
                    position = .region(MKCoordinateRegion(center: center, span: span))
                }
            }
        } catch {
            print("❌ Routenberechnung fehlgeschlagen: \(error.localizedDescription)")
        }
    }
    
    private func startNavigation() {
        withAnimation {
            isNavigating = true
        }
        
        // 🚀 WICHTIG: Automatisches Follow-Modus für Blue Dot (wie Apple Maps)
        position = .userLocation(
            followsHeading: true,
            fallback: .camera(MapCamera(
                centerCoordinate: locationManager.userLocation ?? CLLocationCoordinate2D(latitude: 50.5841, longitude: 8.6784),
                distance: 1000,
                heading: locationManager.heading,
                pitch: 60
            ))
        )
        print("🚗 Navigation gestartet - Blue Dot folgt automatisch!")
    }
    
    private func stopNavigation() {
        withAnimation {
            isNavigating = false
        }
        routeOverlay = nil
        currentRoute = nil
        searchResults = []
        position = .userLocation(fallback: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 50.5841, longitude: 8.6784),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        ))
        print("🛑 Navigation beendet")
    }
    
    private func updateNavigationProgress(userLocation: CLLocationCoordinate2D) {
        guard let route = currentRoute else { return }
        
        let destination = route.polyline.points()[route.polyline.pointCount - 1].coordinate
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let destCLLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        
        remainingDistance = userCLLocation.distance(from: destCLLocation)
        
        let traveledDistance = route.distance - remainingDistance
        let progress = traveledDistance / route.distance
        remainingTime = max(0, route.expectedTravelTime * (1 - progress))
        estimatedArrival = Date().addingTimeInterval(remainingTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        if hours > 0 {
            return "\(hours) Std \(minutes) Min"
        } else {
            return "\(minutes) Min"
        }
    }
}

#Preview {
    NavigationStack {
        MapView()
    }
}
