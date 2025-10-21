import SwiftUI
import CoreData

struct HistoryView: View {
    // 1. Fetch all LoggedSet entities, sorted by dateLogged descending (newest first).
    // Note: The LoggedSet entity has no direct relationship to a 'WorkoutSession',
    // so we'll group by date manually to simulate a session history.
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.dateLogged, order: .reverse)],
        animation: .default)
    private var loggedSets: FetchedResults<LoggedSet>
    
    // DateFormatter to group and display the dates
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long // e.g., "October 20, 2025"
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Helper function to group LoggedSets by day
    private func setsGroupedByDate() -> [Date: [LoggedSet]] {
        // Grouping is tricky with FetchedResults, so convert to array first.
        let allSets = Array(loggedSets)
        
        // Use a Calendar to normalize the Date to just its year/month/day components
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: allSets) { (set) -> Date in
            // Use the date of the log, defaulting to current date if nil (shouldn't happen)
            let date = set.dateLogged ?? Date()
            
            // Normalize the date to be the start of the day
            return calendar.startOfDay(for: date)
        }
        return grouped
    }

    var body: some View {
        NavigationView {
            // Group the sets, then sort the keys (dates) so the list is chronological
            let groupedSets = setsGroupedByDate()
            let sortedDates = groupedSets.keys.sorted(by: >) // Newest date first
            
            if loggedSets.isEmpty {
                // MARK: Empty State
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Workout History")
                        .font(.title2)
                    Text("Start a workout and log a set to see your history here.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
            } else {
                // MARK: History List
                List {
                    // Iterate through the dates (each date represents a workout day)
                    ForEach(sortedDates, id: \.self) { date in
                        // Use a Section header for the date
                        Section(header: Text(HistoryView.dateFormatter.string(from: date))) {
                            // Safely unwrap the sets for this date
                            if let setsForDay = groupedSets[date] {
                                // Further group the sets by the exercise name, since a user
                                // may have logged multiple sets for one exercise on a given day.
                                let groupedByExercise = Dictionary(grouping: setsForDay) {
                                    $0.exercise?.exerciseName ?? "Unknown Exercise"
                                }
                                
                                // Sort exercise names for consistent display
                                ForEach(groupedByExercise.keys.sorted(), id: \.self) { exerciseName in
                                    // Safely unwrap the sets for this specific exercise
                                    if let setsForExercise = groupedByExercise[exerciseName] {
                                        // Display the exercise name as the row header
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(exerciseName)
                                                .font(.headline)
                                                .foregroundColor(.accentColor)
                                            
                                            // Display all logged sets for this exercise on this day
                                            ForEach(setsForExercise.sorted(by: { $0.dateLogged ?? Date.distantPast < $1.dateLogged ?? Date.distantPast }), id: \.self) { logSet in
                                                HStack {
                                                    Text("Set:")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    Spacer()
                                                    
                                                    // Display the logged weight
                                                    Text("\(String(format: "%.1f", logSet.weight)) kg")
                                                        .fontWeight(.medium)
                                                    
                                                    Text("x")
                                                    
                                                    // Display the logged reps
                                                    Text("\(logSet.reps) reps")
                                                        .fontWeight(.medium)
                                                }
                                            }
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

// You'll need a preview for the new view
#Preview {
    HistoryView()
        // Provide the same Core Data environment for the preview
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
