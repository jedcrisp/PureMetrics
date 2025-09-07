import Foundation
import FirebaseStorage
import FirebaseAuth
import UIKit
import Combine

class StorageService: ObservableObject {
    private let storage = Storage.storage()
    private let authService = AuthService()
    
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading = false
    @Published var isDownloading = false
    
    // MARK: - Storage References
    
    private var userID: String? {
        return authService.currentUser?.uid
    }
    
    private func userStorageRef() -> StorageReference? {
        guard let userID = userID else { return nil }
        return storage.reference().child("users").child(userID)
    }
    
    // MARK: - Profile Image Upload
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userID = userID,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(StorageError.invalidImage))
            return
        }
        
        isUploading = true
        uploadProgress = 0.0
        
        let imageRef = userStorageRef()?.child("profile_images").child("\(userID)_\(Date().timeIntervalSince1970).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = imageRef?.putData(imageData, metadata: metadata) { [weak self] metadata, error in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                if let error = error {
                    completion(.failure(error))
                } else {
                    // Get download URL
                    imageRef?.downloadURL { url, error in
                        if let error = error {
                            completion(.failure(error))
                        } else if let downloadURL = url {
                            completion(.success(downloadURL.absoluteString))
                        }
                    }
                }
            }
        }
        
        // Monitor upload progress
        uploadTask?.observe(.progress) { [weak self] snapshot in
            guard let progress = snapshot.progress else { return }
            DispatchQueue.main.async {
                self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            }
        }
    }
    
    // MARK: - Workout Images Upload
    
    func uploadWorkoutImage(_ image: UIImage, workoutID: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userID = userID,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(StorageError.invalidImage))
            return
        }
        
        isUploading = true
        uploadProgress = 0.0
        
        let imageRef = userStorageRef()?.child("workout_images").child("\(workoutID)_\(Date().timeIntervalSince1970).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = imageRef?.putData(imageData, metadata: metadata) { [weak self] metadata, error in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                if let error = error {
                    completion(.failure(error))
                } else {
                    // Get download URL
                    imageRef?.downloadURL { url, error in
                        if let error = error {
                            completion(.failure(error))
                        } else if let downloadURL = url {
                            completion(.success(downloadURL.absoluteString))
                        }
                    }
                }
            }
        }
        
        // Monitor upload progress
        uploadTask?.observe(.progress) { [weak self] snapshot in
            guard let progress = snapshot.progress else { return }
            DispatchQueue.main.async {
                self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            }
        }
    }
    
    // MARK: - Data Backup Upload
    
    func uploadDataBackup(_ data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(StorageError.noUser))
            return
        }
        
        isUploading = true
        uploadProgress = 0.0
        
        let backupRef = userStorageRef()?.child("backups").child("backup_\(Date().timeIntervalSince1970).json")
        
        let metadata = StorageMetadata()
        metadata.contentType = "application/json"
        
        let uploadTask = backupRef?.putData(data, metadata: metadata) { [weak self] metadata, error in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                if let error = error {
                    completion(.failure(error))
                } else {
                    // Get download URL
                    backupRef?.downloadURL { url, error in
                        if let error = error {
                            completion(.failure(error))
                        } else if let downloadURL = url {
                            completion(.success(downloadURL.absoluteString))
                        }
                    }
                }
            }
        }
        
        // Monitor upload progress
        uploadTask?.observe(.progress) { [weak self] snapshot in
            guard let progress = snapshot.progress else { return }
            DispatchQueue.main.async {
                self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            }
        }
    }
    
    // MARK: - Image Download
    
    func downloadImage(from url: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let imageURL = URL(string: url) else {
            completion(.failure(StorageError.invalidURL))
            return
        }
        
        isDownloading = true
        
        URLSession.shared.dataTask(with: imageURL) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isDownloading = false
                
                if let error = error {
                    completion(.failure(error))
                } else if let data = data, let image = UIImage(data: data) {
                    completion(.success(image))
                } else {
                    completion(.failure(StorageError.invalidImage))
                }
            }
        }.resume()
    }
    
    // MARK: - Delete Files
    
    func deleteProfileImage(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(StorageError.noUser))
            return
        }
        
        let imageRef = userStorageRef()?.child("profile_images")
        
        imageRef?.listAll { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let result = result else {
                completion(.failure(StorageError.unknown))
                return
            }
            
            let group = DispatchGroup()
            var lastError: Error?
            
            for item in result.items {
                group.enter()
                item.delete { error in
                    if let error = error {
                        lastError = error
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                if let error = lastError {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func deleteWorkoutImages(workoutID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(StorageError.noUser))
            return
        }
        
        let workoutImagesRef = userStorageRef()?.child("workout_images")
        
        workoutImagesRef?.listAll { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let result = result else {
                completion(.failure(StorageError.unknown))
                return
            }
            
            let group = DispatchGroup()
            var lastError: Error?
            
            for item in result.items {
                if item.name.contains(workoutID) {
                    group.enter()
                    item.delete { error in
                        if let error = error {
                            lastError = error
                        }
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                if let error = lastError {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Storage Management
    
    func getStorageUsage(completion: @escaping (Result<StorageUsage, Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(StorageError.noUser))
            return
        }
        
        let userRef = userStorageRef()
        var totalSize: Int64 = 0
        var fileCount = 0
        
        let group = DispatchGroup()
        
        // Check profile images
        group.enter()
        userRef?.child("profile_images").listAll { result, error in
            if let error = error {
                print("Error listing profile images: \(error)")
            } else if let result = result {
                for item in result.items {
                    group.enter()
                    item.getMetadata { metadata, error in
                        if let size = metadata?.size {
                            totalSize += size
                            fileCount += 1
                        }
                        group.leave()
                    }
                }
            }
            group.leave()
        }
        
        // Check workout images
        group.enter()
        userRef?.child("workout_images").listAll { result, error in
            if let error = error {
                print("Error listing workout images: \(error)")
            } else if let result = result {
                for item in result.items {
                    group.enter()
                    item.getMetadata { metadata, error in
                        if let size = metadata?.size {
                            totalSize += size
                            fileCount += 1
                        }
                        group.leave()
                    }
                }
            }
            group.leave()
        }
        
        // Check backups
        group.enter()
        userRef?.child("backups").listAll { result, error in
            if let error = error {
                print("Error listing backups: \(error)")
            } else if let result = result {
                for item in result.items {
                    group.enter()
                    item.getMetadata { metadata, error in
                        if let size = metadata?.size {
                            totalSize += size
                            fileCount += 1
                        }
                        group.leave()
                    }
                }
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            let usage = StorageUsage(totalSize: totalSize, fileCount: fileCount)
            completion(.success(usage))
        }
    }
}

// MARK: - Storage Models

struct StorageUsage {
    let totalSize: Int64
    let fileCount: Int
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case noUser
    case invalidImage
    case invalidURL
    case uploadFailed
    case downloadFailed
    case deleteFailed
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No authenticated user found"
        case .invalidImage:
            return "Invalid image data"
        case .invalidURL:
            return "Invalid URL"
        case .uploadFailed:
            return "Upload failed"
        case .downloadFailed:
            return "Download failed"
        case .deleteFailed:
            return "Delete failed"
        case .networkError:
            return "Network error occurred"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
