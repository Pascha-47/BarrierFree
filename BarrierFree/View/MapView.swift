//
//  MapView.swift
//  BarrierFree
//
//  Created by TA616 on 18.01.26.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.5841, longitude: 8.6784),  
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 50.5841, longitude: 8.6784),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var searchQuery = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var visibleRegion: MKCoordinateRegion?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            Map(position: $position) {
                ForEach(searchResults, id: \.placemark) { item in
                    Marker(item: item)
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Suchleiste oben
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                    
                    TextField("Suche ...", text: $searchQuery)
                        .font(.title3)
                        .focused($isSearchFocused)
                        .onSubmit {
                            Task {
                                await performSearch()
                            }
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
                            searchQuery = ""
                            searchResults = []
                            isSearchFocused = false
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
                
                Spacer()
                
                HStack(spacing: 0) {
                    Button(action: {
                        print("Explore gedrückt")
                        position = .region(region)
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
        .onMapCameraChange { context in
            visibleRegion = context.region
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func performSearch() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.resultTypes = [.pointOfInterest]
        request.region = visibleRegion ?? region
        
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            searchResults = response.mapItems
            if !searchResults.isEmpty {
                let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                let newRegion = MKCoordinateRegion(
                    center: response.mapItems.first!.placemark.coordinate,
                    span: span
                )
                position = .region(newRegion)
            }
        } catch {
            print("Suche fehlgeschlagen: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        MapView()
    }
}
