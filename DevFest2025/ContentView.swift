//
//  ContentView.swift
//  DevFest2025
//
//  Created by Fahim Uddin on 11/21/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @State private var manager = PotholeManager()
    
    // Start at Wayne State
    @State private var camera = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.3589, longitude: -83.0712),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
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
            
            // SEARCH BAR
            .searchable(text: $searchText, prompt: "Search highways, cities...")
            .onSubmit(of: .search) { performSearch() }
            

        }
        .alert("Too Early", isPresented: $showTooEarlyAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This pothole is less than 30 days old. Liability not established.")
        }
        .sheet(item: $selectedPothole) { pothole in
            ClaimFormView(pothole: pothole)
        }
        // SIRI LISTENER
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            manager.refreshData()
        }
    }
    
    func performSearch() {
        // 1. THE HACK: If we type "Ford", force it to go to our Pins
        if searchText.localizedCaseInsensitiveContains("Ford") {
            let fordFieldCoords = CLLocationCoordinate2D(latitude: 42.3400, longitude: -83.0456)
            
            withAnimation {
                camera = MapCameraPosition.region(MKCoordinateRegion(
                    center: fordFieldCoords,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
            // Close keyboard
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            return
        }
        
        // 2. Normal Search for everything else
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchText) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else { return }
            withAnimation {
                camera = MapCameraPosition.region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
            }
        }
    }
    
    // MANUAL TEST FUNCTION
    func runManualTest() {
        print("⚡️ User clicked Test Button...")
        Task {
            let intent = ReportPothole()
            try? await intent.sendDirectToWatson(lat: 42.33, long: -83.05, date: "2025-11-21")
        }
    }
}
#Preview {
    ContentView()
}

import SwiftUI

struct ClaimFormView: View {
    let pothole: Pothole
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Evidence") {
                    LabeledContent("Date Reported", value: pothole.dateReported)
                    LabeledContent("Status") {
                        Text("Actionable (>30 Days)")
                            .foregroundStyle(.green)
                            .bold()
                    }
                }
                
                Section("Claimant Info") {
                    TextField("Full Name", text: $name)
                    TextField("Describe Damage", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section {
                    Button(action: submitClaim) {
                        if isSubmitting {
                            Text("Consulting IBM Watson...")
                                .foregroundStyle(.gray)
                        } else {
                            Text("Submit Legal Claim")
                                .bold()
                                .foregroundStyle(.blue)
                        }
                    }
                    .disabled(name.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("File Claim")
            .alert("Success", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your claim has been generated and emailed to the county.")
            }
        }
    }
    
    func submitClaim() {
        isSubmitting = true
        // Mock Delay to simulate AI
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSubmitting = false
            showSuccess = true
        }
    }
}
