import SwiftUI
import CoreData

struct ContentView: View {
    // Inject the context
    @Environment(\.managedObjectContext) private var viewContext
    
    // State to control the full-screen Active Workout flow
    @State private var showingActiveWorkout = false

    var body: some View {
        // Use a TabView to structure the app (Templates and History)
        TabView {
            // MARK: - Tab 1: Template Builder (The main screen)
            // FIX: TemplateListView requires the startWorkoutAction closure.
            // This closure sets the state variable to true, launching the fullScreenCover.
            TemplateListView(startWorkoutAction: { showingActiveWorkout = true })
                .tabItem {
                    Label("Plan", systemImage: "dumbbell.fill")
                }
            
            // MARK: - Tab 2: Workout History (Active)
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
        }
        // Launch the ActiveWorkoutView as a full screen cover when the state changes
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            // FIX: ActiveWorkoutView does not take an 'isPresented' argument.
            // It uses @Environment(\.dismiss) internally.
            ActiveWorkoutView()
        }
    }
}

#Preview {
    // Uses the preview configuration from the PersistenceController
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
