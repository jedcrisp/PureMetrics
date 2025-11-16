import SwiftUI

struct CoachDashboardView: View {
    @ObservedObject var firestoreService: FirestoreService
    @State private var clients: [ClientInfo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedClient: ClientInfo?
    @State private var showingClientWorkouts = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading clients...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            loadClients()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if clients.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Clients")
                            .font(.headline)
                        
                        Text("You don't have any clients yet. Send invitations to get started.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(clients) { client in
                            ClientRow(client: client) {
                                selectedClient = client
                                showingClientWorkouts = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Clients")
            .onAppear {
                loadClients()
            }
            .sheet(item: $selectedClient) { client in
                ClientWorkoutsView(firestoreService: firestoreService, client: client)
            }
        }
    }
    
    private func loadClients() {
        isLoading = true
        errorMessage = nil
        
        firestoreService.getCoachClients { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let clientList):
                    clients = clientList
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct ClientRow: View {
    let client: ClientInfo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text(String((client.name ?? client.email).prefix(1)).uppercased())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name ?? client.email)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(client.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Joined \(client.joinedDate, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ClientWorkoutsView: View {
    @ObservedObject var firestoreService: FirestoreService
    let client: ClientInfo
    @Environment(\.dismiss) private var dismiss
    @State private var workouts: [CustomWorkout] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreateWorkout = false
    @State private var selectedWorkout: CustomWorkout?
    @State private var showingEditWorkout = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading workouts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if workouts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Workouts")
                            .font(.headline)
                        
                        Text("Create a workout for \(client.name ?? client.email)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(workouts) { workout in
                            WorkoutRow(workout: workout) {
                                selectedWorkout = workout
                                showingEditWorkout = true
                            } onDelete: {
                                deleteWorkout(workout)
                            }
                        }
                    }
                }
            }
            .navigationTitle(client.name ?? client.email)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateWorkout = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadWorkouts()
            }
            .sheet(isPresented: $showingCreateWorkout) {
                CreateWorkoutForClientView(firestoreService: firestoreService, client: client) {
                    loadWorkouts()
                }
            }
            .sheet(item: $selectedWorkout) { workout in
                EditWorkoutForClientView(firestoreService: firestoreService, client: client, workout: workout) {
                    loadWorkouts()
                }
            }
        }
    }
    
    private func loadWorkouts() {
        isLoading = true
        errorMessage = nil
        
        firestoreService.loadCustomWorkoutsForClient(clientID: client.id) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let workoutList):
                    workouts = workoutList
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func deleteWorkout(_ workout: CustomWorkout) {
        firestoreService.deleteCustomWorkoutForClient(workout, clientID: client.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadWorkouts()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct WorkoutRow: View {
    let workout: CustomWorkout
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                
                if let description = workout.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    Label("\(workout.totalExercises)", systemImage: "dumbbell")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Label("\(workout.totalSets)", systemImage: "repeat")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateWorkoutForClientView: View {
    @ObservedObject var firestoreService: FirestoreService
    let client: ClientInfo
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager: BPDataManager
    @State private var showingWorkoutBuilder = false
    
    init(firestoreService: FirestoreService, client: ClientInfo, onComplete: @escaping () -> Void) {
        self.firestoreService = firestoreService
        self.client = client
        self.onComplete = onComplete
        _dataManager = StateObject(wrappedValue: BPDataManager())
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if showingWorkoutBuilder {
                    CustomWorkoutBuilder()
                        .environmentObject(dataManager)
                        .onChange(of: dataManager.customWorkouts.count) { oldCount, newCount in
                            // When a new workout is added, save it for the client
                            if newCount > oldCount, let latestWorkout = dataManager.customWorkouts.sorted(by: { $0.createdDate > $1.createdDate }).first {
                                saveWorkoutForClient(latestWorkout)
                            }
                        }
                } else {
                    VStack(spacing: 20) {
                        Text("Create Workout for \(client.name ?? client.email)")
                            .font(.headline)
                            .padding()
                        
                        Text("Build a custom workout that will be saved to your client's account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Start Building Workout") {
                            showingWorkoutBuilder = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveWorkoutForClient(_ workout: CustomWorkout) {
        firestoreService.saveCustomWorkoutForClient(workout, clientID: client.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    onComplete()
                    dismiss()
                case .failure(let error):
                    print("Error saving workout: \(error)")
                }
            }
        }
    }
}

struct EditWorkoutForClientView: View {
    @ObservedObject var firestoreService: FirestoreService
    let client: ClientInfo
    let workout: CustomWorkout
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager: BPDataManager
    
    init(firestoreService: FirestoreService, client: ClientInfo, workout: CustomWorkout, onComplete: @escaping () -> Void) {
        self.firestoreService = firestoreService
        self.client = client
        self.workout = workout
        self.onComplete = onComplete
        _dataManager = StateObject(wrappedValue: BPDataManager())
    }
    
    var body: some View {
        NavigationView {
            CustomWorkoutBuilder(editingWorkout: workout)
                .environmentObject(dataManager)
                .navigationTitle("Edit Workout")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            // Get the updated workout from dataManager
                            if let updatedWorkout = dataManager.customWorkouts.first(where: { $0.id == workout.id }) {
                                saveWorkoutForClient(updatedWorkout)
                            }
                        }
                    }
                }
        }
    }
    
    private func saveWorkoutForClient(_ workout: CustomWorkout) {
        firestoreService.updateCustomWorkoutForClient(workout, clientID: client.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    onComplete()
                    dismiss()
                case .failure(let error):
                    print("Error updating workout: \(error)")
                }
            }
        }
    }
}

