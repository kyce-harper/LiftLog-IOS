import SwiftUI
import CoreData

struct TemplateListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    private let persistence = PersistenceController.shared
    
    // Fetch all WorkoutTemplate entities for the main list
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.dateCreated, order: .reverse)],
        animation: .default)
    private var templates: FetchedResults<WorkoutTemplate>

    @State private var showingAddTemplateSheet = false
    @State private var isEditing = false
    
    // This action is set by the parent view (ContentView) to dismiss the active workout sheet
    let startWorkoutAction: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No Templates Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Create a template like “Push Day” or “Leg Day” to get started.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button {
                            showingAddTemplateSheet = true
                        } label: {
                            Label("Create Template", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                        
                        Button {
                            startWorkoutAction()
                        } label: {
                            Label("Start Workout", systemImage: "play.circle")
                        }
                        .buttonStyle(.bordered)
                        .disabled(true) // Disabled when empty to guide flow
                        .tint(.gray)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(templates) { template in
                            NavigationLink {
                                TemplateBuilderView(template: template)
                            } label: {
                                TemplateRow(template: template)
                            }
                        }
                        .onDelete(perform: deleteTemplates)
                    }
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                }
            }
            .toolbar {
                // Leading: optional Start Workout as icon, away from back button on push screens
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        startWorkoutAction()
                    } label: {
                        Image(systemName: "play.circle.fill")
                    }
                    .accessibilityLabel("Start Workout")
                }
                
                // Trailing: Add Template
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTemplateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add Template")
                }
                
                // Trailing: Edit toggle (moved away from back button area)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isEditing.toggle()
                        }
                    } label: {
                        Text(isEditing ? "Done" : "Edit")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel(isEditing ? "Done Editing" : "Edit Templates")
                }
            }
            .sheet(isPresented: $showingAddTemplateSheet) {
                AddTemplateView()
            }
            .navigationTitle("LiftLog")
        }
    }

    // Delete functionality
    private func deleteTemplates(offsets: IndexSet) {
        withAnimation {
            offsets.map { templates[$0] }.forEach(persistence.deleteTemplate)
        }
    }
}

// MARK: - Helper Views

struct TemplateRow: View {
    @ObservedObject var template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name ?? "Untitled Template")
                .font(.headline)
            Text("\(template.exercises?.count ?? 0) exercises defined")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct AddTemplateView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    private let persistence = PersistenceController.shared

    @State private var templateName: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    TextField("Template Name (e.g., Pull Day)", text: $templateName)
                        .textInputAutocapitalization(.words)
                }
                Spacer()
            }
            .navigationTitle("New Template")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        persistence.createTemplate(name: templateName)
                        do {
                            try viewContext.save()
                        } catch {
                            print("Error saving template: \(error)")
                        }
                        dismiss()
                    }
                    .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
