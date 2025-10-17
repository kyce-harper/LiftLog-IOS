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
    
    // This action is set by the parent view (ContentView) to dismiss the active workout sheet
    let startWorkoutAction: () -> Void

    var body: some View {
        NavigationView {
            List {
                // If the list is empty, show a prompt
                if templates.isEmpty {
                    Text("Tap the '+' button to create your first workout template, like 'Leg Day' or 'Push Day'!")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // Loop through all saved templates
                    ForEach(templates) { template in
                        // NavLink takes us to the screen where exercises are added
                        NavigationLink {
                            TemplateBuilderView(template: template)
                        } label: {
                            TemplateRow(template: template)
                        }
                    }
                    .onDelete(perform: deleteTemplates)
                }
            }
            .navigationTitle("Workout Plans")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                
                // Button to launch the Active Workout screen (Passed from ContentView)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Start Workout") {
                        startWorkoutAction()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTemplateSheet = true
                    } label: {
                        Label("Add Template", systemImage: "plus.circle.fill")
                    }
                }
            }
            // Present the sheet for adding a new template
            .sheet(isPresented: $showingAddTemplateSheet) {
                AddTemplateView()
            }
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

// A reusable row component for the list
struct TemplateRow: View {
    @ObservedObject var template: WorkoutTemplate // Use @ObservedObject for managed objects

    var body: some View {
        VStack(alignment: .leading) {
            Text(template.name ?? "Untitled Template")
                .font(.headline)
            // Display count of exercises
            Text("\(template.exercises?.count ?? 0) exercises defined")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

// View for creating a new template (presented as a sheet)
struct AddTemplateView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    private let persistence = PersistenceController.shared

    @State private var templateName: String = ""

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    TextField("Template Name (e.g., Pull Day)", text: $templateName)
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
                        // Use PersistenceController function to create and save
                        persistence.createTemplate(name: templateName)
                        
                        // Explicitly save the context to force the parent list to refresh immediately
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
