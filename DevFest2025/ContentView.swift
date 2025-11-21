//
//  ContentView.swift
//  DevFest2025
//
//  Created by Fahim Uddin on 11/21/25.
//

import SwiftUI

import SwiftUI
import MapKit

import CoreLocation // Needed for address search

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @State private var manager = PotholeManager()
    
    // Start at Wayne State
    @State private var camera = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.3588, longitude: -83.0715), // Centered on Venue
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Zoomed out enough to see city highways
    ))
    
    @State private var selectedPothole: Pothole?
    @State private var showTooEarlyAlert = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            Map(position: $camera) {
                ForEach(manager.potholes) { pothole in
                    Annotation("", coordinate: pothole.coordinate) {
                        Button {
                            if pothole.isActionable {
                                selectedPothole = pothole
                            } else {
                                showTooEarlyAlert = true
                            }
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundStyle(.white)
                                .background(Circle().fill(pothole.isActionable ? .red : .yellow))
                                .shadow(radius: 4)
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .navigationTitle("CivicLoop")
            .navigationBarTitleDisplayMode(.inline)
            // THIS IS THE NATIVE SEARCH BAR
            .searchable(text: $searchText, prompt: "Search highways, cities...") // ✅ FIXED
            .onSubmit(of: .search) {
                performSearch()
            }
        }
        // ALERTS & SHEETS
        .alert("Too Early", isPresented: $showTooEarlyAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This pothole is less than 30 days old. Liability not established.")
        }
        .sheet(item: $selectedPothole) { pothole in
            ClaimFormView(pothole: pothole)
        }
    }
    
    func performSearch() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchText) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                return
            }
            
            // Animate camera to the result
            withAnimation {
                camera = MapCameraPosition.region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
            }
        }
    }
}

// SIMPLE FORM (UI Only)
struct ClaimFormView: View {
    let pothole: Pothole
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Incident Details") {
                    LabeledContent("Date Reported", value: pothole.dateReported)
                    LabeledContent("Status") {
                        Text("Actionable (>30 Days)")
                            .foregroundStyle(.green)
                            .bold()
                    }
                }
                
                Section("Your Info") {
                    TextField("Full Name", text: $name)
                    TextField("Describe Damage", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section {
                    Button("Submit (Simulated)") {
                        print("Submit clicked for \(pothole.id)")
                        dismiss()
                    }
                    .bold()
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle("File Claim")
        }
    }
}

#Preview {
    ContentView()
}
