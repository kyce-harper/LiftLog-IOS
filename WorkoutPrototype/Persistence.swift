import CoreData
import Foundation

struct PersistenceController {
    // MARK: - 1. Singleton and Preview Configuration
    
    // The single instance used throughout the app
    static let shared = PersistenceController()

    // Configuration used only for Xcode Previews (in-memory store with sample data)
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // --- PRE-POPULATE PREVIEW DATA ---
        
        // 1. Create a Template
        let pushDay = WorkoutTemplate(context: context)
        pushDay.name = "Push Day (Template)"
        pushDay.dateCreated = Date().addingTimeInterval(-86400 * 30) // 30 days ago

        // 2. Add Exercises to the Template
        let benchPress = TemplateExercise(context: context)
        benchPress.exerciseName = "Barbell Bench Press"
        benchPress.targetSets = 4
        benchPress.order = 1
        benchPress.template = pushDay // Link to Template
        
        let overheadPress = TemplateExercise(context: context)
        overheadPress.exerciseName = "Overhead Press"
        overheadPress.targetSets = 3
        overheadPress.order = 2
        overheadPress.template = pushDay // Link to Template
        
        // 3. Log Historical Sets for Bench Press (Progressive Overload Data)
        let oldSet = LoggedSet(context: context)
        oldSet.dateLogged = Date().addingTimeInterval(-86400 * 7) // 1 week ago
        oldSet.weight = 135.0
        oldSet.reps = 10
        oldSet.exercise = benchPress // Link to TemplateExercise
        
        let recentSet = LoggedSet(context: context)
        recentSet.dateLogged = Date().addingTimeInterval(-86400) // 1 day ago
        recentSet.weight = 140.0 // Progressive overload!
        recentSet.reps = 8
        recentSet.exercise = benchPress // Link to TemplateExercise
        
        controller.saveContext()
        return controller
    }()

    // MARK: - 2. Core Data Stack

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // ⚠️ Verify "WorkoutPrototype" matches your .xcdatamodeld file name!
        container = NSPersistentContainer(name: "WorkoutPrototype")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error loading Core Data store: \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = nil // Simple app: disable undo manager for performance
    }

    // MARK: - 3. Save Function (U & D Helper)

    // The fundamental function to persist any changes (Create, Update, Delete)
    func saveContext() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                // Log the error to the console instead of fatalError in a robust app
                print("Unresolved error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - 4. CRUD Functions for TEMPLATES (The Blueprint)

    /// Creates and saves a new WorkoutTemplate.
    func createTemplate(name: String) {
        let context = container.viewContext
        let newTemplate = WorkoutTemplate(context: context)
        
        newTemplate.name = name
        newTemplate.dateCreated = Date()
        
        saveContext()
    }
    
    /// Deletes a WorkoutTemplate and, via Cascade rule, all associated TemplateExercises and LoggedSets.
    func deleteTemplate(template: WorkoutTemplate) {
        container.viewContext.delete(template)
        saveContext()
    }
    
    // MARK: - 5. CRUD Functions for TEMPLATE EXERCISES (Building the Blueprint)

    /// Adds a new exercise definition to an existing WorkoutTemplate.
    func addExercise(to template: WorkoutTemplate, name: String, targetSets: Int) {
        let context = container.viewContext
        let newExercise = TemplateExercise(context: context)
        
        newExercise.exerciseName = name
        newExercise.targetSets = Int16(targetSets)
        
        // Find the current highest order to assign the next order number
        let currentMaxOrder = (template.exercises as? Set<TemplateExercise>)?
            .map { $0.order }
            .max() ?? 0
            
        newExercise.order = currentMaxOrder + 1
        
        // ESTABLISH THE RELATIONSHIP
        newExercise.template = template
        
        saveContext()
    }
    
    /// Deletes a TemplateExercise and all associated LoggedSets (via Cascade rule).
    func deleteExercise(exercise: TemplateExercise) {
        container.viewContext.delete(exercise)
        saveContext()
    }
    
    // MARK: - 6. CRUD Functions for LOGGED SETS (The History/Data Entry)

    /// Creates and links a new LoggedSet to a specific TemplateExercise.
    /// This is the core action when the user inputs their weight/reps during a workout.
    func logSet(for exercise: TemplateExercise, weight: Double, reps: Int) {
        let context = container.viewContext
        let newSet = LoggedSet(context: context)
        
        newSet.dateLogged = Date() // Mark time of logging
        newSet.weight = weight
        newSet.reps = Int16(reps)
        
        // ESTABLISH THE RELATIONSHIP (The key to progressive tracking)
        newSet.exercise = exercise
        
        saveContext()
    }
}
