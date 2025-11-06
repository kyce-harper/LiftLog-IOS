import SwiftUI
import CoreData

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) var dismiss

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.dateCreated, order: .reverse)],
        animation: .default)
    private var templates: FetchedResults<WorkoutTemplate>

    @State private var selectedTemplate: WorkoutTemplate? = nil

    var body: some View {
        NavigationStack {
            VStack {
                if templates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Templates Found")
                            .font(.title2)
                        Text("Go to the Templates tab to create a new workout template first.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List {
                        Section {
                            Text("Select a template to begin your workout:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        ForEach(templates) { template in
                            Button {
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
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
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
    
    @State private var activeSession: WorkoutSession? = nil
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeElapsed: TimeInterval = 0
    @State private var currentExerciseIndex: Int = 0
    @State private var currentWeight: String = ""
    @State private var currentReps: String = ""
    
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
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.accentColor)
                    Text(timeFormatter.string(from: timeElapsed) ?? "00:00:00")
                        .font(.largeTitle)
                        .monospacedDigit()
                }
                .padding(.vertical)
                
                if isWorkoutFinished {
                    workoutCompleteView()
                        .transition(.opacity)
                } else if let exercise = sortedExercises[safe: currentExerciseIndex] {
                    exerciseLoggingView(for: exercise)
                        .transition(.opacity)
                } else {
                    Text("Error loading exercise.")
                }
                
                Spacer()
            }
            .navigationTitle(template.name ?? "Active Workout")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Finish") {
                        completeAndDismiss()
                    }
                }
            }
            .onReceive(timer) { _ in
                if !isWorkoutFinished {
                    timeElapsed += 1
                }
            }
            .onAppear {
                activeSession = persistence.startNewSession(for: template)
            }
        }
    }
    
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

            Text("Target: \(exercise.targetSets) sets")
                .font(.title2)
                .foregroundColor(.secondary)
            
            lastPerformanceHint(for: exercise).padding(.top, 10)
            
            VStack(spacing: 20) {
                HStack {
                    TextField("Weight (lbs)", text: $currentWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    TextField("Reps", text: $currentReps)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }
                
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
                    Text("Weight: \(String(format: "%.1f", lastSet.weight)) lbs")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Text("Reps: \(lastSet.reps) avg")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                if let date = lastSet.dateLogged {
                    Text("Date: \(date, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
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
    
    private func completeAndDismiss() {
        if let session = activeSession {
            persistence.completeSession(session: session)
        }
        dismissParent()
    }
    
    func fetchLastPerformance(for exercise: TemplateExercise) -> LoggedSet? {
        guard let setsArray = exercise.loggedSets as? Set<LoggedSet> else {
            return nil
        }
        let sortedSets = setsArray.sorted { ($0.dateLogged ?? .distantPast) > ($1.dateLogged ?? .distantPast) }
        return sortedSets.first
    }
    
    func logFinalPerformance(for exercise: TemplateExercise) {
        guard let weight = Double(currentWeight),
              let reps = Int(currentReps),
              let session = activeSession,
              reps > 0, weight >= 0 else {
            print("Invalid input or active session is nil. Cannot log set.")
            return
        }
        persistence.logSet(for: exercise, weight: weight, reps: reps, session: session)
        withAnimation(.easeInOut(duration: 0.15)) {
            currentExerciseIndex += 1
        }
        currentWeight = ""
        currentReps = ""
    }
}

fileprivate extension Array {
    subscript (safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
