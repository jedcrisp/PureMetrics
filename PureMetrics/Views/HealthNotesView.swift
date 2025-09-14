import SwiftUI

struct HealthNotesView: View {
    let metricType: String
    let date: Date
    @ObservedObject var dataManager: BPDataManager
    @State private var newNoteText = ""
    @State private var showingAddNote = false
    @State private var editingNote: HealthNote?
    
    private var notes: [HealthNote] {
        dataManager.getHealthNotes(for: metricType, on: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Notes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    showingAddNote = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            if notes.isEmpty {
                HStack {
                    Image(systemName: "note.text.badge.plus")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No notes yet - tap + to add")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(notes.prefix(3)) { note in
                        CompactNoteCard(
                            note: note,
                            onEdit: { editingNote = note },
                            onDelete: { dataManager.deleteHealthNote(note) }
                        )
                    }
                    
                    if notes.count > 3 {
                        Text("+ \(notes.count - 3) more notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(
                metricType: metricType,
                date: date,
                dataManager: dataManager,
                isPresented: $showingAddNote
            )
        }
        .sheet(item: $editingNote) { note in
            EditNoteView(
                note: note,
                dataManager: dataManager,
                isPresented: $editingNote
            )
        }
    }
}

struct NoteCard: View {
    let note: HealthNote
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.note)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Text(note.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if note.updatedAt != note.createdAt {
                    Text("Edited")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }
}

struct CompactNoteCard: View {
    let note: HealthNote
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 8) {
            Text(note.note)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Menu {
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive) {
                    showingDeleteAlert = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }
}

struct AddNoteView: View {
    let metricType: String
    let date: Date
    @ObservedObject var dataManager: BPDataManager
    @Binding var isPresented: Bool
    @State private var noteText = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Note for \(metricType)")
                        .font(.headline)
                    
                    Text(date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $noteText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveNote() {
        guard !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSaving = true
        
        let note = HealthNote(
            userId: dataManager.userProfile?.id ?? "",
            metricType: metricType,
            date: date,
            note: noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        // Save on background queue to prevent UI freezing
        DispatchQueue.global(qos: .userInitiated).async {
            dataManager.saveHealthNote(note)
            
            DispatchQueue.main.async {
                isSaving = false
                isPresented = false
            }
        }
    }
}

struct EditNoteView: View {
    let note: HealthNote
    @ObservedObject var dataManager: BPDataManager
    @Binding var isPresented: HealthNote?
    @State private var noteText = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Note for \(note.metricType)")
                        .font(.headline)
                    
                    Text(note.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $noteText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = nil
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .onAppear {
                noteText = note.note
            }
        }
    }
    
    private func saveNote() {
        guard !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSaving = true
        
        let updatedNote = HealthNote(
            id: note.id ?? "",
            userId: note.userId,
            metricType: note.metricType,
            date: note.date,
            note: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: note.createdAt,
            updatedAt: Date()
        )
        
        // Save on background queue to prevent UI freezing
        DispatchQueue.global(qos: .userInitiated).async {
            dataManager.saveHealthNote(updatedNote)
            
            DispatchQueue.main.async {
                isSaving = false
                isPresented = nil
            }
        }
    }
}

#Preview {
    HealthNotesView(
        metricType: "Weight",
        date: Date(),
        dataManager: BPDataManager()
    )
}
