import SwiftUI
import AVFoundation
import UIKit

struct BarcodeScanner: View {
    @ObservedObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = false
    @State private var scannedBarcode: String?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var isCameraReady = false
    @State private var cameraSetupTimeout = false
    @State private var nutritionData: ScannedNutrition?
    @State private var isLoading = false
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var hasScanned = false
    @State private var showingTemplateCreation = false
    @State private var servingAmount: Double = 1.0
    @State private var servingAmountText: String = "1.0"
    @State private var servingSizeUnit: String = "serving"
    @State private var templateName: String = ""
    @State private var selectedCategory: String = NutritionTemplateCategory.general.rawValue
    
    // Editable nutrition values
    @State private var editableCalories: String = ""
    @State private var editableProtein: String = ""
    @State private var editableCarbs: String = ""
    @State private var editableFat: String = ""
    @State private var editableSodium: String = ""
    @State private var editableSugar: String = ""
    @State private var editableNaturalSugar: String = ""
    @State private var editableAddedSugar: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if cameraPermissionStatus == .authorized {
                    BarcodeCameraView(
                        isScanning: $isScanning,
                        onBarcodeDetected: { barcode in
                            // Prevent multiple scans of the same barcode
                            guard !hasScanned else { return }
                            hasScanned = true
                            scannedBarcode = barcode
                            fetchNutritionData(for: barcode)
                        },
                        onError: { error in
                            errorMessage = error
                            showingError = true
                        },
                        onCameraReady: {
                            isCameraReady = true
                            // Auto-start scanning when camera is ready
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isScanning = true
                            }
                        }
                    )
                    .ignoresSafeArea()
                    
