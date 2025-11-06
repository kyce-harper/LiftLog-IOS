import SwiftUI
import CoreData

struct ContentView: View {
    // Inject the context
    @Environment(\.managedObjectContext) private var viewContext
    
    // State to control the full-screen Active Workout flow
    @State private var showingActiveWorkout = false

    var body: some View {
        TabView {
            // Templates / Planning
            NavigationStack {
                TemplateListView(startWorkoutAction: {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    showingActiveWorkout = true
                })
                .navigationTitle("Templates")
            }
            .tabItem {
                Label("Templates", systemImage: "list.bullet.rectangle")
            }
            
            // Workout History
            NavigationStack {
                HistoryView()
                    .navigationTitle("History")
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
        }
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            ActiveWorkoutView()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
