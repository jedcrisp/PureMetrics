import SwiftUI
import AVFoundation
import Vision
import UIKit

struct NutritionLabelScanner: View {
    @ObservedObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = false
    @State private var scannedNutrition: ScannedNutrition?
    @State private var showingConfirmation = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var isCameraReady = false
    @State private var cameraSetupTimeout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if cameraPermissionStatus == .authorized {
                    CameraView(
                        isScanning: $isScanning,
                        onNutritionDetected: { nutrition in
                            scannedNutrition = nutrition
                            // Auto-save the nutrition data
                            saveNutritionEntry(nutrition)
                            presentationMode.wrappedValue.dismiss()
                        },
                        onError: { error in
                            errorMessage = error
                            showingError = true
                        },
                        onCameraReady: {
                            isCameraReady = true
                        }
                    )
                    .ignoresSafeArea()
                    
                    VStack {
                        // Top section with instructions
                        VStack(spacing: 16) {
                            Text("Scan Nutrition Label")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 8) {
                                Text("Position the nutrition label within the frame")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("Ensure the text is clear and well-lit")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            if isScanning {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(isScanning ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isScanning)
                                    Text("Scanning nutrition label...")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Scanning frame overlay
                        VStack {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 280, height: 200)
                                .overlay(
                                    VStack {
                                        HStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.black, lineWidth: 2)
                                                )
                                            Spacer()
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.black, lineWidth: 2)
                                                )
                                        }
                                        Spacer()
                                        HStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.black, lineWidth: 2)
                                                )
                                            Spacer()
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.black, lineWidth: 2)
                                                )
                                        }
                                    }
                                    .padding(8)
                                )
                        }
                        
                        Spacer()
                        
                        // Control buttons
                        HStack(spacing: 20) {
                            Button("Cancel") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.8))
                            )
                            
                            Button(isScanning ? "Stop Scanning" : "Start Scanning") {
                                isScanning.toggle()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isScanning ? Color.orange : Color.blue)
                            )
                        }
                        .padding(.bottom, 50)
                    }
                } else if cameraPermissionStatus == .denied || cameraPermissionStatus == .restricted {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Camera Access Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Please enable camera access in Settings to scan nutrition labels.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding()
                } else if cameraSetupTimeout {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Camera Setup Failed")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Unable to initialize camera. Please try again.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Retry") {
                            cameraSetupTimeout = false
                            isCameraReady = false
                            checkCameraPermission()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Setting up camera...")
                            .font(.headline)
                        
                        Text("This may take a moment")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Scan Nutrition Label")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert("Scanning Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
        .onAppear {
            checkCameraPermission()
            
            // Set up timeout for camera initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if !isCameraReady && cameraPermissionStatus == .authorized {
                    print("Camera setup timeout - setting timeout flag")
                    cameraSetupTimeout = true
                }
            }
        }
    }
    
    private func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("Camera permission status: \(cameraPermissionStatus.rawValue)")
        
        switch cameraPermissionStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionStatus = granted ? .authorized : .denied
                    print("Camera permission granted: \(granted)")
                    
                    if granted {
                        self.isCameraReady = true
                    }
                }
            }
        case .authorized:
            isCameraReady = true
        case .denied, .restricted:
            // Permission denied or restricted
            break
        @unknown default:
            break
        }
    }
    
    private func saveNutritionEntry(_ nutrition: ScannedNutrition) {
        let entry = NutritionEntry(
            date: Date(),
            calories: Double(nutrition.calories ?? 0),
            protein: nutrition.protein ?? 0,
            carbohydrates: nutrition.carbohydrates ?? 0,
            fat: nutrition.fat ?? 0,
            sodium: nutrition.sodium ?? 0,
            sugar: nutrition.sugar ?? 0,
            fiber: nutrition.fiber ?? 0,
            water: 0,
            notes: "Scanned from nutrition label",
            label: nutrition.productName ?? "Scanned Product"
        )
        
        dataManager.addNutritionEntry(entry)
    }
}

struct CameraView: UIViewRepresentable {
    @Binding var isScanning: Bool
    let onNutritionDetected: (ScannedNutrition) -> Void
    let onError: (String) -> Void
    let onCameraReady: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let captureSession = AVCaptureSession()
        