                    // Overlay UI
                    VStack {
                        // Top section with instructions
                        VStack(spacing: 20) {
                            // Header with icon and title
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "barcode.viewfinder")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Scan Product Barcode")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            // Status indicator
                            VStack(spacing: 12) {
                                if isLoading {
                                    HStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                        Text("Fetching nutrition data...")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.blue.opacity(0.8))
                                    )
                                } else if showingSuccess {
                                    VStack(spacing: 12) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.green)
                                            Text(successMessage)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.green)
                                        }
                                        
                                        Button("Scan Another") {
                                            resetScanner()
                                            isScanning = true
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.blue.opacity(0.8))
                                        )
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.green.opacity(0.2))
                                    )
                                } else if isScanning {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 10, height: 10)
                                            .scaleEffect(isScanning ? 1.3 : 1.0)
                                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isScanning)
                                        Text("Scanning...")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.green.opacity(0.2))
                                    )
                                } else {
                                    VStack(spacing: 8) {
                                        Text("Position the barcode within the scanning area")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Text("Ensure good lighting and hold steady")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        // Scanning frame overlay with improved design
                        VStack {
                            ZStack {
                                // Outer glow effect
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    .frame(width: 280, height: 180)
                                
                                // Main scanning frame
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 260, height: 160)
                                    .overlay(
                                        VStack {
                                            HStack {
                                                // Top-left corner
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.white)
                                                        .frame(width: 30, height: 4)
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.white)
                                                        .frame(width: 4, height: 30)
                                                }
                                                Spacer()
                                                // Top-right corner
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.white)
                                                        .frame(width: 30, height: 4)
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.white)
                                                        .frame(width: 4, height: 30)
                                                }
                                            }
                                            Spacer()
                                            HStack {
                                                // Bottom-left corner
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.white)
                                                        .frame(width: 4, height: 30)
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.white)
                                                        .frame(width: 30, height: 4)
                                                }
                                                Spacer()
                                                // Bottom-right corner
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.white)
                                                        .frame(width: 4, height: 30)
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.white)
                                                        .frame(width: 30, height: 4)
                                                }
                                            }
                                        }
                                        .padding(12)
                                    )
                                
                                // Scanning line animation
                                if isScanning {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.clear, Color.green, Color.clear],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 240, height: 3)
                                        .offset(y: -20)
                                        .animation(
                                            .easeInOut(duration: 2.0)
                                            .repeatForever(autoreverses: true),
                                            value: isScanning
                                        )
                                }
                            }
                            
                            // Instructions below frame
                            Text("Align barcode within the frame")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 12)
                        }
                        
                        Spacer()
                        
                        // Bottom control - only Cancel button
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.red.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.bottom, 50)
                    }
                } else if cameraPermissionStatus == .denied || cameraPermissionStatus == .restricted {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Camera Access Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Please allow camera access to scan barcodes")
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
            .navigationBarHidden(true)
            .onAppear {
                resetScanner()
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
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
        .sheet(isPresented: $showingTemplateCreation) {
            templateCreationSheet
        }
    }
    
    private var templateCreationSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let nutrition = nutritionData {
                        // Product Info Header
                        VStack(spacing: 12) {
                            Text("Create Custom Template")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(nutrition.productName ?? "Scanned Product")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top)
                        
                        // Template Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Template Name")
                                .font(.headline)
                            TextField("Enter template name", text: $templateName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    
                    // Category Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(NutritionTemplateCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category.rawValue)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Serving Size and Amount
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Serving Size")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            // Quantity input
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Amount")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("1.0", text: $servingAmountText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .onChange(of: servingAmountText) { newValue in
                                        if let amount = Double(newValue), amount > 0 {
                                            servingAmount = amount
                                            // Removed automatic recalculation - serving size changes no longer affect nutritional values
                                        }
                                    }
                            }
                            
                            // Unit input
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Unit")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("serving", text: $servingSizeUnit)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        // Quick unit buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["serving", "cup", "cups", "tbsp", "tsp", "oz", "ml", "g", "piece", "slice"], id: \.self) { unit in
                                    Button(unit) {
                                        servingSizeUnit = unit
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(servingSizeUnit == unit ? Color.blue : Color(.systemGray5))
                                    )
                                    .foregroundColor(servingSizeUnit == unit ? .white : .primary)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    // Editable Nutrition Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nutrition Information (per \(servingSizeUnit))")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            EditableNutritionCard(
                                title: "Calories",
                                value: $editableCalories,
                                unit: "kcal",
                                baseValue: Double(nutrition.calories ?? 0),
                                servingAmount: servingAmount
                            )
                            EditableNutritionCard(
                                title: "Protein",
                                value: $editableProtein,
                                unit: "g",
                                baseValue: nutrition.protein ?? 0,
                                servingAmount: servingAmount
                            )
                            EditableNutritionCard(
                                title: "Carbs",
                                value: $editableCarbs,
                                unit: "g",
                                baseValue: nutrition.carbohydrates ?? 0,
                                servingAmount: servingAmount
                            )
                            EditableNutritionCard(
                                title: "Fat",
                                value: $editableFat,
                                unit: "g",
                                baseValue: nutrition.fat ?? 0,
                                servingAmount: servingAmount
                            )
                            EditableNutritionCard(
                                title: "Sodium",
                                value: $editableSodium,
                                unit: "mg",
                                baseValue: (nutrition.sodium ?? 0) / 1000, // Convert mg to g for base calculation
                                servingAmount: servingAmount
                            )
                            EditableNutritionCard(
                                title: "Total Sugar",
                                value: $editableSugar,
                                unit: "g",
                                baseValue: nutrition.sugar ?? 0,
                                servingAmount: servingAmount
                            )
                            EditableNutritionCard(
                                title: "Natural Sugar",
                                value: $editableNaturalSugar,
                                unit: "g",
                                baseValue: nutrition.naturalSugar ?? 0,
                                servingAmount: servingAmount
                            )
                            EditableNutritionCard(
                                title: "Added Sugar",
                                value: $editableAddedSugar,
                                unit: "g",
                                baseValue: nutrition.addedSugar ?? 0,
                                servingAmount: servingAmount
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: createTemplate) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Template")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                showingTemplateCreation = false
                                resetScanner()
                                isScanning = true
                            }) {
                                HStack {
                                    Image(systemName: "barcode.viewfinder")
                                    Text("Scan Another")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showingTemplateCreation = false
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Done")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    }
                }
                .padding()
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                showingTemplateCreation = false
                presentationMode.wrappedValue.dismiss()
            })
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    // MARK: - Private Helper Functions
    
    private struct NutritionPreviewCard: View {
        let title: String
        let value: String
        let unit: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color.white)
            .cornerRadius(8)
        }
    }
    
    private func createTemplate() {
        guard let nutrition = nutritionData else { 
            print("🔍 DEBUG: No nutrition data available for template creation")
            return 
        }
        
        // Create custom template with editable values
        let template = CustomNutritionTemplate(
            name: templateName.isEmpty ? (nutrition.productName ?? "Scanned Item") : templateName,
            calories: Double(editableCalories) ?? (Double(nutrition.calories ?? 0) * servingAmount),
            protein: Double(editableProtein) ?? ((nutrition.protein ?? 0) * servingAmount),
            carbohydrates: Double(editableCarbs) ?? ((nutrition.carbohydrates ?? 0) * servingAmount),
            fat: Double(editableFat) ?? ((nutrition.fat ?? 0) * servingAmount),
            sodium: (Double(editableSodium) ?? ((nutrition.sodium ?? 0) * servingAmount)) * 1000, // Convert back to mg
            sugar: Double(editableSugar) ?? ((nutrition.sugar ?? 0) * servingAmount),
            naturalSugar: Double(editableNaturalSugar) ?? ((nutrition.naturalSugar ?? 0) * servingAmount),
            addedSugar: Double(editableAddedSugar) ?? ((nutrition.addedSugar ?? 0) * servingAmount),
            fiber: round((nutrition.fiber ?? 0) * servingAmount * 10) / 10,
            cholesterol: round((nutrition.cholesterol ?? 0) * servingAmount * 10) / 10,
            water: 0,
            servingSize: "\(servingAmountText) \(servingSizeUnit)",
            category: selectedCategory,
            notes: nil
        )
        
        print("🔍 DEBUG: Creating template with name: '\(template.name)'")
        print("🔍 DEBUG: Template serving size: '\(template.servingSize)'")
        print("🔍 DEBUG: Template category: '\(template.category)'")
        print("🔍 DEBUG: Template calories: \(template.calories)")
        
        // Add template to data manager
        print("🔍 DEBUG: Adding custom nutrition template: \(template.name)")
        dataManager.addCustomNutritionTemplate(template)
        print("🔍 DEBUG: Template added to data manager. Total templates: \(dataManager.customNutritionTemplates.count)")
        
        // Show success message but keep scanner open
        successMessage = "Template created successfully!"
        showingSuccess = true
        showingTemplateCreation = false
        
        // Reset editable values for next scan
        resetEditableValues()
        
        // Auto-hide success message after 3 seconds but keep scanner open
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showingSuccess = false
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
    
    private func fetchNutritionData(for barcode: String) {
        isLoading = true
        print("Fetching nutrition data for barcode: \(barcode)")
        
        // Validate barcode format
        guard isValidBarcode(barcode) else {
            errorMessage = "Invalid barcode format. Please try scanning again."
            showingError = true
            isLoading = false
            return
        }
        
        // Try to fetch from Open Food Facts API first
        fetchFromOpenFoodFacts(barcode: barcode) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let nutrition):
                    self.nutritionData = nutrition
                    // Set default template name from product name (already capitalized)
                    self.templateName = nutrition.productName ?? "Scanned Item"
                    // Set default serving size unit from scanned data
                    self.servingSizeUnit = self.extractUnitFromServingSize(nutrition.servingSize ?? "1 serving")
                    // Initialize editable nutrition values
                    self.initializeEditableValues(from: nutrition)
                    // Show template creation screen
                    self.showingTemplateCreation = true
                case .failure(let error):
                    print("API fetch failed: \(error)")
                    // Fall back to sample data for testing
                    let sampleNutrition = self.createSampleNutritionData(for: barcode)
                    self.nutritionData = sampleNutrition
                    self.templateName = sampleNutrition.productName ?? "Sample Product"
                    // Initialize editable nutrition values
                    self.initializeEditableValues(from: sampleNutrition)
                    self.showingTemplateCreation = true
                }
            }
        }
    }
    
    private func isValidBarcode(_ barcode: String) -> Bool {
        // Check if barcode is numeric and has valid length
        let numericBarcode = barcode.replacingOccurrences(of: " ", with: "")
        return numericBarcode.allSatisfy { $0.isNumber } && 
               (numericBarcode.count == 8 || numericBarcode.count == 12 || numericBarcode.count == 13)
    }
    
    private func fetchFromOpenFoodFacts(barcode: String, completion: @escaping (Result<ScannedNutrition, Error>) -> Void) {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let status = json?["status"] as? Int, status == 1,
                   let product = json?["product"] as? [String: Any],
                   let nutriments = product["nutriments"] as? [String: Any] {
                    
                    // Get serving size and calculate conversion factor
                    let servingSize = product["serving_size"] as? String ?? "100g"
                    let productName = product["product_name"] as? String
                    let density = self.getDensityForProduct(productName: productName, servingSize: servingSize)
                    let servingWeight = self.extractServingWeightWithDensity(from: servingSize, density: density)
                    let conversionFactor = servingWeight / 100.0 // Convert from per 100g to per serving
                    
                    // Debug logging
                    print("🔍 DEBUG - Product: \(productName ?? "Unknown")")
                    print("🔍 DEBUG - Serving Size: \(servingSize)")
                    print("🔍 DEBUG - Density: \(density)")
                    print("🔍 DEBUG - Serving Weight: \(servingWeight)")
                    print("🔍 DEBUG - Conversion Factor: \(conversionFactor)")
                    
                    // For fluid products, we might need to adjust density calculations
                    let isFluid = self.isFluidProduct(servingSize: servingSize)
                    
                    // Debug raw nutrition values from API
                    let rawCalories = self.extractNutrientValue(from: nutriments, key: "energy-kcal_100g") ?? self.extractNutrientValue(from: nutriments, key: "energy_100g").map { $0 / 4.184 }
                    let rawProtein = self.extractNutrientValue(from: nutriments, key: "proteins_100g")
                    let rawCarbs = self.extractNutrientValue(from: nutriments, key: "carbohydrates_100g")
                    let rawFat = self.extractNutrientValue(from: nutriments, key: "fat_100g")
                    let rawSodium = self.extractNutrientValue(from: nutriments, key: "sodium_100g")
                    let rawSugar = self.extractNutrientValue(from: nutriments, key: "sugars_100g")
                    
                    print("🔍 DEBUG - Raw API values (per 100g):")
                    print("  Calories: \(rawCalories ?? 0)")
                    print("  Protein: \(rawProtein ?? 0)")
                    print("  Carbs: \(rawCarbs ?? 0)")
                    print("  Fat: \(rawFat ?? 0)")
                    print("  Sodium: \(rawSodium ?? 0)")
                    print("  Sugar: \(rawSugar ?? 0)")
                    
                    let nutrition = ScannedNutrition(
                        servingSize: servingSize,
                        calories: rawCalories.map { Int($0 * conversionFactor) },
                        protein: rawProtein.map { $0 * conversionFactor },
                        carbohydrates: rawCarbs.map { $0 * conversionFactor },
                        fat: rawFat.map { $0 * conversionFactor },
                        fiber: self.extractNutrientValue(from: nutriments, key: "fiber_100g").map { $0 * conversionFactor },
                        sugar: rawSugar.map { $0 * conversionFactor },
                        addedSugar: self.extractNutrientValue(from: nutriments, key: "sugars-added_100g").map { $0 * conversionFactor },
                        sodium: rawSodium.map { $0 * conversionFactor * 1000 }, // Convert to mg
                        cholesterol: self.extractNutrientValue(from: nutriments, key: "cholesterol_100g").map { $0 * conversionFactor * 1000 }, // Convert to mg
                        productName: self.capitalizeProductName(product["product_name"] as? String)
                    )
                    
                    print("🔍 DEBUG - Final calculated values:")
                    print("  Calories: \(nutrition.calories ?? 0)")
                    print("  Protein: \(nutrition.protein ?? 0)")
                    print("  Carbs: \(nutrition.carbohydrates ?? 0)")
                    print("  Fat: \(nutrition.fat ?? 0)")
                    print("  Sodium: \(nutrition.sodium ?? 0)")
                    print("  Sugar: \(nutrition.sugar ?? 0)")
                    
                    completion(.success(nutrition))
                } else {
                    completion(.failure(URLError(.badServerResponse)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func extractNutrientValue(from nutriments: [String: Any], key: String) -> Double? {
        if let value = nutriments[key] as? Double {
            return value
        } else if let value = nutriments[key] as? String, let doubleValue = Double(value) {
            return doubleValue
        }
        return nil
    }
    
    private func isFluidProduct(servingSize: String) -> Bool {
        // Check if the serving size indicates a fluid product
        let fluidUnits = ["ml", "milliliter", "milliliters", "l", "liter", "liters", "cup", "cups", "tbsp", "tablespoon", "tablespoons", "tsp", "teaspoon", "teaspoons", "fl oz", "floz", "fluid ounce", "fluid ounces", "pint", "pt", "quart", "qt"]
        let lowercased = servingSize.lowercased()
        return fluidUnits.contains { lowercased.contains($0) }
    }
    
    private func extractServingWeight(from servingSize: String) -> Double {
        // Extract numeric value from serving size string and convert to grams
        let pattern = #"(\d+(?:\.\d+)?)\s*(g|ml|oz|cup|cups|tbsp|tsp|fl\s*oz|fluid\s*ounce|pint|pt|quart|qt|liter|l|serving|servings)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: servingSize.utf16.count)
        
        if let match = regex?.firstMatch(in: servingSize, options: [], range: range) {
            let matchRange = match.range(at: 1)
            if let swiftRange = Range(matchRange, in: servingSize) {
                let numberString = String(servingSize[swiftRange])
                if let number = Double(numberString) {
                    // Convert to grams for consistency
                    let unitRange = match.range(at: 2)
                    if let unitSwiftRange = Range(unitRange, in: servingSize) {
                        let unit = String(servingSize[unitSwiftRange]).lowercased().trimmingCharacters(in: .whitespaces)
                        switch unit {
                        // Weight units (convert to grams)
                        case "g", "gram", "grams": return number
                        case "oz", "ounce", "ounces": return number * 28.35 // Convert oz to grams
                        
                        // Volume units (convert to approximate grams based on density)
                        case "ml", "milliliter", "milliliters": return number * 1.0 // Water density: 1ml = 1g
                        case "l", "liter", "liters": return number * 1000.0 // 1L = 1000ml = 1000g
                        case "cup", "cups": return number * 240.0 // 1 cup = 240ml = 240g (water)
                        case "tbsp", "tablespoon", "tablespoons": return number * 15.0 // 1 tbsp = 15ml = 15g (water)
                        case "tsp", "teaspoon", "teaspoons": return number * 5.0 // 1 tsp = 5ml = 5g (water)
                        case "fl oz", "floz", "fluid ounce", "fluid ounces": return number * 29.57 // 1 fl oz = 29.57ml = 29.57g (water)
                        case "pint", "pt": return number * 473.0 // 1 pint = 473ml = 473g (water)
                        case "quart", "qt": return number * 946.0 // 1 quart = 946ml = 946g (water)
                        
                        // Generic serving
                        case "serving", "servings": return 100.0 // Default to 100g per serving
                        default: return 100.0 // Default to 100g
                        }
                    }
                }
            }
        }
        return 100.0 // Default to 100g if parsing fails
    }
    
    private func getDensityForProduct(productName: String?, servingSize: String) -> Double {
        // Check if this is a milk or dairy product
        let productNameLower = (productName ?? "").lowercased()
        let servingSizeLower = servingSize.lowercased()
        
        // Milk and dairy products have higher density than water
        if productNameLower.contains("milk") || 
           productNameLower.contains("dairy") || 
           productNameLower.contains("cream") ||
           productNameLower.contains("yogurt") ||
           productNameLower.contains("cheese") ||
           servingSizeLower.contains("milk") {
            return 1.03 // Milk density: 1.03 g/ml
        }
        
        // Default to water density for other liquids
        return 1.0 // Water density: 1.0 g/ml
    }
    
    private func capitalizeProductName(_ productName: String?) -> String? {
        guard let name = productName, !name.isEmpty else { return productName }
        
        // Split by spaces and capitalize each word
        let words = name.components(separatedBy: " ")
        let capitalizedWords = words.map { word in
            // Handle special cases like "ultra-filtered" where we want to capitalize after hyphens too
            if word.contains("-") {
                return word.components(separatedBy: "-").map { $0.capitalized }.joined(separator: "-")
            } else {
                return word.capitalized
            }
        }
        
        return capitalizedWords.joined(separator: " ")
    }
    
    private func extractServingWeightWithDensity(from servingSize: String, density: Double) -> Double {
        // Extract numeric value from serving size string and convert to grams using correct density
        // Handle formats like "1 serving (240 ml)" by looking for volume in parentheses first
        let patterns = [
            // Look for volume in parentheses first: "1 serving (240 ml)" -> extract "240 ml"
            #"\((\d+(?:\.\d+)?)\s*(ml|milliliter|milliliters|l|liter|liters|fl\s*oz|fluid\s*ounce|cup|cups|tbsp|tablespoon|tsp|teaspoon|pint|pt|quart|qt)\)"#,
            // Standard pattern: "240 ml" or "1 cup"
            #"(\d+(?:\.\d+)?)\s*(g|ml|oz|cup|cups|tbsp|tsp|fl\s*oz|fluid\s*ounce|pint|pt|quart|qt|liter|l|serving|servings)"#
        ]
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: servingSize.utf16.count)
            
            if let match = regex?.firstMatch(in: servingSize, options: [], range: range) {
                let matchRange = match.range(at: 1)
                if let swiftRange = Range(matchRange, in: servingSize) {
                    let numberString = String(servingSize[swiftRange])
                    if let number = Double(numberString) {
                        // Convert to grams for consistency
                        let unitRange = match.range(at: 2)
                        if let unitSwiftRange = Range(unitRange, in: servingSize) {
                            let unit = String(servingSize[unitSwiftRange]).lowercased().trimmingCharacters(in: .whitespaces)
                            switch unit {
                            // Weight units (convert to grams)
                            case "g", "gram", "grams": return number
                            case "oz", "ounce", "ounces": return number * 28.35 // Convert oz to grams
                            
                            // Volume units (convert to approximate grams based on density)
                            case "ml", "milliliter", "milliliters": return number * density // Use correct density
                            case "l", "liter", "liters": return number * 1000.0 * density // 1L = 1000ml
                            case "cup", "cups": return number * 240.0 * density // 1 cup = 240ml
                            case "tbsp", "tablespoon", "tablespoons": return number * 15.0 * density // 1 tbsp = 15ml
                            case "tsp", "teaspoon", "teaspoons": return number * 5.0 * density // 1 tsp = 5ml
                            case "fl oz", "floz", "fluid ounce", "fluid ounces": return number * 29.57 * density // 1 fl oz = 29.57ml
                            case "pint", "pt": return number * 473.0 * density // 1 pint = 473ml
                            case "quart", "qt": return number * 946.0 * density // 1 quart = 946ml
                            
                            // Generic serving - try to extract volume from context
                            case "serving", "servings": 
                                // For "1 serving (240 ml)", we should have already matched the volume pattern above
                                // If we get here, it means no volume was found, so use default
                                return 100.0 // Default to 100g per serving
                            default: return 100.0 // Default to 100g
                            }
                        }
                    }
                }
            }
        }
        return 100.0 // Default to 100g if parsing fails
    }
    
    private func createSampleNutritionData(for barcode: String) -> ScannedNutrition {
        // Create different sample data based on barcode patterns
        let lastDigit = String(barcode.last ?? "0")
        let baseValue = Int(lastDigit) ?? 0
        
        return ScannedNutrition(
            servingSize: "1 serving",
            calories: 200 + (baseValue * 10),
            protein: Double(10 + baseValue),
            carbohydrates: Double(30 + baseValue * 2),
            fat: Double(5 + baseValue),
            fiber: Double(3 + baseValue),
            sugar: Double(8 + baseValue),
            addedSugar: Double(5 + baseValue),
            sodium: Double(200 + baseValue * 50),
            cholesterol: Double(20 + baseValue * 5),
            productName: "Sample Product \(barcode.suffix(4))"
        )
    }
    
    private func saveNutritionEntry(_ nutrition: ScannedNutrition) {
        // Validate nutrition data before saving
        guard let calories = nutrition.calories, calories > 0 && calories < 10000 else {
            print("Invalid calories value: \(nutrition.calories ?? 0)")
            return
        }
        
        let entry = NutritionEntry(
            date: Date(),
            calories: Double(calories),
            protein: min(nutrition.protein ?? 0, 1000), // Cap at reasonable values
            carbohydrates: min(nutrition.carbohydrates ?? 0, 1000),
            fat: min(nutrition.fat ?? 0, 1000),
            sodium: min(nutrition.sodium ?? 0, 10000), // Cap sodium at 10g
            sugar: min(nutrition.sugar ?? 0, 1000),
            addedSugar: min(nutrition.addedSugar ?? 0, 1000),
            fiber: min(nutrition.fiber ?? 0, 1000),
            water: 0,
            notes: nil,
            label: nutrition.productName ?? "Scanned Product"
        )
        
        dataManager.addNutritionEntry(entry)
    }
    
    private func extractUnitFromServingSize(_ servingSize: String) -> String {
        // Extract unit from serving size string like "1 serving", "240 ml", "1 cup"
        let pattern = #"(\d+(?:\.\d+)?)\s*(g|ml|oz|cup|cups|tbsp|tsp|fl\s*oz|fluid\s*ounce|pint|pt|quart|qt|liter|l|serving|servings|piece|pieces|slice|slices)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: servingSize.utf16.count)
        
        if let match = regex?.firstMatch(in: servingSize, options: [], range: range) {
            let unitRange = match.range(at: 2)
            if let unitSwiftRange = Range(unitRange, in: servingSize) {
                let unit = String(servingSize[unitSwiftRange]).lowercased().trimmingCharacters(in: .whitespaces)
                return unit
            }
        }
        return "serving" // Default unit
    }
    
    private func resetScanner() {
        hasScanned = false
        scannedBarcode = nil
        nutritionData = nil
        isLoading = false
        showingSuccess = false
        successMessage = ""
        resetEditableValues()
    }
    
    private func initializeEditableValues(from nutrition: ScannedNutrition) {
        editableCalories = String(Int(Double(nutrition.calories ?? 0) * servingAmount))
        editableProtein = String(format: "%.1f", (nutrition.protein ?? 0) * servingAmount)
        editableCarbs = String(format: "%.1f", (nutrition.carbohydrates ?? 0) * servingAmount)
        editableFat = String(format: "%.1f", (nutrition.fat ?? 0) * servingAmount)
        editableSodium = String(Int((nutrition.sodium ?? 0) * servingAmount))
        editableSugar = String(format: "%.1f", (nutrition.sugar ?? 0) * servingAmount)
        editableNaturalSugar = String(format: "%.1f", (nutrition.naturalSugar ?? 0) * servingAmount)
        editableAddedSugar = String(format: "%.1f", (nutrition.addedSugar ?? 0) * servingAmount)
    }
    
    private func resetEditableValues() {
        editableCalories = ""
        editableProtein = ""
        editableCarbs = ""
        editableFat = ""
        editableSodium = ""
        editableSugar = ""
        editableNaturalSugar = ""
        editableAddedSugar = ""
    }
}

// MARK: - Editable Nutrition Card

struct EditableNutritionCard: View {
    let title: String
    @Binding var value: String
    let unit: String
    let baseValue: Double
    let servingAmount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 2) {
                TextField("0", text: $value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white)
        .cornerRadius(8)
        .onAppear {
            // Initialize with calculated value if empty
            if value.isEmpty {
                updateValue()
            }
        }
        // Removed automatic recalculation - serving size changes no longer affect nutritional values
    }
    
    private func updateValue() {
        let calculatedValue = baseValue * servingAmount
        if unit == "kcal" {
            value = String(Int(calculatedValue))
        } else if unit == "mg" {
            value = String(Int(calculatedValue * 1000)) // Convert back to mg for sodium
        } else {
            value = String(format: "%.1f", calculatedValue)
        }
    }
}

