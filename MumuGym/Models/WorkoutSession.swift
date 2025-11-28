import Foundation
import CoreData
import SwiftUI
import Combine

class WorkoutSession: ObservableObject {
    @Published var isActive = false
    @Published var workoutName = "Workout"
    @Published var startTime = Date()
    @Published var exercises: [LiveExercise] = []
    @Published var currentDuration = 0
    
    private var timer: Timer?
    private let backgroundQueue = DispatchQueue(label: "workout.timer", qos: .background)
    
    var formattedDuration: String {
        let hours = currentDuration / 3600
        let minutes = (currentDuration % 3600) / 60
        let seconds = currentDuration % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    func setupFromTemplate(_ template: WorkoutTemplate, exercises templateExercises: [WorkoutTemplateExercise]) {
        workoutName = template.name ?? "Workout"
        
        exercises = templateExercises.map { templateExercise in
            let liveExercise = LiveExercise(
                name: templateExercise.exercise?.name ?? "Unknown",
                targetMuscle: templateExercise.exercise?.targetMuscle,
                instructions: templateExercise.exercise?.instructions,
                imageUrl: templateExercise.exercise?.imageUrl,
                restTime: Int(templateExercise.restTime)
            )
            
            for _ in 0..<templateExercise.sets {
                liveExercise.addSet(
                    reps: Int(templateExercise.reps),
                    weight: templateExercise.weight
                )
            }
            
            return liveExercise
        }
        
        startWorkout()
    }
    
    func startEmptyWorkout() {
        workoutName = "Quick Workout"
        exercises = []
        startWorkout()
    }
    
    private func startWorkout() {
        isActive = true
        startTime = Date()
        currentDuration = 0
        
        // Save start time to UserDefaults for persistence
        UserDefaults.standard.set(startTime, forKey: "workout_start_time")
        UserDefaults.standard.set(true, forKey: "workout_active")
        UserDefaults.standard.set(workoutName, forKey: "workout_name")
        
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateDuration()
        }
    }
    
    private func updateDuration() {
        currentDuration = Int(Date().timeIntervalSince(startTime))
    }
    
    func resumeWorkoutIfActive() {
        // Check if workout was active when app closed
        guard UserDefaults.standard.bool(forKey: "workout_active") else { return }
        
        if let savedStartTime = UserDefaults.standard.object(forKey: "workout_start_time") as? Date {
            isActive = true
            startTime = savedStartTime
            workoutName = UserDefaults.standard.string(forKey: "workout_name") ?? "Workout"
            
            // Restore exercises from UserDefaults if needed
            restoreExercises()
            
            // Calculate current duration and start timer
            updateDuration()
            startTimer()
        }
    }
    
    private func saveExercises() {
        // Save exercises to UserDefaults for background persistence
        do {
            let data = try JSONEncoder().encode(exercises.map(LiveExerciseData.init))
            UserDefaults.standard.set(data, forKey: "workout_exercises")
        } catch {
            print("Failed to save exercises: \(error)")
        }
    }
    
    private func restoreExercises() {
        guard let data = UserDefaults.standard.data(forKey: "workout_exercises") else { return }
        
        do {
            let exerciseData = try JSONDecoder().decode([LiveExerciseData].self, from: data)
            exercises = exerciseData.map(LiveExercise.init)
        } catch {
            print("Failed to restore exercises: \(error)")
        }
    }
    
    func enterBackground() {
        // Save current state when entering background
        saveExercises()
    }
    
    func enterForeground() {
        // Update duration when returning to foreground
        if isActive {
            updateDuration()
        }
    }
    
    func endWorkout(context: NSManagedObjectContext, user: User?) {
        timer?.invalidate()
        timer = nil
        
        guard let user = user else { return }
        
        let workout = Workout(context: context)
        workout.name = workoutName
        workout.startTime = startTime
        workout.endTime = Date()
        workout.duration = Int32(currentDuration)
        workout.completed = true
        workout.user = user
        
        for (index, liveExercise) in exercises.enumerated() {
            if let exercise = findExercise(name: liveExercise.name, context: context) {
                let workoutExercise = WorkoutExercise(context: context)
                workoutExercise.order = Int16(index)
                workoutExercise.completed = liveExercise.isCompleted
                workoutExercise.restTime = Int32(liveExercise.restTime)
                workoutExercise.exercise = exercise
                workoutExercise.workout = workout
                
                for liveSet in liveExercise.sets {
                    let workoutSet = WorkoutSet(context: context)
                    workoutSet.reps = Int16(liveSet.reps)
                    workoutSet.weight = liveSet.weight
                    workoutSet.completed = liveSet.completed
                    workoutSet.workoutExercise = workoutExercise
                }
            }
        }
        
        try? context.save()
        
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "workout_start_time")
        UserDefaults.standard.removeObject(forKey: "workout_active")
        UserDefaults.standard.removeObject(forKey: "workout_name")
        UserDefaults.standard.removeObject(forKey: "workout_exercises")
        
