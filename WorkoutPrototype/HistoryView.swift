import SwiftUI
import CoreData

// This view shows all the specific sets for each workoutSessions

struct SessionDetailView: View {
    @ObservedObject var session: WorkoutSession
    
    var body: some View {
        List {
            // Group the LoggedSets by the name of the TemplateExercise
            let sets = session.loggedSets as? Set<LoggedSet> ?? []
            let setsByExercise = Dictionary(grouping: sets) { $0.exercise?.exerciseName ?? "Unknown Exercise" }
            
            // Sort by exercise name
            ForEach(setsByExercise.keys.sorted(), id: \.self) { exerciseName in
                Section(header: Text(exerciseName).font(.title3)) {
                    if let exerciseSets = setsByExercise[exerciseName]?.sorted(by: { $0.dateLogged ?? Date.distantPast < $1.dateLogged ?? Date.distantPast }) {
                        ForEach(exerciseSets.indices, id: \.self) { index in
                            let logSet = exerciseSets[index]
                            HStack {
                                Text("Stats:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(String(format: "%.1f", logSet.weight)) lbs")
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


// HistoryView (The main session list view)
// This view fetches and groups WorkoutSession entities.

struct HistoryView: View {
    // Fetch all WorkoutSessions, sort them by dateCompleted descending.
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.dateCompleted, order: .reverse)],
        animation: .default)
    private var sessions: FetchedResults<WorkoutSession>
    
    // Helper functions for formatting the Time and Date
    private static let sessionTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Helper function to group sessions by the date
    private func sessionsGroupedByDate() -> [Date: [WorkoutSession]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { (session) -> Date in
            let date = session.dateCompleted ?? session.dateStarted ?? Date()
            return calendar.startOfDay(for: date)
        }
        return grouped
    }

    var body: some View {
        NavigationStack {
            let groupedSessions = sessionsGroupedByDate()
            let sortedDates = groupedSessions.keys.sorted(by: >)
            
            if sessions.isEmpty {
                // Empty State pinned to top
                VStack(alignment: .center, spacing: 16) {
                    Spacer(minLength: 16)
                    
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Workout History")
                        .font(.title2)
                    Text("Start a workout and complete it to see your history here.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal)
            } else {
                List {
                    ForEach(sortedDates, id: \.self) { date in
                        Section(header: Text(HistoryView.dateOnlyFormatter.string(from: date))) {
                            if let sessionsForDay = groupedSessions[date] {
                                let daySorted = sessionsForDay.sorted { ($0.dateCompleted ?? .distantPast) < ($1.dateCompleted ?? .distantPast) }
                                
                                ForEach(daySorted, id: \.self) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        VStack(alignment: .leading) {
                                            Text(session.template?.name ?? "Untitled Session")
                                                .font(.headline)
                                            
                                            let completionDate = session.dateCompleted ?? session.dateStarted ?? Date()
                                            Text("Completed at: \(completionDate, formatter: HistoryView.sessionTimeFormatter)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .onDelete { indexSet in
                                    deleteSessions(at: indexSet, in: daySorted)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped) // Optional: choose list style; starts near top under title
            }
        }
        .navigationTitle("History")
    }
    
    private func deleteSessions(at offsets: IndexSet, in daySessions: [WorkoutSession]) {
        let persistence = PersistenceController.shared
        for index in offsets {
            let session = daySessions[index]
            persistence.deleteSession(session)
        }
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