        // Check camera authorization
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("CameraView - Authorization status: \(authStatus.rawValue)")
        if authStatus == .denied || authStatus == .restricted {
            onError("Camera access denied. Please enable camera access in Settings.")
            return view
        }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            onError("Camera not available on this device")
            return view
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            onError("Failed to create video input: \(error.localizedDescription)")
            return view
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            onError("Cannot add video input to capture session")
            return view
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            onError("Cannot add video output to capture session")
            return view
        }
        
        // Configure session
        captureSession.sessionPreset = .high
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer)
        
        // Ensure the preview layer updates its frame when the view bounds change
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        context.coordinator.captureSession = captureSession
        context.coordinator.previewLayer = previewLayer
        
        // Start session on background queue
        DispatchQueue.global(qos: .userInitiated).async {
            print("Starting camera session...")
            captureSession.startRunning()
            
            // Check if session is running
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if captureSession.isRunning {
                    print("Camera session started successfully")
                    onCameraReady()
                } else {
                    print("Camera session failed to start")
                    onError("Failed to start camera session")
                }
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view bounds change
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let parent: CameraView
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        private var lastScanTime = Date()
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard parent.isScanning else { return }
            
            // Throttle scanning to avoid too frequent processing
            let now = Date()
            guard now.timeIntervalSince(lastScanTime) > 2.0 else { return }
            lastScanTime = now
            
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Text recognition error: \(error.localizedDescription)")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else { 
                    print("No text observations found")
                    return 
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                print("Recognized text: \(recognizedText)")
                
                if let nutrition = self.parseNutritionLabel(from: recognizedText) {
                    print("Nutrition data found: \(nutrition)")
                    DispatchQueue.main.async {
                        self.parent.onNutritionDetected(nutrition)
                    }
                } else {
                    print("No nutrition data found in text")
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }
        
        private func parseNutritionLabel(from text: String) -> ScannedNutrition? {
            var nutrition = ScannedNutrition()
            var foundAnyData = false
            
            print("=== PARSING NUTRITION FROM TEXT ===")
            print("Full text: \(text)")
            
            // Clean and normalize text
            let cleanedText = text.replacingOccurrences(of: "\n", with: " ")
                                 .replacingOccurrences(of: "\r", with: " ")
                                 .replacingOccurrences(of: "  ", with: " ")
                                 .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let lowerText = cleanedText.lowercased()
            
            // Look for calories - try multiple patterns
            if let calories = extractCalories(from: lowerText) {
                nutrition.calories = calories
                foundAnyData = true
                print("✅ Found calories: \(calories)")
            }
            
            // Look for protein
            if let protein = extractNutrient(from: lowerText, keywords: ["protein", "prot", "proteins", "protéines"]) {
                nutrition.protein = protein
                foundAnyData = true
                print("✅ Found protein: \(protein)")
            }
            
            // Look for carbohydrates
            if let carbs = extractNutrient(from: lowerText, keywords: ["carbohydrate", "carbs", "carb", "carbohydrates", "total carbohydrate", "total carbs", "glucides"]) {
                nutrition.carbohydrates = carbs
                foundAnyData = true
                print("✅ Found carbs: \(carbs)")
            }
            
            // Look for fat
            if let fat = extractNutrient(from: lowerText, keywords: ["total fat", "fat", "fats", "total fats", "lipides", "matières grasses"]) {
                nutrition.fat = fat
                foundAnyData = true
                print("✅ Found fat: \(fat)")
            }
            
            // Look for fiber
            if let fiber = extractNutrient(from: lowerText, keywords: ["fiber", "fibre", "dietary fiber", "dietary fibre", "fibres"]) {
                nutrition.fiber = fiber
                foundAnyData = true
                print("✅ Found fiber: \(fiber)")
            }
            
            // Look for sugar
            if let sugar = extractNutrient(from: lowerText, keywords: ["sugar", "sugars", "total sugar", "total sugars", "sucres"]) {
                nutrition.sugar = sugar
                foundAnyData = true
                print("✅ Found sugar: \(sugar)")
            }
            
            // Look for sodium
            if let sodium = extractNutrient(from: lowerText, keywords: ["sodium", "salt", "na", "sel"]) {
                nutrition.sodium = sodium
                foundAnyData = true
                print("✅ Found sodium: \(sodium)")
            }
            
            // Look for serving size
            if let servingSize = extractServingSize(from: lowerText) {
                nutrition.servingSize = servingSize
                foundAnyData = true
                print("✅ Found serving size: \(servingSize)")
            }
            
            // If we found calories but no other nutrients, try a more aggressive approach
            if nutrition.calories != nil && !foundAnyData {
                print("🔍 Found calories but no other nutrients, trying aggressive extraction...")
                extractNutrientsAggressively(from: lowerText, nutrition: &nutrition)
            }
            
            print("=== PARSING COMPLETE ===")
            print("Found any data: \(foundAnyData)")
            
            // Only return nutrition if we found actual data
            if foundAnyData {
                print("Final nutrition object: \(nutrition)")
                return nutrition
            } else {
                print("⚠️ No nutrition data found in scanned text")
                return nil
            }
        }
        
        private func extractCalories(from text: String) -> Int? {
            // Look for patterns like "calories 150", "150 calories", "cal 150", "150 cal"
            let patterns = [
                #"calories?\s*(\d+)"#,
                #"(\d+)\s*calories?"#,
                #"cal\s*(\d+)"#,
                #"(\d+)\s*cal"#
            ]
            
            for pattern in patterns {
                if let number = extractNumberWithPattern(text, pattern: pattern) {
                    return Int(number)
                }
            }
            return nil
        }
        
        private func extractNutrient(from text: String, keywords: [String]) -> Double? {
            for keyword in keywords {
                // Look for patterns like "protein 25g", "25g protein", "protein: 25g", "protein 25", "25 protein"
                let patterns = [
                    #"\(keyword)\s*(\d+(?:\.\d+)?)\s*(?:g|mg|ml|%)"#,
                    #"(\d+(?:\.\d+)?)\s*(?:g|mg|ml|%)\s*\(keyword)"#,
                    #"\(keyword):\s*(\d+(?:\.\d+)?)"#,
                    #"\(keyword)\s*(\d+(?:\.\d+)?)"#,
                    #"(\d+(?:\.\d+)?)\s*\(keyword)"#,
                    #"\(keyword)\s*(\d+(?:\.\d+)?)\s*$"#,
                    #"^\s*(\d+(?:\.\d+)?)\s*\(keyword)"#
                ]
                
                for pattern in patterns {
                    if let number = extractNumberWithPattern(text, pattern: pattern) {
                        print("✅ Found \(keyword): \(number) using pattern: \(pattern)")
                        return number
                    }
                }
            }
            return nil
        }
        
        private func extractNumberWithPattern(_ text: String, pattern: String) -> Double? {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(location: 0, length: text.utf16.count)
                
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let matchRange = match.range(at: 1) // Get the first capture group
                    if let swiftRange = Range(matchRange, in: text) {
                        let numberString = String(text[swiftRange])
                        if let number = Double(numberString), number > 0 {
                            print("🔢 Extracted number '\(number)' using pattern '\(pattern)'")
                            return number
                        }
                    }
                }
            } catch {
                print("❌ Regex error: \(error)")
            }
            return nil
        }
        
        private func extractNutrientsAggressively(from text: String, nutrition: inout ScannedNutrition) {
            // Look for any number followed by 'g' or 'mg' and try to match with nearby keywords
            let lines = text.components(separatedBy: .newlines)
            
            for line in lines {
                let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Look for protein patterns
                if cleanLine.contains("protein") || cleanLine.contains("prot") {
                    if let protein = extractNumberWithPattern(cleanLine, pattern: #"(\d+(?:\.\d+)?)\s*(?:g|mg)"#) {
                        nutrition.protein = protein
                        print("🔍 Aggressively found protein: \(protein)")
                    }
                }
                
                // Look for carb patterns
                if cleanLine.contains("carb") || cleanLine.contains("carbohydrate") {
                    if let carbs = extractNumberWithPattern(cleanLine, pattern: #"(\d+(?:\.\d+)?)\s*(?:g|mg)"#) {
                        nutrition.carbohydrates = carbs
                        print("🔍 Aggressively found carbs: \(carbs)")
                    }
                }
                
                // Look for fat patterns
                if cleanLine.contains("fat") {
                    if let fat = extractNumberWithPattern(cleanLine, pattern: #"(\d+(?:\.\d+)?)\s*(?:g|mg)"#) {
                        nutrition.fat = fat
                        print("🔍 Aggressively found fat: \(fat)")
                    }
                }
                
                // Look for fiber patterns
                if cleanLine.contains("fiber") || cleanLine.contains("fibre") {
                    if let fiber = extractNumberWithPattern(cleanLine, pattern: #"(\d+(?:\.\d+)?)\s*(?:g|mg)"#) {
                        nutrition.fiber = fiber
                        print("🔍 Aggressively found fiber: \(fiber)")
                    }
                }
                
                // Look for sugar patterns
                if cleanLine.contains("sugar") {
                    if let sugar = extractNumberWithPattern(cleanLine, pattern: #"(\d+(?:\.\d+)?)\s*(?:g|mg)"#) {
                        nutrition.sugar = sugar
                        print("🔍 Aggressively found sugar: \(sugar)")
                    }
                }
                
                // Look for sodium patterns
                if cleanLine.contains("sodium") || cleanLine.contains("salt") || cleanLine.contains("na") {
                    if let sodium = extractNumberWithPattern(cleanLine, pattern: #"(\d+(?:\.\d+)?)\s*(?:g|mg)"#) {
                        nutrition.sodium = sodium
                        print("🔍 Aggressively found sodium: \(sodium)")
                    }
                }
            }
        }
        
        private func extractServingSize(from text: String) -> String? {
            let pattern = #"(\d+(?:\.\d+)?)\s*(g|ml|oz|cup|cups|tbsp|tsp|serving|servings)"#
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: text.utf16.count)
            
            if let match = regex?.firstMatch(in: text, options: [], range: range) {
                let matchRange = match.range
                if let swiftRange = Range(matchRange, in: text) {
                    return String(text[swiftRange])
                }
            }
            return nil
        }
        
        private func extractNumber(from text: String) -> Double? {
            // Try multiple patterns to find numbers
            let patterns = [
                #"(\d+(?:\.\d+)?)\s*(?:g|mg|ml|oz|cup|cups|tbsp|tsp|serving|servings|cal|calories)"#, // With units
                #"(\d+(?:\.\d+)?)\s*$"#, // At end of line
                #"(\d+(?:\.\d+)?)"# // Just numbers
            ]
            
            for pattern in patterns {
                let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(location: 0, length: text.utf16.count)
                
                if let match = regex?.firstMatch(in: text, options: [], range: range) {
                    let matchRange = match.range(at: 1) // Get the first capture group
                    if let swiftRange = Range(matchRange, in: text) {
                        let numberString = String(text[swiftRange])
                        if let number = Double(numberString), number > 0 {
                            print("🔢 Extracted number '\(number)' from '\(text)' using pattern '\(pattern)'")
                            return number
                        }
                    }
                }
            }
            
            print("❌ No number found in '\(text)'")
            return nil
        }
    }
}