        isActive = false
        exercises = []
        currentDuration = 0
    }
    
    private func findExercise(name: String, context: NSManagedObjectContext) -> Exercise? {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let exercises = try context.fetch(request)
            return exercises.first
        } catch {
            return nil
        }
    }
}

class LiveExercise: ObservableObject, Equatable {
    let id = UUID()
    @Published var name: String
    @Published var targetMuscle: String?
    @Published var instructions: String?
    @Published var imageUrl: String?
    @Published var sets: [LiveSet] = []
    @Published var restTime: Int
    
    static func == (lhs: LiveExercise, rhs: LiveExercise) -> Bool {
        return lhs.id == rhs.id
    }
    
    var isCompleted: Bool {
        return sets.allSatisfy { $0.completed }
    }
    
    init(name: String, targetMuscle: String? = nil, instructions: String? = nil, imageUrl: String? = nil, restTime: Int = 60) {
        self.name = name
        self.targetMuscle = targetMuscle
        self.instructions = instructions
        self.imageUrl = imageUrl
        self.restTime = restTime
    }
    
    func addSet(reps: Int = 0, weight: Double = 0.0) {
        let newSet = LiveSet(reps: reps, weight: weight)
        sets.append(newSet)
    }
}

class LiveSet: ObservableObject {
    @Published var reps: Int
    @Published var weight: Double
    @Published var completed: Bool
    
    init(reps: Int = 0, weight: Double = 0.0, completed: Bool = false) {
        self.reps = reps
        self.weight = weight
        self.completed = completed
    }
}

// MARK: - Codable Data Structures for Background Persistence

struct LiveExerciseData: Codable {
    let name: String
    let targetMuscle: String?
    let instructions: String?
    let imageUrl: String?
    let restTime: Int
    let sets: [LiveSetData]
    
    init(from exercise: LiveExercise) {
        self.name = exercise.name
        self.targetMuscle = exercise.targetMuscle
        self.instructions = exercise.instructions
        self.imageUrl = exercise.imageUrl
        self.restTime = exercise.restTime
        self.sets = exercise.sets.map(LiveSetData.init)
    }
}

struct LiveSetData: Codable {
    let reps: Int
    let weight: Double
    let completed: Bool
    
    init(from set: LiveSet) {
        self.reps = set.reps
        self.weight = set.weight
        self.completed = set.completed
    }
}

// MARK: - Extensions for Data Restoration

extension LiveExercise {
    convenience init(from data: LiveExerciseData) {
        self.init(
            name: data.name,
            targetMuscle: data.targetMuscle,
            instructions: data.instructions,
            imageUrl: data.imageUrl,
            restTime: data.restTime
        )
        
        self.sets = data.sets.map { setData in
            LiveSet(reps: setData.reps, weight: setData.weight, completed: setData.completed)
        }
    }
}

class RestTimer: ObservableObject {
    @Published var remainingTime = 0
    @Published var isActive = false
    @Published var isPaused = false
    
    private var timer: Timer?
    private var totalTime = 0
    
    var formattedTime: String {
        return remainingTime.formattedRestTime
    }
    
    func start(duration: Int) {
        totalTime = duration
        remainingTime = duration
        isActive = true
        isPaused = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !self.isPaused {
                self.remainingTime -= 1
                
                if self.remainingTime <= 0 {
                    self.stop()
                }
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isPaused = false
        remainingTime = 0
    }
    
    func togglePause() {
        isPaused.toggle()
    }
    
    func addTime(_ seconds: Int) {
        remainingTime += seconds
        if remainingTime < 0 {
            remainingTime = 0
        }
    }
}