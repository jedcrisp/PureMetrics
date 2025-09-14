import Foundation
import SwiftUI

// MARK: - Max Filter Settings Model

class MaxFilterSettings: ObservableObject {
    @Published var showWeightRecords: Bool = true
    @Published var showTimeRecords: Bool = true
    @Published var showDistanceRecords: Bool = true
    @Published var showRepRecords: Bool = true
    @Published var showVolumeRecords: Bool = true
    
    @Published var showMajorLifts: Bool = true
    @Published var showCustomLifts: Bool = true
    
    @Published var showRepEstimations: Bool = true
    @Published var show2RM: Bool = true
    @Published var show3RM: Bool = true
    @Published var show5RM: Bool = true
    @Published var show10RM: Bool = true
    
    @Published var showEpleyFormula: Bool = true
    @Published var showBrzyckiFormula: Bool = false
    
    @Published var sortBy: SortOption = .date
    @Published var sortOrder: SortOrder = .descending
    
    private let userDefaults = UserDefaults.standard
    private let filterSettingsKey = "MaxFilterSettings"
    
    init() {
        loadSettings()
    }
    
    // MARK: - Data Persistence
    
    private func loadSettings() {
        if let data = userDefaults.data(forKey: filterSettingsKey),
           let settings = try? JSONDecoder().decode(FilterSettingsData.self, from: data) {
            showWeightRecords = settings.showWeightRecords
            showTimeRecords = settings.showTimeRecords
            showDistanceRecords = settings.showDistanceRecords
            showRepRecords = settings.showRepRecords
            showVolumeRecords = settings.showVolumeRecords
            
            showMajorLifts = settings.showMajorLifts
            showCustomLifts = settings.showCustomLifts
            
            showRepEstimations = settings.showRepEstimations
            show2RM = settings.show2RM
            show3RM = settings.show3RM
            show5RM = settings.show5RM
            show10RM = settings.show10RM
            
            showEpleyFormula = settings.showEpleyFormula
            showBrzyckiFormula = settings.showBrzyckiFormula
            
            sortBy = SortOption(rawValue: settings.sortBy) ?? .date
            sortOrder = SortOrder(rawValue: settings.sortOrder) ?? .descending
        }
    }
    
    func saveSettings() {
        let settings = FilterSettingsData(
            showWeightRecords: showWeightRecords,
            showTimeRecords: showTimeRecords,
            showDistanceRecords: showDistanceRecords,
            showRepRecords: showRepRecords,
            showVolumeRecords: showVolumeRecords,
            showMajorLifts: showMajorLifts,
            showCustomLifts: showCustomLifts,
            showRepEstimations: showRepEstimations,
            show2RM: show2RM,
            show3RM: show3RM,
            show5RM: show5RM,
            show10RM: show10RM,
            showEpleyFormula: showEpleyFormula,
            showBrzyckiFormula: showBrzyckiFormula,
            sortBy: sortBy.rawValue,
            sortOrder: sortOrder.rawValue
        )
        
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: filterSettingsKey)
        }
    }
    
    // MARK: - Filter Logic
    
    func shouldShowRecord(_ record: OneRepMax, isCustom: Bool) -> Bool {
        // Check record type filter
        let typeFilter: Bool
        switch record.recordType {
        case .weight:
            typeFilter = showWeightRecords
        case .time:
            typeFilter = showTimeRecords
        case .distance:
            typeFilter = showDistanceRecords
        case .reps:
            typeFilter = showRepRecords
        case .volume:
            typeFilter = showVolumeRecords
        }
        
        // Check lift type filter
        let liftTypeFilter = isCustom ? showCustomLifts : showMajorLifts
        
        return typeFilter && liftTypeFilter
    }
    
    func shouldShowRepEstimation(_ reps: Int) -> Bool {
        guard showRepEstimations else { return false }
        
        switch reps {
        case 2: return show2RM
        case 3: return show3RM
        case 5: return show5RM
        case 10: return show10RM
        default: return false
        }
    }
    
    func getFilteredRecords(_ records: [OneRepMax], majorLifts: [String], customLifts: [String]) -> [OneRepMax] {
        let filtered = records.filter { record in
            let isCustom = customLifts.contains(record.liftName)
            return shouldShowRecord(record, isCustom: isCustom)
        }
        
        return sortRecords(filtered)
    }
    
    func getFilteredLifts(_ allLifts: [String], customLifts: [String]) -> [String] {
        return allLifts.filter { lift in
            let isCustom = customLifts.contains(lift)
            return isCustom ? showCustomLifts : showMajorLifts
        }
    }
    
    private func sortRecords(_ records: [OneRepMax]) -> [OneRepMax] {
        return records.sorted { first, second in
            let isAscending: Bool
            
            switch sortBy {
            case .date:
                isAscending = first.date < second.date
            case .name:
                isAscending = first.liftName < second.liftName
            case .value:
                isAscending = first.value < second.value
            case .type:
                isAscending = first.recordType.rawValue < second.recordType.rawValue
            }
            
            return sortOrder == .ascending ? isAscending : !isAscending
        }
    }
    
    // MARK: - Reset Functions
    
    func resetToDefaults() {
        showWeightRecords = true
        showTimeRecords = true
        showDistanceRecords = true
        showRepRecords = true
        showVolumeRecords = true
        
        showMajorLifts = true
        showCustomLifts = true
        
        showRepEstimations = true
        show2RM = true
        show3RM = true
        show5RM = true
        show10RM = true
        
        showEpleyFormula = true
        showBrzyckiFormula = false
        
        sortBy = .date
        sortOrder = .descending
        
        saveSettings()
    }
    
    func resetRecordTypeFilters() {
        showWeightRecords = true
        showTimeRecords = true
        showDistanceRecords = true
        showRepRecords = true
        showVolumeRecords = true
        saveSettings()
    }
    
    func resetLiftTypeFilters() {
        showMajorLifts = true
        showCustomLifts = true
        saveSettings()
    }
    
    func resetEstimationFilters() {
        showRepEstimations = true
        show2RM = true
        show3RM = true
        show5RM = true
        show10RM = true
        saveSettings()
    }
}

// MARK: - Supporting Types

enum SortOption: String, CaseIterable {
    case date = "Date"
    case name = "Name"
    case value = "Value"
    case type = "Type"
    
    var icon: String {
        switch self {
        case .date: return "calendar"
        case .name: return "textformat.abc"
        case .value: return "number"
        case .type: return "tag"
        }
    }
}

enum SortOrder: String, CaseIterable {
    case ascending = "Ascending"
    case descending = "Descending"
    
    var icon: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        }
    }
}

// MARK: - Codable Data Structure

private struct FilterSettingsData: Codable {
    let showWeightRecords: Bool
    let showTimeRecords: Bool
    let showDistanceRecords: Bool
    let showRepRecords: Bool
    let showVolumeRecords: Bool
    
    let showMajorLifts: Bool
    let showCustomLifts: Bool
    
    let showRepEstimations: Bool
    let show2RM: Bool
    let show3RM: Bool
    let show5RM: Bool
    let show10RM: Bool
    
    let showEpleyFormula: Bool
    let showBrzyckiFormula: Bool
    
    let sortBy: String
    let sortOrder: String
}