struct ScannedNutrition {
    var servingSize: String?
    var calories: Int?
    var protein: Double?
    var carbohydrates: Double?
    var fat: Double?
    var fiber: Double?
    var sugar: Double?
    var naturalSugar: Double?
    var addedSugar: Double?
    var sodium: Double?
    var cholesterol: Double?
    var productName: String?
}

struct NutritionConfirmationView: View {
    let nutrition: ScannedNutrition
    @ObservedObject var dataManager: BPDataManager
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var foodName = ""
    @State private var servingSize = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbohydrates = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var sugar = ""
    @State private var sodium = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food Information")) {
                    TextField("Food Name", text: $foodName)
                    TextField("Serving Size", text: $servingSize)
                }
                
                Section(header: Text("Nutrition Facts")) {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", text: $calories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("0", text: $protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Carbohydrates (g)")
                        Spacer()
                        TextField("0", text: $carbohydrates)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("0", text: $fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Fiber (g)")
                        Spacer()
                        TextField("0", text: $fiber)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Sugar (g)")
                        Spacer()
                        TextField("0", text: $sugar)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Sodium (mg)")
                        Spacer()
                        TextField("0", text: $sodium)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Confirm Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNutritionEntry()
                    }
                    .disabled(foodName.isEmpty || calories.isEmpty)
                }
            }
        }
        .onAppear {
            populateFields()
        }
    }
    
    private func populateFields() {
        servingSize = nutrition.servingSize ?? ""
        calories = nutrition.calories?.description ?? ""
        protein = nutrition.protein?.description ?? ""
        carbohydrates = nutrition.carbohydrates?.description ?? ""
        fat = nutrition.fat?.description ?? ""
        fiber = nutrition.fiber?.description ?? ""
        sugar = nutrition.sugar?.description ?? ""
        sodium = nutrition.sodium?.description ?? ""
    }
    
    private func saveNutritionEntry() {
        let entry = NutritionEntry(
            date: Date(),
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbohydrates: Double(carbohydrates) ?? 0,
            fat: Double(fat) ?? 0,
            sodium: Double(sodium) ?? 0,
            sugar: Double(sugar) ?? 0,
            fiber: Double(fiber) ?? 0,
            label: foodName.isEmpty ? nil : foodName
        )
        
        dataManager.addNutritionEntry(entry)
        onSave()
    }
}

#Preview {
    NutritionLabelScanner(dataManager: BPDataManager())
}
