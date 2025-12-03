import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MumuGym")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
            
            print("🏪 Core Data store loaded: \(description)")
            // Seed exercises when the store loads
            ExerciseData.seedExercises(context: container.viewContext)
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    func save() {
        if context.hasChanges {
            try? context.save()
        }
    }
    
    func ensureExercisesSeeded() {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        do {
            let count = try context.count(for: request)
            if count == 0 {
                print("🌱 No exercises found, forcing seed...")
                ExerciseData.seedExercises(context: context, forceReseed: true)
            } else {
                print("📋 Found \(count) exercises in database")
            }
        } catch {
            print("❌ Error checking exercise count: \(error)")
            // Force seed anyway if we can't check
            ExerciseData.seedExercises(context: context, forceReseed: true)
        }
    }
    
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        let sampleUser = User(context: context)
        sampleUser.firstName = "John"
        sampleUser.lastName = "Doe"
        sampleUser.email = "john@example.com"
        sampleUser.passwordHash = "hashed_password"
        sampleUser.age = 25
        sampleUser.gender = "Male"
        sampleUser.emailSubscription = true
        sampleUser.currentWeight = 75.0
        sampleUser.targetWeight = 80.0
        sampleUser.isActive = true
        
        try? context.save()
        return controller
    }()
    
    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MumuGym")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}