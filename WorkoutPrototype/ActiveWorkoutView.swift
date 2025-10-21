import SwiftUI
import CoreData

struct ActiveWorkoutView: View {
    // Dismiss the sheet when the workout is complete or cancelled
    @Environment(\.dismiss) var dismiss

    // Fetch all available templates to populate the selector list
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.dateCreated, order: .reverse)],
        animation: .default)
    private var templates: FetchedResults<WorkoutTemplate>

    // State to manage the full-screen session view
    @State private var selectedTemplate: WorkoutTemplate? = nil

    var body: some View {
        NavigationView {
            VStack {
                if templates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Templates Found")
                            .font(.title2)
                        Text("Go to the 'Plan' tab to create a new workout template first!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List {
                        Text("Select a template to begin your workout:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(templates) { template in
                            Button {
                                // Action: Set the template, which triggers the fullScreenCover below
                                selectedTemplate = template
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(template.name ?? "Untitled Template")
                                        .font(.headline)
                                    Text("\(template.exercises?.count ?? 0) exercises planned")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Start Workout")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        // Launch the actual logging screen when a template is selected
        .fullScreenCover(item: $selectedTemplate) { template in
            SessionLoggingView(template: template, dismissParent: dismiss)
        }
    }
}

struct SessionLoggingView: View {
    @Environment(\.dismiss) var dismiss
    private let persistence = PersistenceController.shared
    
    let template: WorkoutTemplate
    let dismissParent: DismissAction
    
    // MARK: - Core Data State
    @State private var activeSession: WorkoutSession? = nil // Holds the new session object
    
    // MARK: - UI State
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeElapsed: TimeInterval = 0
    @State private var currentExerciseIndex: Int = 0
    @State private var currentWeight: String = ""
    @State private var currentReps: String = ""
    
    // MARK: - Computed Properties
    
    private var sortedExercises: [TemplateExercise] {
        guard let exercises = template.exercises as? Set<TemplateExercise> else { return [] }
        return exercises.sorted { $0.order < $1.order }
    }
    
    private var isWorkoutFinished: Bool {
        currentExerciseIndex >= sortedExercises.count
    }
    
    private var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional
        return formatter
    }

    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Workout Timer
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.accentColor)
                    Text(timeFormatter.string(from: timeElapsed) ?? "00:00:00")
                        .font(.largeTitle)
                        .monospacedDigit()
                }
                .padding(.vertical)
                
                // MARK: - Main Content Area
                if isWorkoutFinished {
                    workoutCompleteView()
                } else if let exercise = sortedExercises[safe: currentExerciseIndex] {
                    exerciseLoggingView(for: exercise)
                } else {
                    Text("Error loading exercise.")
                }
                
                Spacer()
            }
            .navigationTitle(template.name ?? "Active Workout")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Finish") {
                        // Action: Complete the session and dismiss
                        completeAndDismiss()
                    }
                }
            }
            // Start/Stopwatch Logic
            .onReceive(timer) { _ in
                if !isWorkoutFinished {
                    timeElapsed += 1
                }
            }
            // MARK: - NEW: Start the session when the view appears
            .onAppear {
                activeSession = persistence.startNewSession(for: template)
            }
        }
    }
    
    // MARK: - Component Views
    
    @ViewBuilder
    private func workoutCompleteView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            Text("Workout Completed!")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Total time: \(timeFormatter.string(from: timeElapsed) ?? "00:00:00")")
                .font(.title3)
            
            Button("Done") {
                // Action: Complete the session and dismiss
                completeAndDismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
        .padding()
    }
    
    @ViewBuilder
    private func exerciseLoggingView(for exercise: TemplateExercise) -> some View {
        VStack(spacing: 25) {
            Text(exercise.exerciseName ?? "Unknown Exercise")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // Target Info
            Text("Target: \(exercise.targetSets) sets")
                .font(.title2)
                .foregroundColor(.secondary)
            
            // MARK: - PROGRESSIVE OVERLOAD HINT
            lastPerformanceHint(for: exercise).padding(.top, 10)
            
            // MARK: - LOGGING INTERFACE (Weight/Reps)
            VStack(spacing: 20) {
                HStack {
                    TextField("Weight (kg)", text: $currentWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    TextField("Reps", text: $currentReps)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }
                
                // MARK: - LOG AND ADVANCE BUTTON
                Button("Complete Exercise & Advance (\(currentExerciseIndex + 1)/\(sortedExercises.count))") {
                    logFinalPerformance(for: exercise)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(currentWeight.isEmpty || currentReps.isEmpty)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func lastPerformanceHint(for exercise: TemplateExercise) -> some View {
        if let lastSet = fetchLastPerformance(for: exercise) {
            VStack(alignment: .center) {
                Text("Last Session Performance")
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack(spacing: 15) {
                    Text("Weight: \(String(format: "%.1f", lastSet.weight)) kg")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Text("Reps: \(lastSet.reps) avg")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                Text("Date: \(lastSet.dateLogged!, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
        } else {
            Text("No history recorded yet. Set a baseline!")
                .font(.subheadline)
                .foregroundColor(.orange)
        }
    }
    
    // MARK: - Core Data Logic (Modified)
    
    /// Helper function to finalize the session and close the full screen cover.
    private func completeAndDismiss() {
        if let session = activeSession {
            persistence.completeSession(session: session)
        }
        dismissParent()
    }
    
    /// Finds the most recent LoggedSet for a given exercise to show prior performance.
    func fetchLastPerformance(for exercise: TemplateExercise) -> LoggedSet? {
        guard let setsArray = exercise.loggedSets as? Set<LoggedSet> else {
            return nil
        }

        // Sort the array of sets by date, descending (most recent first)
        let sortedSets = setsArray.sorted { $0.dateLogged ?? Date.distantPast > $1.dateLogged ?? Date.distantPast }

        // Return the first item (the most recent completed exercise log)
        return sortedSets.first
    }
    
    /// Logs the final performance for the exercise and advances to the next one.
    func logFinalPerformance(for exercise: TemplateExercise) {
        guard let weight = Double(currentWeight),
              let reps = Int(currentReps),
              let session = activeSession, // Get the active session
              reps > 0, weight >= 0 else {
            print("Invalid input or active session is nil. Cannot log set.")
            return
        }
        
        // 1. LOG THE SINGLE RECORD, passing the session
        persistence.logSet(for: exercise, weight: weight, reps: reps, session: session)
        
        // 2. ADVANCE TO THE NEXT EXERCISE
        withAnimation {
            currentExerciseIndex += 1
        }
        
        // 3. Reset inputs
        currentWeight = ""
        currentReps = ""
    }
}

// Extension to safely access array elements (required by the view)
fileprivate extension Array {
    subscript (safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
