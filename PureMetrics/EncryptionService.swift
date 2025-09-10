import Foundation
import CryptoKit
import Security

// MARK: - Encryption Service

class EncryptionService {
    static let shared = EncryptionService()
    
    private let keychain = KeychainService()
    private let keyTag = "PureMetrics.EncryptionKey"
    
    private init() {}
    
    // MARK: - Key Management
    
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to get existing key from keychain
        if let existingKeyData = keychain.getData(forKey: keyTag),
           let key = SymmetricKey(fromData: existingKeyData) {
            return key
        }
        
        // Create new key if none exists
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        // Store in keychain
        keychain.set(keyData, forKey: keyTag)
        
        return newKey
    }
    
    // MARK: - Encryption Methods
    
    func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        // Combine nonce, ciphertext, and tag
        var encryptedData = Data()
        encryptedData.append(sealedBox.nonce.withUnsafeBytes { Data($0) })
        encryptedData.append(sealedBox.ciphertext)
        encryptedData.append(sealedBox.tag)
        
        return encryptedData
    }
    
    func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        
        // Extract components
        let nonceSize = 12 // AES-GCM nonce size
        let tagSize = 16   // AES-GCM tag size
        
        guard encryptedData.count > nonceSize + tagSize else {
            throw EncryptionError.invalidData
        }
        
        let nonce = encryptedData.prefix(nonceSize)
        let tag = encryptedData.suffix(tagSize)
        let ciphertext = encryptedData.dropFirst(nonceSize).dropLast(tagSize)
        
        let sealedBox = try AES.GCM.SealedBox(
            nonce: try AES.GCM.Nonce(data: nonce),
            ciphertext: ciphertext,
            tag: tag
        )
        
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - String Encryption (for JSON data)
    
    func encryptString(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        
        let encryptedData = try encrypt(data)
        return encryptedData.base64EncodedString()
    }
    
    func decryptString(_ encryptedString: String) throws -> String {
        guard let encryptedData = Data(base64Encoded: encryptedString) else {
            throw EncryptionError.invalidData
        }
        
        let decryptedData = try decrypt(encryptedData)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidData
        }
        
        return string
    }
    
    // MARK: - Health Data Encryption
    
    func encryptHealthData<T: Codable>(_ data: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(data)
        return try encryptString(String(data: jsonData, encoding: .utf8) ?? "")
    }
    
    func decryptHealthData<T: Codable>(_ encryptedString: String, as type: T.Type) throws -> T {
        let decryptedString = try decryptString(encryptedString)
        guard let jsonData = decryptedString.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: jsonData)
    }
    
    // MARK: - Key Rotation
    
    func rotateEncryptionKey() throws {
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        // Store new key in keychain
        keychain.set(keyData, forKey: keyTag)
        
        print("Encryption key rotated successfully")
    }
    
    // MARK: - Security Validation
    
    func validateEncryption() -> Bool {
        do {
            let testData = "PureMetrics Test Data".data(using: .utf8)!
            let encrypted = try encrypt(testData)
            let decrypted = try decrypt(encrypted)
            return testData == decrypted
        } catch {
            print("Encryption validation failed: \(error)")
            return false
        }
    }
}

// MARK: - Keychain Service

class KeychainService {
    private let service = "com.puremetrics.app"
    
    func set(_ data: Data, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }
    
    func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        
        return nil
    }
    
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Encryption Errors

enum EncryptionError: LocalizedError {
    case invalidData
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data provided for encryption/decryption"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        }
    }
}

// MARK: - SymmetricKey Extension

extension SymmetricKey {
    init?(fromData data: Data) {
        guard data.count == 32 else { return nil } // 256 bits = 32 bytes
        let bytes = [UInt8](data)
        self.init(data: bytes)
    }
}
