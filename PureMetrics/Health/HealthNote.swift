import Foundation
import FirebaseFirestore

struct HealthNote: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let metricType: String // "weight", "bodyFatPercentage", "leanBodyMass", "totalCalories", "steps"
    let date: Date
    let note: String
    let createdAt: Date
    let updatedAt: Date
    
    init(userId: String, metricType: String, date: Date, note: String) {
        self.userId = userId
        self.metricType = metricType
        self.date = date
        self.note = note
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(id: String, userId: String, metricType: String, date: Date, note: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.metricType = metricType
        self.date = date
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "metricType": metricType,
            "date": Timestamp(date: date),
            "note": note,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any], documentId: String) -> HealthNote? {
        guard let userId = data["userId"] as? String,
              let metricType = data["metricType"] as? String,
              let note = data["note"] as? String else {
            return nil
        }
        
        let date: Date
        if let timestamp = data["date"] as? Timestamp {
            date = timestamp.dateValue()
        } else if let dateValue = data["date"] as? Date {
            date = dateValue
        } else {
            return nil
        }
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let dateValue = data["createdAt"] as? Date {
            createdAt = dateValue
        } else {
            createdAt = Date()
        }
        
        let updatedAt: Date
        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else if let dateValue = data["updatedAt"] as? Date {
            updatedAt = dateValue
        } else {
            updatedAt = Date()
        }
        
        return HealthNote(
            id: documentId,
            userId: userId,
            metricType: metricType,
            date: date,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