struct BarcodeConfirmationView: View {
    let nutrition: ScannedNutrition
    let barcode: String
    let onSave: (ScannedNutrition) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Nutrition Data Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Barcode: \(barcode)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Calories:")
                        Spacer()
                        Text("\(nutrition.calories ?? 0)")
                    }
                    
                    HStack {
                        Text("Protein (g):")
                        Spacer()
                        Text("\(nutrition.protein ?? 0, specifier: "%.1f")")
                    }
                    
                    HStack {
                        Text("Carbohydrates (g):")
                        Spacer()
                        Text("\(nutrition.carbohydrates ?? 0, specifier: "%.1f")")
                    }
                    
                    HStack {
                        Text("Fat (g):")
                        Spacer()
                        Text("\(nutrition.fat ?? 0, specifier: "%.1f")")
                    }
                    
                    HStack {
                        Text("Fiber (g):")
                        Spacer()
                        Text("\(nutrition.fiber ?? 0, specifier: "%.1f")")
                    }
                    
                    HStack {
                        Text("Sugar (g):")
                        Spacer()
                        Text("\(nutrition.sugar ?? 0, specifier: "%.1f")")
                    }
                    
                    HStack {
                        Text("Sodium (mg):")
                        Spacer()
                        Text("\(nutrition.sodium ?? 0, specifier: "%.1f")")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    
                    Button("Save") {
                        onSave(nutrition)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct BarcodeCameraView: UIViewRepresentable {
    @Binding var isScanning: Bool
    let onBarcodeDetected: (String) -> Void
    let onError: (String) -> Void
    let onCameraReady: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            onError("No camera available")
            return view
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            onError("Could not create video input: \(error.localizedDescription)")
            return view
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            onError("Could not add video input to capture session")
            return view
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .code128, .code39, .upce]
        } else {
            onError("Could not add metadata output to capture session")
            return view
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.captureSession = captureSession
        
        // Start session on background queue
        DispatchQueue.global(qos: .userInitiated).async {
            print("Starting barcode camera session...")
            captureSession.startRunning()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if captureSession.isRunning {
                    print("Barcode camera session started successfully")
                    onCameraReady()
                } else {
                    print("Barcode camera session failed to start")
                    onError("Camera session failed to start")
                }
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update scanning state if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: BarcodeCameraView
        var captureSession: AVCaptureSession?
        
        init(_ parent: BarcodeCameraView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard parent.isScanning else { return }
            
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                print("Barcode detected: \(stringValue)")
                parent.onBarcodeDetected(stringValue)
            }
        }
    }
}


