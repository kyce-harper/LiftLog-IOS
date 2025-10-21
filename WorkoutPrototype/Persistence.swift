import CoreData
import Foundation

struct PersistenceController {
    // MARK: - 1. Singleton and Preview Configuration
    
    // The single instance used throughout the app
    // Allows global access and ensure only one copy of database running
    static let shared = PersistenceController()

    // Configuration used only for Xcode Previews (in-memory store with sample data)/
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // --- PRE-POPULATE PREVIEW DATA ---
        
        // 1. Create a Workout Template
        let pushDay = WorkoutTemplate(context: context)
        pushDay.name = "Push Day (Template)"
        pushDay.dateCreated = Date().addingTimeInterval(-86400 * 30) // 30 days ago

        // 2. Create two Workout Sessions
        let session1 = WorkoutSession(context: context)
        session1.dateStarted = Date().addingTimeInterval(-86400 * 7) // 1 week ago
        session1.dateCompleted = Date().addingTimeInterval(-86400 * 7).addingTimeInterval(3600) // 1 hour later
        session1.template = pushDay // Link Session to Template

        let session2 = WorkoutSession(context: context)
        session2.dateStarted = Date().addingTimeInterval(-86400) // 1 day ago
        session2.dateCompleted = Date().addingTimeInterval(-86400).addingTimeInterval(2700) // 45 minutes later
        session2.template = pushDay

        // 3. Add Exercises to the Template
        let benchPress = TemplateExercise(context: context)
        benchPress.exerciseName = "Barbell Bench Press"
        benchPress.targetSets = 4
        benchPress.order = 1
        benchPress.template = pushDay
        
        let overheadPress = TemplateExercise(context: context)
        overheadPress.exerciseName = "Overhead Press"
        overheadPress.targetSets = 3
        overheadPress.order = 2
        overheadPress.template = pushDay
        
        // 4. Log Historical Sets (linking them to specific session)
        
        // LoggedSet from 1 week ago (linked to session1)
        let oldSet = LoggedSet(context: context)
        oldSet.dateLogged = session1.dateCompleted // Use session completion time
        oldSet.weight = 135.0
        oldSet.reps = 10
        oldSet.exercise = benchPress
        oldSet.session = session1 // Links to session1
        
        // LoggedSet from 1 day ago (linked to session2)
        let recentSet = LoggedSet(context: context)
        recentSet.dateLogged = session2.dateCompleted
        recentSet.weight = 140.0
        recentSet.reps = 8
        recentSet.exercise = benchPress
        recentSet.session = session2 // Links to Session 2
        
        // LoggedSet for Overhead Press (linked to session2)
        let opSet = LoggedSet(context: context)
        opSet.dateLogged = session2.dateCompleted!.addingTimeInterval(60) // Logged slightly later
        opSet.weight = 60.0
        opSet.reps = 12
        opSet.exercise = overheadPress
        opSet.session = session2 // Links to Session 2
        
        controller.saveContext()
        return controller
    }()

    // Core Data Stack

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {  // Initialize core data stack
        
        container = NSPersistentContainer(name: "WorkoutPrototype")

        if inMemory {  //Using for previews... maybe unit tests?
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error loading Core Data store: \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = nil
    }

    // Save Function
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
    
    // Basic CRUD functions

    // creates and saves new workouttemplate
    func createTemplate(name: String) {
        let context = container.viewContext
        let newTemplate = WorkoutTemplate(context: context)
        
        newTemplate.name = name
        newTemplate.dateCreated = Date()
        
        saveContext()
    }
    
    // Deletes WorkoutTemplate because of Cascade rule, all associated TemplateExercises and LoggedSets get deleted too
    func deleteTemplate(template: WorkoutTemplate) {
        container.viewContext.delete(template)
        saveContext()
    }

    // Adds a new exercise definition to an existing WorkoutTemplate.
    // Variables (template, exercisename, targetsets) this currently cannot be edited but maybe look into this in the future???
    func addExercise(to template: WorkoutTemplate, name: String, targetSets: Int) {
        let context = container.viewContext
        let newExercise = TemplateExercise(context: context)
        
        newExercise.exerciseName = name
        newExercise.targetSets = Int16(targetSets)
        
        // Find the current highest order to assign the next order number
        let currentMaxOrder = (template.exercises as? Set<TemplateExercise>)?
            .map { $0.order }
            .max() ?? 0 // no exercises defualt max order to 0
            
        newExercise.order = currentMaxOrder + 1
        
        // Establish the relationship
        newExercise.template = template
        
        // Save to the database
        saveContext()
    }
    
    // Deletes a TemplateExercise and all associated LoggedSets (Cascade rule)
    func deleteExercise(exercise: TemplateExercise) {
        container.viewContext.delete(exercise)
        saveContext()
    }

    // Creates and links a new LoggedSet to a specific TemplateExercise.
    // This is  when the user inputs their weight/reps during a workout.
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

// Added as extension after design shift for organized classes with WorkoutSession
extension PersistenceController {
    // Creates a new WorkoutSession linked to the template and saves the context.parameter(template)returns(workoutSession)
    func startNewSession(for template: WorkoutTemplate) -> WorkoutSession {
        let context = container.viewContext
        // NOTE: This requires the Core Data entity 'WorkoutSession' to exist.
        let newSession = WorkoutSession(context: context)
        
        newSession.dateStarted = Date()
        newSession.template = template // Link to the template used
        
        saveContext()
        return newSession
    }
    
    // Updates an existing session by setting its completion time.
    func completeSession(session: WorkoutSession) {
        session.dateCompleted = Date()
        saveContext()
    }
    
    // Creates and links a new LoggedSet to a specific TemplateExercise AND a specific WorkoutSession.parameters(templateExercise, weight, reps, workoutSession(tolinkto)
    func logSet(for exercise: TemplateExercise, weight: Double, reps: Int, session: WorkoutSession) {
        let context = container.viewContext
        let newSet = LoggedSet(context: context)
        
        newSet.dateLogged = Date() // Mark time of logging
        newSet.weight = weight
        newSet.reps = Int16(reps)
        
        // ESTABLISH RELATIONSHIPS
        newSet.exercise = exercise
        newSet.session = session // Link to the current session
        saveContext()
    }
}
