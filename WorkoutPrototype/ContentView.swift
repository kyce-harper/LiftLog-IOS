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
            // Template Builder (The main screen)
            TemplateListView(startWorkoutAction: { showingActiveWorkout = true })
                .tabItem {
                    Label("Plan", systemImage: "dumbbell.fill")
                }
            
            // Workout History (Active)
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
        }
        // Launch the ActiveWorkoutView as a full screen cover when the state changes
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            ActiveWorkoutView()
        }
    }
}

#Preview {
    // Uses the preview configuration from the PersistenceController
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
