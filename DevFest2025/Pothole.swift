//
//  Pothole.swift
//  DevFest2025
//
//  Created by Fahim Uddin on 11/21/25.
//

import Foundation
import Observation
import CoreLocation

// 1. THE MODEL
struct Pothole: Identifiable, Codable, Hashable {
    let id: String
    let lat: Double
    let long: Double
    let dateReported: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    // The Logic: Is it older than 30 days?
    var isActionable: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let reportDate = formatter.date(from: dateReported) else { return false }
        
        let days = Calendar.current.dateComponents([.day], from: reportDate, to: Date()).day ?? 0
        return days > 30
    }
}

// 2. THE VIEW MODEL (Using iOS 17 @Observable)
@Observable class PotholeManager {
    var potholes: [Pothole] = []
    
    init() {
        loadData()
    }
    
    func loadData() {
        guard let url = Bundle.main.url(forResource: "potholes", withExtension: "json") else {
            print("Error: potholes.json not found in project bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.potholes = try JSONDecoder().decode([Pothole].self, from: data)
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }
}
