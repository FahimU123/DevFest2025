//
//  Pothole.swift
//  DevFest2025
//
//  Created by Fahim Uddin on 11/21/25.
//

import Foundation
import CoreLocation

// 1. THE DATA MODEL
struct Pothole: Identifiable, Codable, Hashable {
    let id: String
    let lat: Double
    let long: Double
    let dateReported: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    var isActionable: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let reportDate = formatter.date(from: dateReported) else { return false }
        
        let days = Calendar.current.dateComponents([.day], from: reportDate, to: Date()).day ?? 0
        return days > 30
    }
}

// 2. THE MANAGER (Handles Data & Map Updates)
@Observable class PotholeManager {
    var potholes: [Pothole] = []
    
    init() {
        refreshData()
    }
    
    func refreshData() {
        var allData: [Pothole] = []
        
        // A. Load Static JSON (Red Pins)
        if let url = Bundle.main.url(forResource: "potholes", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Pothole].self, from: data) {
            allData.append(contentsOf: decoded)
        }
        
        // B. Load Siri Reports (Yellow Pins)
        if let data = UserDefaults.standard.data(forKey: "siri_reports"),
           let siriReports = try? JSONDecoder().decode([Pothole].self, from: data) {
            print("🎤 Found \(siriReports.count) Siri Reports")
            allData.append(contentsOf: siriReports)
        }
        
        self.potholes = allData
    }
}

import AppIntents
import Foundation

struct ReportPothole: AppIntent {
    static var title: LocalizedStringResource = "Report Pothole"
    static var description = IntentDescription("Logs hazard and sends directly to IBM Watson.")
    
    // --- CONFIGURATION (YOUR REAL KEYS) ---
    let ibmApiKey = "m3Dr8kSVw7d9FBP-2FPbnPCIRmpIPK891WhV6M4Ikl40"
    let ibmUrl = "https://api.us-south.natural-language-understanding.watson.cloud.ibm.com/instances/f31f1d3f-7172-4881-90c2-5ede109293bc/v1/analyze?version=2022-04-07"
    // --------------------------------------
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        
        // 1. GENERATE DATA
        let newID = UUID().uuidString
        let dateString = Date().formatted(date: .numeric, time: .omitted)
        let lat = 42.3595
        let long = -83.0725
        
        // 2. SAVE LOCALLY (Yellow Pin)
        let newReport = Pothole(id: newID, lat: lat, long: long, dateReported: "2025-11-21")
        saveToUserDefaults(report: newReport)
        
        // 3. SEND TO IBM
        do {
            try await sendDirectToWatson(lat: lat, long: long, date: dateString)
            return .result(value: "Reported. IBM Watson NLU has analyzed the data.")
        } catch {
            return .result(value: "Saved locally. Connection failed: \(error.localizedDescription)")
        }
    }
    
    // --- THE NETWORKING FUNCTION ---
    func sendDirectToWatson(lat: Double, long: Double, date: String) async throws {
        guard let url = URL(string: ibmUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // AUTHENTICATION
        let loginString = "apikey:\(ibmApiKey)"
        guard let loginData = loginString.data(using: .utf8) else { return }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        // PAYLOAD
        let textForAI = "Urgent: Pothole reported on \(date) at coordinates latitude \(lat), longitude \(long) in Michigan. High severity."
        
        let body: [String: Any] = [
            "text": textForAI,
            "features": [
                "keywords": [:],
                "entities": [
                    "mentions": true,
                    "sentiment": true,
                    "emotion": true
                ],
                "categories": [:]
            ],
            "language": "en"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("🚀 Sending Direct to IBM...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 IBM Status Code: \(httpResponse.statusCode)") // 200 = SUCCESS
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("🤖 IBM Response: \(json)")
        }
    }
    
    func saveToUserDefaults(report: Pothole) {
        var current = [Pothole]()
        if let data = UserDefaults.standard.data(forKey: "siri_reports"),
           let decoded = try? JSONDecoder().decode([Pothole].self, from: data) {
            current = decoded
        }
        current.append(report)
        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: "siri_reports")
        }
    }
}

// 🚀 REGISTER SHORTCUT WITH SIRI
struct CivicLoopShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ReportPothole(),
            phrases: [
                "Report Pothole in \(.applicationName)",
                "Log Pothole with \(.applicationName)",
                "Tell \(.applicationName) to report a hazard"
            ],
            shortTitle: "Report Pothole",
            systemImageName: "exclamationmark.triangle.fill"
        )
    }
}
