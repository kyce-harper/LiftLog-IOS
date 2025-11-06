import SwiftUI

struct TemplateBuilderView: View {
    // 1. Receives the specific template object from the previous view
    @ObservedObject var template: WorkoutTemplate
    
    @Environment(\.managedObjectContext) private var viewContext
    private let persistence = PersistenceController.shared
    
    // State for showing the "Add Exercise" sheet
    @State private var showingAddExerciseSheet = false
    // State for editing an existing exercise
    @State private var editingExercise: TemplateExercise? = nil

    var exercises: [TemplateExercise] {
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
                    // Progressive overload hint: show last logged weight/reps if any
                    if let last = fetchLastPerformance(for: exercise) {
                        Text("Last: \(String(format: "%.1f", last.weight)) lbs x \(last.reps)")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("No history")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                // Swipe actions to Edit or Delete
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        editingExercise = exercise
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                    
                    Button(role: .destructive) {
                        persistence.deleteExercise(exercise: exercise)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                // Also provide a context menu for iPadOS/macOS style interaction
                .contextMenu {
                    Button {
                        editingExercise = exercise
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        persistence.deleteExercise(exercise: exercise)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
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
        // Sheet for editing an existing exercise
        .sheet(item: $editingExercise) { exercise in
            EditExerciseView(exercise: exercise) {
                // Dismiss action: set editingExercise to nil
                editingExercise = nil
            }
            .environment(\.managedObjectContext, viewContext)
        }
    }
    
    // MARK: - CRUD Delete
    
    private func deleteExercises(offsets: IndexSet) {
        withAnimation {
            let exercisesToDelete = offsets.map { exercises[$0] }
            for exercise in exercisesToDelete {
                persistence.deleteExercise(exercise: exercise)
            }
        }
    }
    
    // MARK: - Last performance helper (mirrors ActiveWorkoutView)
    private func fetchLastPerformance(for exercise: TemplateExercise) -> LoggedSet? {
        guard let sets = exercise.loggedSets as? Set<LoggedSet> else { return nil }
        return sets.sorted { ($0.dateLogged ?? .distantPast) > ($1.dateLogged ?? .distantPast) }.first
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

// MARK: - Subview for Editing Exercise

struct EditExerciseView: View {
    @ObservedObject var exercise: TemplateExercise
    var onDismiss: () -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // Local editable state initialized from the exercise
    @State private var name: String = ""
    @State private var targetSets: Int = 3
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Exercise")) {
                    TextField("Exercise Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Stepper("Target Sets: \(targetSets)", value: $targetSets, in: 1...10)
                }
            }
            .navigationTitle("Edit Exercise")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Apply changes to the managed object
                        exercise.exerciseName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? exercise.exerciseName : name
                        exercise.targetSets = Int16(targetSets)
                        do {
                            try viewContext.save()
                        } catch {
                            print("Error saving edited exercise: \(error)")
                        }
                        onDismiss()
                    }
                }
            }
            .onAppear {
                name = exercise.exerciseName ?? ""
                targetSets = Int(exercise.targetSets)
            }
        }
    }
}
