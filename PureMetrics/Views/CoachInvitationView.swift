import SwiftUI

struct CoachInvitationView: View {
    @ObservedObject var firestoreService: FirestoreService
    @State private var invitations: [CoachInvitation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSendInvitation = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading invitations...")
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
                            loadInvitations()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if invitations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.open")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Pending Invitations")
                            .font(.headline)
                        
                        Text("You don't have any pending coach invitations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(invitations) { invitation in
                            InvitationRow(invitation: invitation, firestoreService: firestoreService) {
                                loadInvitations()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Coach Invitations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSendInvitation = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadInvitations()
            }
            .sheet(isPresented: $showingSendInvitation) {
                SendCoachInvitationView(firestoreService: firestoreService)
            }
        }
    }
    
    private func loadInvitations() {
        isLoading = true
        errorMessage = nil
        
        firestoreService.getPendingInvitations { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let invs):
                    invitations = invs
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct InvitationRow: View {
    let invitation: CoachInvitation
    let firestoreService: FirestoreService
    let onUpdate: () -> Void
    @State private var isProcessing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invitation.coachName ?? invitation.coachEmail)
                        .font(.headline)
                    
                    Text(invitation.coachEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(invitation.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let message = invitation.message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    acceptInvitation()
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("Accept")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isProcessing)
                
                Button(action: {
                    rejectInvitation()
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                        }
                        Text("Reject")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isProcessing)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func acceptInvitation() {
        isProcessing = true
        firestoreService.acceptCoachInvitation(invitation) { result in
            DispatchQueue.main.async {
                isProcessing = false
                switch result {
                case .success:
                    onUpdate()
                case .failure(let error):
                    print("Error accepting invitation: \(error)")
                }
            }
        }
    }
    
    private func rejectInvitation() {
        isProcessing = true
        firestoreService.rejectCoachInvitation(invitation) { result in
            DispatchQueue.main.async {
                isProcessing = false
                switch result {
                case .success:
                    onUpdate()
                case .failure(let error):
                    print("Error rejecting invitation: \(error)")
                }
            }
        }
    }
}

struct SendCoachInvitationView: View {
    @ObservedObject var firestoreService: FirestoreService
    @Environment(\.dismiss) private var dismiss
    @State private var clientEmail = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Client Information") {
                    TextField("Client Email", text: $clientEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                Section("Optional Message") {
                    TextEditor(text: $message)
                        .frame(height: 100)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let success = successMessage {
                    Section {
                        Text(success)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Send Invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        sendInvitation()
                    }
                    .disabled(clientEmail.isEmpty || isSending)
                }
            }
        }
    }
    
    private func sendInvitation() {
        guard !clientEmail.isEmpty else { return }
        
        isSending = true
        errorMessage = nil
        successMessage = nil
        
        firestoreService.sendCoachInvitation(to: clientEmail, message: message.isEmpty ? nil : message) { result in
            DispatchQueue.main.async {
                isSending = false
                switch result {
                case .success:
                    successMessage = "Invitation sent successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

