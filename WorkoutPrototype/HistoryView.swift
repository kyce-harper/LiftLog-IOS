import SwiftUI
import CoreData

// MARK: - 1. SessionDetailView (The drill-down view)
// This view shows all the sets logged for a single WorkoutSession.

struct SessionDetailView: View {
    // We use @ObservedObject because the session object is passed from the HistoryView
    // and we need SwiftUI to react to changes (though likely not changing here).
    @ObservedObject var session: WorkoutSession
    
    var body: some View {
        List {
            // Group the LoggedSets by the name of the TemplateExercise
            // Casting the NSSet to Set<LoggedSet>
            let sets = session.loggedSets as? Set<LoggedSet> ?? []
            let setsByExercise = Dictionary(grouping: sets) { $0.exercise?.exerciseName ?? "Unknown Exercise" }
            
            // Sort by exercise name
            ForEach(setsByExercise.keys.sorted(), id: \.self) { exerciseName in
                Section(header: Text(exerciseName).font(.title3)) {
                    // Sort the sets within the exercise by time
                    if let exerciseSets = setsByExercise[exerciseName]?.sorted(by: { $0.dateLogged ?? Date.distantPast < $1.dateLogged ?? Date.distantPast }) {
                        
                        // We use the index to show "Set 1", "Set 2", etc.
                        ForEach(exerciseSets.indices, id: \.self) { index in
                            let logSet = exerciseSets[index]
                            HStack {
                                Text("Set \(index + 1):")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(String(format: "%.1f", logSet.weight)) kg")
                                    .fontWeight(.medium)
                                
                                Text("x")
                                
                                Text("\(logSet.reps) reps")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(session.template?.name ?? "Workout Details")
    }
}


// MARK: - 2. HistoryView (The main session list view)
// This view fetches and groups WorkoutSession entities.

struct HistoryView: View {
    // Fetch all WorkoutSessions, sorted by dateCompleted descending.
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.dateCompleted, order: .reverse)],
        animation: .default)
    private var sessions: FetchedResults<WorkoutSession>
    
    // Date formatters
    private static let sessionTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short // e.g., "9:30 PM"
        return formatter
    }()
    
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long // e.g., "October 20, 2025"
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Helper function to group sessions by the calendar day
    private func sessionsGroupedByDate() -> [Date: [WorkoutSession]] {
        let calendar = Calendar.current
        
        // Group by the start of the day for the completion date
        let grouped = Dictionary(grouping: sessions) { (session) -> Date in
            // Use dateCompleted, falling back to dateStarted
            let date = session.dateCompleted ?? session.dateStarted ?? Date()
            return calendar.startOfDay(for: date)
        }
        return grouped
    }

    var body: some View {
        NavigationView {
            let groupedSessions = sessionsGroupedByDate()
            let sortedDates = groupedSessions.keys.sorted(by: >) // Newest date first
            
            if sessions.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Workout History")
                        .font(.title2)
                    Text("Start a workout and complete it to see your history here.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
            } else {
                List {
                    // Iterate through the dates (sections)
                    ForEach(sortedDates, id: \.self) { date in
                        // Section header is the date
                        Section(header: Text(HistoryView.dateOnlyFormatter.string(from: date))) {
                            if let sessionsForDay = groupedSessions[date] {
                                // Sort sessions by completion time (oldest first within the day)
                                ForEach(sessionsForDay.sorted(by: { $0.dateCompleted ?? Date.distantPast < $1.dateCompleted ?? Date.distantPast }), id: \.self) { session in
                                    
                                    // NavigationLink to the detail view
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        VStack(alignment: .leading) {
                                            // Show the Template name
                                            Text(session.template?.name ?? "Untitled Session")
                                                .font(.headline)
                                            
                                            // Show the completion time
                                            let completionDate = session.dateCompleted ?? session.dateStarted ?? Date()
                                            Text("Completed at: \(completionDate, formatter: HistoryView.sessionTimeFormatter)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
    }
}

#Preview {
    HistoryView()
        // Provide the same Core Data environment for the preview
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
