import SwiftUI
import HealthKit

struct HealthKitDashboard: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // HealthKit Toggle Section
                    healthKitToggleSection
                    
                    if healthKitManager.isHealthKitEnabled {
                        if !healthKitManager.isAuthorized {
                            permissionSection
                        } else {
                            // Steps Section
                            stepsSection
                            
                            // Activity Section
                            activitySection
                            
                            // Health Metrics Section
                            healthMetricsSection
                            
                            // Refresh Button
                            refreshButton
                        }
                    } else {
                        disabledSection
                    }
                }
                .padding()
            }
            .navigationTitle("Health Data")
            .onAppear {
                if healthKitManager.isHealthKitEnabled && healthKitManager.isAuthorized {
                    healthKitManager.refreshData()
                }
            }
        }
    }
    
    // MARK: - HealthKit Toggle Section
    
    private var healthKitToggleSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Health Integration")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(healthKitManager.isHealthKitEnabled ? "Connected to Apple Health" : "Disconnected from Apple Health")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $healthKitManager.isHealthKitEnabled)
                    .labelsHidden()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - Disabled Section
    
    private var disabledSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Health Data Disabled")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Enable Apple Health integration to track your daily activity, steps, heart rate, and other health metrics.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Enable Health Data") {
                healthKitManager.toggleHealthKit()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Permission Section
    
    private var permissionSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Health Data Access")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Connect to Apple Health to track your steps, heart rate, and other health metrics.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Enable Health Access") {
                healthKitManager.requestAuthorization()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Steps Section
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(.blue)
                Text("Steps")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Today
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(healthKitManager.formattedStepsToday)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // This Week
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(healthKitManager.formattedStepsThisWeek)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // This Month
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(healthKitManager.formattedStepsThisMonth)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Active Energy
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Energy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(healthKitManager.formattedActiveEnergy)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Walking Distance
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(healthKitManager.formattedWalkingDistance)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Flights Climbed
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flights Climbed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(healthKitManager.formattedFlightsClimbed)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Health Metrics Section
    
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Health Metrics")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Heart Rate
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heart Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(healthKitManager.formattedHeartRate)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Refresh Button
    
    private var refreshButton: some View {
        Button(action: {
            healthKitManager.refreshData()
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Refresh Data")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

#Preview {
    HealthKitDashboard(healthKitManager: HealthKitManager())
}
