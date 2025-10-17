import SwiftUI

struct TemplateBuilderView: View {
    // 1. Receives the specific template object from the previous view
    @ObservedObject var template: WorkoutTemplate
    
    @Environment(\.managedObjectContext) private var viewContext
    private let persistence = PersistenceController.shared
    
    // State for showing the "Add Exercise" sheet
    @State private var showingAddExerciseSheet = false

    // Fetch the exercises belonging to THIS specific template
    // We use a manual @FetchRequest inside the body to filter by the template.
    // However, for simplicity and proper SwiftUI observation of relationships,
    // we access the relationship directly and sort it manually in the List.

    var exercises: [TemplateExercise] {
        // Convert the NSSet relationship to a sorted Swift Array
        let set = template.exercises as? Set<TemplateExercise> ?? []
        return set.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        List {
            // MARK: - List of Exercises
            ForEach(exercises) { exercise in
                HStack {
                    VStack(alignment: .leading) {
                        Text(exercise.exerciseName ?? "Unknown Exercise")
                            .font(.headline)
                        // Show the target number of sets
                        Text("Target: \(exercise.targetSets) Sets")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    // Placeholder for the progressive overload hint (Phase 3)
                    Text("Last: 140x8")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .onDelete(perform: deleteExercises)
        }
        .navigationTitle(template.name ?? "Template")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddExerciseSheet = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        // Sheet for adding a new exercise to this template
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExerciseView(template: template, isPresented: $showingAddExerciseSheet)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    // MARK: - CRUD Delete
    
    private func deleteExercises(offsets: IndexSet) {
        withAnimation {
            // Get the exercises to delete from the sorted array
            let exercisesToDelete = offsets.map { exercises[$0] }
            
            for exercise in exercisesToDelete {
                // Use the delete function from the persistence controller
                persistence.deleteExercise(exercise: exercise)
            }
        }
    }
}

// MARK: - Subview for Adding Exercise

struct AddExerciseView: View {
    @ObservedObject var template: WorkoutTemplate // The parent template
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var targetSets: Int = 3
    
    private let persistence = PersistenceController.shared
    
    @Environment(\.managedObjectContext) private var viewContext
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && targetSets > 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name (e.g., Bench Press)", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Stepper("Target Sets: \(targetSets)", value: $targetSets, in: 1...10)
                }
                
                Button("Add Exercise to \(template.name ?? "Template")") {
                    if isFormValid {
                        // Call the PersistenceController function to link the new exercise
                        persistence.addExercise(
                            to: template,
                            name: name,
                            targetSets: targetSets
                        )
                        do {
                            try viewContext.save()
                        } catch {
                            print("Error Saving exercise")
                        }
                        isPresented = false
                    }
                }
                .disabled(!isFormValid)
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
