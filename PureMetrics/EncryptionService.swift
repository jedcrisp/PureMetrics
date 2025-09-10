import Foundation
import CryptoKit
import Security

// MARK: - Encryption Service

class EncryptionService {
    static let shared = EncryptionService()
    
    private let keychain = Keychain()
    private let keyIdentifier = "PureMetrics.EncryptionKey"
    
    private init() {}
    
    // MARK: - Key Management
    
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to load existing key from Keychain
        if let existingKeyData = keychain.load(forKey: keyIdentifier) {
            return SymmetricKey(data: existingKeyData)
        }
        
        // Generate new key if none exists
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        // Save to Keychain
        try keychain.save(keyData, forKey: keyIdentifier)
        
        return newKey
    }
    
    func rotateEncryptionKey() throws {
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        // Save new key to Keychain
        try keychain.save(keyData, forKey: keyIdentifier)
    }
    
    // MARK: - Encryption Methods
    
    func encryptHealthData<T: Codable>(_ data: T) throws -> String {
        let key = try getOrCreateEncryptionKey()
        
        // Encode data to JSON
        let jsonData = try JSONEncoder().encode(data)
        
        // Encrypt using AES-256-GCM
        let sealedBox = try AES.GCM.seal(jsonData, using: key)
        
        // Combine nonce, ciphertext, and tag
        let encryptedData = sealedBox.combined!
        
        // Encode to base64 for storage
        return encryptedData.base64EncodedString()
    }
    
    func decryptHealthData<T: Codable>(_ encryptedString: String, as type: T.Type) throws -> T {
        let key = try getOrCreateEncryptionKey()
        
        // Decode from base64
        guard let encryptedData = Data(base64Encoded: encryptedString) else {
            throw EncryptionError.invalidData
        }
        
        // Create sealed box from combined data
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        
        // Decrypt
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        // Decode from JSON
        return try JSONDecoder().decode(type, from: decryptedData)
    }
    
    // MARK: - Validation
    
    func validateEncryption() -> Bool {
        do {
            // Test encryption and decryption with sample data
            let testData = HealthMetric(type: .weight, value: 150.0, timestamp: Date())
            let encrypted = try encryptHealthData(testData)
            let decrypted: HealthMetric = try decryptHealthData(encrypted, as: HealthMetric.self)
            
            return decrypted.value == testData.value && 
                   decrypted.type == testData.type
        } catch {
            print("Encryption validation failed: \(error)")
            return false
        }
    }
    
    // MARK: - Bulk Operations
    
    func encryptHealthDataArray<T: Codable>(_ dataArray: [T]) throws -> [String] {
        return try dataArray.map { try encryptHealthData($0) }
    }
    
    func decryptHealthDataArray<T: Codable>(_ encryptedStrings: [String], as type: T.Type) throws -> [T] {
        return try encryptedStrings.map { try decryptHealthData($0, as: type) }
    }
    
    // MARK: - Secure Deletion
    
    func deleteEncryptionKey() throws {
        try keychain.delete(forKey: keyIdentifier)
    }
    
    func deleteAllEncryptedData() throws {
        // This would need to be implemented based on your data storage strategy
        // For now, we just delete the encryption key
        try deleteEncryptionKey()
    }
}

// MARK: - Keychain Helper

private class Keychain {
    private let service = "com.puremetrics.app"
    
    func save(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }
    
    func load(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return result as? Data
    }
    
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw EncryptionError.keychainError(status)
        }
    }
}

// MARK: - Encryption Errors

enum EncryptionError: LocalizedError {
    case invalidData
    case keychainError(OSStatus)
    case encryptionFailed
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid encrypted data format"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        }
    }
}

// MARK: - Health Metric Extension for Testing

extension HealthMetric {
    // This is used for encryption validation
    // The actual HealthMetric type should be defined elsewhere in your project
}

// MARK: - Usage Examples

/*
 
 // Encrypt a single health metric
 let encryptionService = EncryptionService.shared
 let metric = HealthMetric(type: .weight, value: 150.0, timestamp: Date())
 let encryptedString = try encryptionService.encryptHealthData(metric)
 
 // Decrypt the health metric
 let decryptedMetric: HealthMetric = try encryptionService.decryptHealthData(encryptedString, as: HealthMetric.self)
 
 // Encrypt an array of health data
 let metrics = [metric1, metric2, metric3]
 let encryptedStrings = try encryptionService.encryptHealthDataArray(metrics)
 
 // Decrypt the array
 let decryptedMetrics: [HealthMetric] = try encryptionService.decryptHealthDataArray(encryptedStrings, as: HealthMetric.self)
 
 // Validate encryption is working
 if encryptionService.validateEncryption() {
     print("Encryption is working correctly")
 }
 
 // Rotate encryption key (for security)
 try encryptionService.rotateEncryptionKey()
 
 // Delete encryption key (for secure deletion)
 try encryptionService.deleteEncryptionKey()
 
 */