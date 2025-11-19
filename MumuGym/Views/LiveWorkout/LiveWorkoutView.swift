import SwiftUI
import CoreData

struct LiveWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    let template: WorkoutTemplate?
    
    @StateObject private var workoutSession = WorkoutSession()
    @State private var showingEndWorkoutAlert = false
    @State private var showingAddExercise = false
    @State private var currentExerciseIndex = 0
    
    init(template: WorkoutTemplate? = nil) {
        self.template = template
    }
    
    var body: some View {
        NavigationView {
            Group {
                if workoutSession.isActive {
                    activeWorkoutView
                } else {
                    workoutSetupView
                }
            }
            .navigationBarBackButtonHidden(workoutSession.isActive)
            .toolbar {
                if workoutSession.isActive {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("End") {
                            showingEndWorkoutAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .alert("End Workout", isPresented: $showingEndWorkoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Workout", role: .destructive) {
                endWorkout()
            }
        } message: {
            Text("Are you sure you want to end this workout? Your progress will be saved.")
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToWorkoutView { exercise in
                addExerciseToWorkout(exercise)
            }
        }
        .onAppear {
            if let template = template {
                setupWorkoutFromTemplate(template)
            }
        }
    }
    
    private var workoutSetupView: some View {
        ScrollView {
            VStack(spacing: 25) {
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Ready to Workout?")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Start a new workout session or continue from a template")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    Button("Start Empty Workout") {
                        startEmptyWorkout()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    NavigationLink(destination: TemplatesView()) {
                        Text("Choose Template")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navigationTitle("Workout")
    }
    
    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
            workoutHeader
            
            if !workoutSession.exercises.isEmpty {
                currentExerciseView
            } else {
                emptyWorkoutView
            }
            
            workoutControls
        }
    }
    
    private var workoutHeader: some View {
        VStack(spacing: 8) {
            Text(workoutSession.workoutName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("\(workoutSession.formattedDuration)")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.orange)
                    Text("\(currentExerciseIndex + 1)/\(workoutSession.exercises.count)")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var currentExerciseView: some View {
        ScrollView {
            if currentExerciseIndex < workoutSession.exercises.count {
                let exercise = workoutSession.exercises[currentExerciseIndex]
                CurrentExerciseView(
                    exercise: exercise,
                    onNextExercise: moveToNextExercise,
                    onPreviousExercise: moveToPreviousExercise,
                    canGoNext: currentExerciseIndex < workoutSession.exercises.count - 1,
                    canGoPrevious: currentExerciseIndex > 0
                )
            }
        }
    }
    
    private var emptyWorkoutView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Add your first exercise")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to add exercises to your workout")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
    
    private var workoutControls: some View {
        HStack(spacing: 16) {
            Button(action: addExercise) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Exercise")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button("Finish") {
                showingEndWorkoutAlert = true
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
    }
    
    private func setupWorkoutFromTemplate(_ template: WorkoutTemplate) {
        let templateExercises = (template.exercises as? Set<WorkoutTemplateExercise> ?? [])
            .sorted { $0.order < $1.order }
        
        workoutSession.setupFromTemplate(template, exercises: templateExercises)
    }
    
    private func startEmptyWorkout() {
        workoutSession.startEmptyWorkout()
    }
    
    private func addExercise() {
        showingAddExercise = true
    }
    
    private func addExerciseToWorkout(_ exercise: Exercise) {
        let liveExercise = LiveExercise(
            name: exercise.name ?? "Unknown",
            targetMuscle: exercise.targetMuscle,
            instructions: exercise.instructions,
            imageUrl: exercise.imageUrl,
            restTime: 60
        )
        
        // Add 3 default sets
        for _ in 0..<3 {
            liveExercise.addSet()
        }
        
        workoutSession.exercises.append(liveExercise)
    }
    
    private func moveToNextExercise() {
        if currentExerciseIndex < workoutSession.exercises.count - 1 {
            currentExerciseIndex += 1
        }
    }
    
    private func moveToPreviousExercise() {
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
        }
    }
    
    private func endWorkout() {
        workoutSession.endWorkout(context: viewContext, user: authManager.currentUser)
    }
}

struct CurrentExerciseView: View {
    @ObservedObject var exercise: LiveExercise
    let onNextExercise: () -> Void
    let onPreviousExercise: () -> Void
    let canGoNext: Bool
    let canGoPrevious: Bool
    
    @StateObject private var restTimer = RestTimer()
    
    var body: some View {
        VStack(spacing: 25) {
            exerciseHeader
            setsSection
            restSection
            navigationButtons
        }
        .padding(20)
    }
    
    private var exerciseHeader: some View {
        VStack(spacing: 16) {
            DetailedExerciseImageView(
                imageUrl: exercise.imageUrl,
                exerciseName: exercise.name
            )
            
            Text(exercise.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            if let targetMuscle = exercise.targetMuscle {
                Text(targetMuscle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.blue)
                    .cornerRadius(20)
            }
            
            if let instructions = exercise.instructions {
                Text(instructions)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var setsSection: some View {
        VStack(spacing: 16) {
            Text("Sets")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(exercise.sets.indices, id: \.self) { index in
                    SetRow(
                        set: $exercise.sets[index],
                        setNumber: index + 1,
                        onComplete: { startRest() }
                    )
                }
            }
            
            Button("Add Set") {
                exercise.addSet()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var restSection: some View {
        Group {
            if restTimer.isActive {
                RestTimerView(timer: restTimer)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(16)
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            Button("Previous") {
                onPreviousExercise()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canGoPrevious ? Color.gray : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(!canGoPrevious)
            
            Button("Next") {
                onNextExercise()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canGoNext ? Color.blue : Color.blue.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(!canGoNext)
        }
    }
    
    private func startRest() {
        restTimer.start(duration: exercise.restTime)
    }
}

struct SetRow: View {
    @Binding var set: LiveSet
    let setNumber: Int
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("\(setNumber)")
                .font(.headline)
                .fontWeight(.bold)
                .frame(width: 35, height: 35)
                .background(set.completed ? Color.green.opacity(0.2) : Color.blue.opacity(0.1))
                .foregroundColor(set.completed ? .green : .blue)
                .cornerRadius(17.5)
            
            // Reps input
            VStack(spacing: 4) {
                Text("Reps")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                TextField("0", value: $set.reps, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 55)
                    .multilineTextAlignment(.center)
            }
            
            // Weight input
            VStack(spacing: 4) {
                Text("Weight (kg)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                TextField("0.0", value: $set.weight, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Completion button
            Button(action: toggleCompletion) {
                HStack(spacing: 6) {
                    Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                    Text(set.completed ? "Done" : "Mark")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(set.completed ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(set.completed ? Color.green : Color.gray.opacity(0.2))
                .cornerRadius(16)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(set.completed ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
    
    private func toggleCompletion() {
        set.completed.toggle()
        if set.completed && set.reps > 0 {
            onComplete()
        }
    }
}

struct RestTimerView: View {
    @ObservedObject var timer: RestTimer
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Rest Time")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !timer.isPaused {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .scaleEffect(timer.isActive ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 1).repeatForever(), value: timer.isActive)
                }
            }
            
            Text("\(timer.remainingTime)")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
                .padding(.vertical, 8)
            
            HStack(spacing: 16) {
                Button("Skip Rest") {
                    timer.stop()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)
                .fontWeight(.medium)
                
                Button(timer.isPaused ? "Resume" : "Pause") {
                    timer.togglePause()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(timer.isPaused ? Color.green : Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.medium)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(configuration.isPressed ? Color.gray.opacity(0.8) : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct AddExerciseToWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        entity: Exercise.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
    ) private var exercises: FetchedResults<Exercise>
    
    let onExerciseSelected: (Exercise) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(exercises, id: \.objectID) { exercise in
                    ExerciseCardWithImage(exercise: exercise) {
                        onExerciseSelected(exercise)
                        dismiss()
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LiveWorkoutView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager.shared)
}