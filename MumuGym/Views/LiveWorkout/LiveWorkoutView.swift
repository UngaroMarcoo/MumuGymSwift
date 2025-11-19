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
            .background(Color.appBackground)
            .navigationBarBackButtonHidden(workoutSession.isActive)
            .navigationTitle(workoutSession.isActive ? "" : "Workout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if workoutSession.isActive {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("End") {
                            showingEndWorkoutAlert = true
                        }
                        .foregroundColor(.deleteButtonColor)
                        .fontWeight(.semibold)
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
        VStack(spacing: 32) {
            Spacer()
            
            // Header with gradient
            VStack(spacing: 16) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                Text("Ready to Workout?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Start a new workout session or continue from a template")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.warningGradient)
                    .shadow(color: Color.primaryOrange1.opacity(0.3), radius: 12, x: 0, y: 6)
            )
            
            // Action buttons
            VStack(spacing: 16) {
                Button("Start Empty Workout") {
                    startEmptyWorkout()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.successGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
                
                NavigationLink(destination: TemplatesView()) {
                    Text("Browse Templates")
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primaryOrange1, lineWidth: 2)
                                )
                        )
                        .foregroundColor(.primaryBlue1)
                        .fontWeight(.semibold)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
            )
            
            Spacer()
        }
        .padding(.horizontal, 20)
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
        VStack(spacing: 12) {
            Text(workoutSession.workoutName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color.primaryOrange1)
                    Text("\(workoutSession.formattedDuration)")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(Color.primaryOrange2)
                    Text("\(currentExerciseIndex + 1)/\(workoutSession.exercises.count)")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
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
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.primaryOrange1)
                    .shadow(color: Color.primaryOrange1.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Text("Add your first exercise")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Tap the + button to add exercises to your workout")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 25)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            
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
                .background(Color.buttonPrimary)
                .foregroundColor(.white)
                .cornerRadius(25)
                .fontWeight(.semibold)
                .shadow(color: Color.primaryOrange1.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            
            Button("Finish") {
                showingEndWorkoutAlert = true
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(25)
            .fontWeight(.semibold)
            .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: -4)
        )
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
                            gradient: Gradient(colors: [Color.primaryOrange1.opacity(0.2), Color.primaryOrange1.opacity(0.1)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(Color.primaryOrange1)
                    .cornerRadius(20)
            }
            
            if let instructions = exercise.instructions {
                Text(instructions)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
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
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.primaryOrange1)
            .cornerRadius(16)
            .shadow(color: Color.primaryOrange1.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
    
    private var restSection: some View {
        Group {
            if restTimer.isActive {
                RestTimerView(timer: restTimer)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
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
            .cornerRadius(25)
            .fontWeight(.semibold)
            .shadow(color: canGoPrevious ? Color.gray.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
            .disabled(!canGoPrevious)
            
            Button("Next") {
                onNextExercise()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canGoNext ? Color.buttonPrimary : LinearGradient(gradient: Gradient(colors: [Color.primaryOrange1.opacity(0.3), Color.primaryOrange2.opacity(0.3)]), startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
            .cornerRadius(25)
            .fontWeight(.semibold)
            .shadow(color: canGoNext ? Color.primaryOrange1.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
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
                .background(set.completed ? Color.green.opacity(0.2) : Color.primaryOrange1.opacity(0.1))
                .foregroundColor(set.completed ? .green : Color.primaryOrange1)
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
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.primaryOrange1, Color.primaryOrange2]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(exercises, id: \.objectID) { exercise in
                            ExerciseCardWithImage(exercise: exercise) {
                                onExerciseSelected(exercise)
                                dismiss()
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.medium)
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
