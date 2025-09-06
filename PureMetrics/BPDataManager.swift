import Foundation
import SwiftUI

class BPDataManager: ObservableObject {
    @Published var currentSession: BPSession
    @Published var sessions: [BPSession] = []
    
    private let maxReadingsPerSession = 5
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "BPSessions"
    
    init() {
        self.currentSession = BPSession()
        loadSessions()
    }
    
    // MARK: - Session Management
    
    func addReading(systolic: Int, diastolic: Int, heartRate: Int? = nil, timestamp: Date? = nil) -> Bool {
        guard currentSession.readings.count < maxReadingsPerSession else {
            return false
        }
        
        let reading = BloodPressureReading(systolic: systolic, diastolic: diastolic, heartRate: heartRate, timestamp: timestamp)
        guard reading.isValid else {
            return false
        }
        
        currentSession.addReading(reading)
        return true
    }
    
    func removeReading(at index: Int) {
        currentSession.removeReading(at: index)
    }
    
    func clearCurrentSession() {
        currentSession = BPSession()
    }
    
    func startSession() {
        currentSession = BPSession(startTime: Date())
    }
    
    func stopSession() {
        currentSession.stop()
    }
    
    func saveCurrentSession() {
        guard !currentSession.readings.isEmpty else { return }
        
        currentSession.complete()
        sessions.insert(currentSession, at: 0)
        saveSessions()
        clearCurrentSession()
    }
    
    func canAddReading() -> Bool {
        return currentSession.readings.count < maxReadingsPerSession && currentSession.isActive
    }
    
    // MARK: - Data Persistence
    
    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: sessionsKey)
        } catch {
            print("Error saving sessions: \(error)")
        }
    }
    
    private func loadSessions() {
        guard let data = userDefaults.data(forKey: sessionsKey) else { return }
        
        do {
            sessions = try JSONDecoder().decode([BPSession].self, from: data)
        } catch {
            print("Error loading sessions: \(error)")
            sessions = []
        }
    }
    
    // MARK: - Validation
    
    func isValidReading(systolic: Int, diastolic: Int, heartRate: Int? = nil) -> Bool {
        let reading = BloodPressureReading(systolic: systolic, diastolic: diastolic, heartRate: heartRate)
        return reading.isValid
    }
}
