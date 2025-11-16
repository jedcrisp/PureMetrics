import Foundation
import FirebaseFirestore

// MARK: - Coach-Client Invitation Models

struct CoachInvitation: Codable, Identifiable {
    let id: String
    let coachID: String
    let clientID: String
    let coachEmail: String
    let coachName: String?
    let clientEmail: String
    let clientName: String?
    let status: InvitationStatus
    let createdAt: Date
    let updatedAt: Date
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case coachID = "coach_id"
        case clientID = "client_id"
        case coachEmail = "coach_email"
        case coachName = "coach_name"
        case clientEmail = "client_email"
        case clientName = "client_name"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case message
    }
    
    init(id: String = UUID().uuidString,
         coachID: String,
         clientID: String,
         coachEmail: String,
         coachName: String? = nil,
         clientEmail: String,
         clientName: String? = nil,
         status: InvitationStatus = .pending,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         message: String? = nil) {
        self.id = id
        self.coachID = coachID
        self.clientID = clientID
        self.coachEmail = coachEmail
        self.coachName = coachName
        self.clientEmail = clientEmail
        self.clientName = clientName
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.message = message
    }
}

enum InvitationStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case cancelled = "cancelled"
}

// MARK: - Coach-Client Relationship Model

struct CoachClientRelationship: Codable, Identifiable {
    let id: String
    let coachID: String
    let clientID: String
    let coachEmail: String
    let coachName: String?
    let clientEmail: String
    let clientName: String?
    let createdAt: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case coachID = "coach_id"
        case clientID = "client_id"
        case coachEmail = "coach_email"
        case coachName = "coach_name"
        case clientEmail = "client_email"
        case clientName = "client_name"
        case createdAt = "created_at"
        case isActive = "is_active"
    }
    
    init(id: String = UUID().uuidString,
         coachID: String,
         clientID: String,
         coachEmail: String,
         coachName: String? = nil,
         clientEmail: String,
         clientName: String? = nil,
         createdAt: Date = Date(),
         isActive: Bool = true) {
        self.id = id
        self.coachID = coachID
        self.clientID = clientID
        self.coachEmail = coachEmail
        self.coachName = coachName
        self.clientEmail = clientEmail
        self.clientName = clientName
        self.createdAt = createdAt
        self.isActive = isActive
    }
}

// MARK: - Client Info Model (for coach dashboard)

struct ClientInfo: Identifiable {
    let id: String
    let email: String
    let name: String?
    let relationshipID: String
    let joinedDate: Date
    
    init(from relationship: CoachClientRelationship, isCoach: Bool) {
        self.id = isCoach ? relationship.clientID : relationship.coachID
        self.email = isCoach ? relationship.clientEmail : relationship.coachEmail
        self.name = isCoach ? relationship.clientName : relationship.coachName
        self.relationshipID = relationship.id
        self.joinedDate = relationship.createdAt
    }
}

