import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct LiveWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let template: WorkoutTemplate?
    
    @StateObject private var workoutSession = WorkoutSession()
    @State private var showingEndWorkoutAlert = false
    @State private var showingAddExercise = false
    @State private var currentExerciseIndex = 0
    @State private var showingExerciseList = false
    @State private var showingExercisePicker = false
    @State private var showingExerciseConfiguration = false
    @State private var selectedExerciseForConfig: Exercise?
    @State private var selectedTemplate: WorkoutTemplate?
    
    @FetchRequest(
        entity: WorkoutTemplate.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutTemplate.createdDate, ascending: false)]
    ) private var templates: FetchedResults<WorkoutTemplate>
    
    @FetchRequest(
        entity: Exercise.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
    ) private var availableExercises: FetchedResults<Exercise>
    
    init(template: WorkoutTemplate? = nil) {
        self.template = template
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !workoutSession.isActive {
                    // Custom title section for setup view
                    HStack {
                        Text("Workout")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.cardBackground)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                }
                
                Group {
                    if workoutSession.isActive {
                        activeWorkoutView
                    } else {
                        workoutSetupView
                    }
                }
            }
            .background(themeManager.currentBackgroundGradient)
            .navigationBarBackButtonHidden(workoutSession.isActive)
            .navigationBarHidden(!workoutSession.isActive)
            .toolbar {
                if workoutSession.isActive {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("\(workoutSession.formattedDuration)")
                            .font(workoutSession.currentDuration >= 3600 ? .caption2 : .caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.3))
                            )
                            .fixedSize()
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Finish") {
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
        .fullScreenCover(isPresented: $showingExerciseList) {
            LiveWorkoutExerciseListView(
                exercises: workoutSession.exercises,
                currentIndex: $currentExerciseIndex,
                onReorder: { from, to in
                    workoutSession.exercises.move(fromOffsets: from, toOffset: to)
                },
                onDismiss: {
                    showingExerciseList = false
                }
            )
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(
                exercises: Array(availableExercises),
                onExerciseAdded: { exerciseData in
                    addExerciseFromTemplate(exerciseData)
                }
            )
        }
        .sheet(isPresented: $showingExerciseConfiguration) {
            if let exercise = selectedExerciseForConfig {
                ExerciseConfigurationView(
                    exercise: exercise,
                    onSave: { exerciseData in
                        addExerciseFromTemplate(exerciseData)
                        showingExerciseConfiguration = false
                        selectedExerciseForConfig = nil
                    }
                )
            }
        }
        .onAppear {
            // First, try to resume any active workout
            workoutSession.resumeWorkoutIfActive()
            
            // Update duration if returning to an active workout
            if workoutSession.isActive {
                workoutSession.enterForeground()
            }
            
            // Only setup from template if no workout is active
            if !workoutSession.isActive, let template = template {
                setupWorkoutFromTemplate(template)
            }
            
            // Add notification observers for app lifecycle
            NotificationCenter.default.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                workoutSession.enterBackground()
            }
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                workoutSession.enterForeground()
            }
        }
        .onDisappear {
            // Save workout state when leaving the view
            if workoutSession.isActive {
                workoutSession.enterBackground()
            }
            
            // Remove observers to prevent memory leaks
            NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }
    
    private var workoutSetupView: some View {
        Group {
            if templates.isEmpty {
                emptyTemplatesView
            } else {
                templatesListView
            }
        }
    }
    
    private var emptyTemplatesView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.primaryGreen1)
                    
                    Text("Ready to Workout?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Start your first workout session")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                
                Button("Start Empty Workout") {
                    startEmptyWorkout()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
            )
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var templatesListView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header section
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose Your Workout")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.cardBackground)
                        
                        Text("Select a template or start empty")
                            .font(.subheadline)
                            .foregroundColor(.surfaceBackground)
                    }
                    
                    Spacer()
                    
                    Button(action: startEmptyWorkout) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Empty")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Templates list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(templates, id: \.objectID) { template in
                            FullWidthTemplateCard(
                                template: template,
                                screenWidth: geometry.size.width,
                                onTapCard: {
                                    selectedTemplate = template
                                },
                                onTapPlay: {
                                    setupWorkoutFromTemplate(template)
                                }
                            )
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(template: template)
        }
    }
    
    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
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
                
                Button(action: { showingExerciseList = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(Color.primaryOrange2)
                        Text("\(currentExerciseIndex + 1)/\(workoutSession.exercises.count)")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(12)
                }
                .disabled(workoutSession.exercises.isEmpty)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .padding(.top, 10)
    }
    
    @StateObject private var restTimer = RestTimer()
    
    private var currentExerciseView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if currentExerciseIndex < workoutSession.exercises.count {
                    let exercise = workoutSession.exercises[currentExerciseIndex]
                    
                    // Exercise header card
                    CurrentExerciseHeaderView(
                        exercise: exercise,
                        onShowExerciseList: { showingExerciseList = true },
                        currentExerciseIndex: currentExerciseIndex,
                        totalExercises: workoutSession.exercises.count
                    )
                    .padding(.horizontal, 20)
                    
                    // Show either sets card or rest timer card
                    if restTimer.isActive {
                        // Rest timer card
                        RestTimerCardView(
                            restTimer: restTimer,
                            onSkipRest: {
                                restTimer.stop()
                            }
                        )
                        .padding(.horizontal, 20)
                    } else {
                        // Sets card
                        CurrentExerciseSetsView(
                            exercise: exercise,
                            onNextExercise: moveToNextExercise,
                            onPreviousExercise: moveToPreviousExercise,
                            canGoNext: currentExerciseIndex < workoutSession.exercises.count - 1,
                            canGoPrevious: currentExerciseIndex > 0,
                            onAddExercise: addExercise,
                            onSetCompleted: {
                                startRestTimer(for: exercise)
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
    
    private func startRestTimer(for exercise: LiveExercise) {
        restTimer.start(duration: exercise.restTime)
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
                
                Text("Start building your workout by adding exercises")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Add Exercise") {
                    addExercise()
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
        // Empty view - Add Exercise button moved to sets section
        EmptyView()
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
        showingExercisePicker = true
    }
    
    private func addExerciseFromTemplate(_ exerciseData: TemplateExerciseData) {
        let liveExercise = LiveExercise(
            name: exerciseData.exercise.name ?? "Unknown",
            targetMuscle: exerciseData.exercise.targetMuscle,
            instructions: exerciseData.exercise.instructions,
            imageUrl: exerciseData.exercise.imageUrl,
            restTime: exerciseData.restTime
        )
        
        // Add configured number of sets with configured reps and weight
        for _ in 0..<exerciseData.sets {
            let set = LiveSet()
            set.reps = exerciseData.reps
            set.weight = exerciseData.weight
            set.completed = false
            liveExercise.sets.append(set)
        }
        
        workoutSession.exercises.append(liveExercise)
        currentExerciseIndex = workoutSession.exercises.count - 1
        
        // Save updated exercises to UserDefaults for persistence
        workoutSession.enterBackground()
        
        showingExercisePicker = false
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

struct FullWidthTemplateCard: View {
    let template: WorkoutTemplate
    let screenWidth: CGFloat
    let onTapCard: () -> Void
    let onTapPlay: () -> Void
    
    var exerciseCount: Int {
        template.exercises?.count ?? 0
    }
    
    var body: some View {
        Button(action: onTapCard) {
            HStack(spacing: 16) {
                // Template info
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name ?? "Unknown")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text("\(exerciseCount) exercises")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        if let goal = template.goal {
                            Text("•")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(goal)
                                .font(.subheadline)
                                .foregroundColor(.primaryOrange1)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
                
                // Start button
                Button(action: onTapPlay) {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.cardBackground)
                        .background(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 40, height: 40)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .frame(width: screenWidth - 32)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - New Template-Style Card Views
struct CurrentExerciseHeaderView: View {
    @ObservedObject var exercise: LiveExercise
    let onShowExerciseList: () -> Void
    let currentExerciseIndex: Int
    let totalExercises: Int
    
    var body: some View {
        VStack(spacing: 16) {
            DetailedExerciseImageView(
                imageUrl: exercise.imageUrl,
                exerciseName: exercise.name
            )
            
            Text(exercise.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            HStack {
                Text(exercise.targetMuscle ?? "Unknown")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primaryOrange1)
                    .cornerRadius(12)
                
                Spacer()
                
                Button(action: onShowExerciseList) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                        Text("\(currentExerciseIndex + 1)/\(totalExercises)")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            if let instructions = exercise.instructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
}

struct CurrentExerciseSetsView: View {
    @ObservedObject var exercise: LiveExercise
    @ObservedObject private var themeManager = ThemeManager.shared
    let onNextExercise: () -> Void
    let onPreviousExercise: () -> Void
    let canGoNext: Bool
    let canGoPrevious: Bool
    let onAddExercise: () -> Void
    let onSetCompleted: () -> Void
    
    private var previousButtonBackground: AnyShapeStyle {
        if canGoPrevious {
            return AnyShapeStyle(themeManager.currentBackgroundGradient)
        } else {
            return AnyShapeStyle(themeManager.currentBackgroundGradient.opacity(0.4))
        }
    }
    
    private var nextButtonBackground: AnyShapeStyle {
        if canGoNext {
            return AnyShapeStyle(themeManager.currentBackgroundGradient)
        } else {
            return AnyShapeStyle(themeManager.currentBackgroundGradient.opacity(0.4))
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sets")
                .font(.title3)
                .fontWeight(.bold)
            
            LazyVStack(spacing: 12) {
                ForEach(exercise.sets.indices, id: \.self) { index in
                    SetRow(
                        set: $exercise.sets[index],
                        setNumber: index + 1,
                        onComplete: onSetCompleted,
                        onRemove: exercise.sets.count > 1 ? {
                            exercise.removeSet(at: index)
                        } : nil
                    )
                }
            }
            
            // Add Set button (circular)
            HStack {
                Spacer()
                Button(action: { exercise.addSet() }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.successGradient)
                        .clipShape(Circle())
                }
                Spacer()
            }
            
            // Navigation buttons
            HStack(spacing: 16) {
                Button("Previous") {
                    onPreviousExercise()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(previousButtonBackground)
                .foregroundColor(.white)
                .cornerRadius(25)
                .fontWeight(.semibold)
                .disabled(!canGoPrevious)
                
                Button("Next") {
                    onNextExercise()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(nextButtonBackground)
                .foregroundColor(.white)
                .cornerRadius(25)
                .fontWeight(.semibold)
                .disabled(!canGoNext)
            }
            
            Button("Add Exercise") {
                onAddExercise()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.successGradient)
            .foregroundColor(.white)
            .cornerRadius(25)
            .fontWeight(.semibold)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
}

struct RestTimerCardView: View {
    @ObservedObject var restTimer: RestTimer
    let onSkipRest: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Rest Time")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !restTimer.isPaused {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .scaleEffect(restTimer.isActive ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 1).repeatForever(), value: restTimer.isActive)
                }
            }
            
            Text(restTimer.formattedTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
                .padding(.vertical, 8)
            
            HStack(spacing: 16) {
                Button("Skip Rest") {
                    onSkipRest()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(25)
                .fontWeight(.semibold)
                
                Button(restTimer.isPaused ? "Resume" : "Pause") {
                    restTimer.togglePause()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(restTimer.isPaused ? Color.green : Color.orange)
                .foregroundColor(.white)
                .cornerRadius(25)
                .fontWeight(.semibold)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
}

struct CurrentExerciseView: View {
    @ObservedObject var exercise: LiveExercise
    let onNextExercise: () -> Void
    let onPreviousExercise: () -> Void
    let canGoNext: Bool
    let canGoPrevious: Bool
    let onAddExercise: () -> Void
    let onShowExerciseList: () -> Void
    let currentExerciseIndex: Int
    let totalExercises: Int
    
    @StateObject private var restTimer = RestTimer()
    
    var body: some View {
        VStack(spacing: 25) {
            exerciseHeader
            setsSection
            restSection
            navigationButtons
            addExerciseButton
        }
        .padding(.vertical, 25)
        .padding(.horizontal, 20)
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
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
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
                        onComplete: { startRest() },
                        onRemove: exercise.sets.count > 1 ? {
                            exercise.removeSet(at: index)
                        } : nil
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
            .background(canGoNext ? Color.buttonPrimary : LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]), startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
            .cornerRadius(25)
            .fontWeight(.semibold)
            .shadow(color: canGoNext ? Color.primaryOrange1.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
            .disabled(!canGoNext)
        }
    }
    
    private var addExerciseButton: some View {
        HStack(spacing: 12) {
            Button("Add Exercise") {
                onAddExercise()
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.primaryOrange1)
            .cornerRadius(16)
            .shadow(color: Color.primaryOrange1.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Button(action: onShowExerciseList) {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                    Text("\(currentExerciseIndex + 1)/\(totalExercises)")
                        .fontWeight(.medium)
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
    let onRemove: (() -> Void)?
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var showingRepsPicker = false
    @State private var showingWeightPicker = false
    @FocusState private var isRepsFieldFocused: Bool
    @FocusState private var isWeightFieldFocused: Bool
    
    private var completeButtonBackground: AnyShapeStyle {
        if set.completed {
            return AnyShapeStyle(Color.green)
        } else if canComplete {
            return AnyShapeStyle(themeManager.currentBackgroundGradient)
        } else {
            return AnyShapeStyle(LinearGradient(gradient: Gradient(colors: [Color.textSecondary.opacity(0.3), Color.textSecondary.opacity(0.3)]), startPoint: .leading, endPoint: .trailing))
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Set number with improved styling
                Text("\(setNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(width: 40, height: 40)
                    .background(setNumberBackground)
                    .foregroundColor(set.completed ? .white : themeManager.customBackgroundColor)
                    .shadow(color: set.completed ? Color.green.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 8) {
                    if set.completed {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    } else if set.reps > 0 || set.weight > 0 {
                        Label("In Progress", systemImage: "clock.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    } else {
                        Label("Not Started", systemImage: "circle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Remove button
                if let onRemove = onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
            }
            
            // Input fields with better UX
            HStack(spacing: 16) {
                // Reps input with tap-to-edit
                VStack(spacing: 8) {
                    Text("REPS")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingRepsPicker = true }) {
                        Text(set.reps > 0 ? "\(set.reps)" : "—")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(set.reps > 0 ? .textPrimary : .textSecondary)
                            .frame(minWidth: 60)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(set.reps > 0 ? Color.blue.opacity(0.3) : Color.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                // Weight input with tap-to-edit
                VStack(spacing: 8) {
                    Text("WEIGHT (KG)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingWeightPicker = true }) {
                        Text(set.weight > 0 ? String(format: "%.1f", set.weight) : "—")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(set.weight > 0 ? .textPrimary : .textSecondary)
                            .frame(minWidth: 80)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(set.weight > 0 ? Color.blue.opacity(0.3) : Color.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            
            // Action button
            Button(action: toggleCompletion) {
                HStack(spacing: 8) {
                    Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                    
                    Text(set.completed ? "Completed" : "Complete Set")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(completeButtonBackground)
                )
                .foregroundColor(.white)
                .shadow(color: set.completed ? Color.green.opacity(0.3) : (canComplete ? themeManager.customBackgroundColor.opacity(0.3) : Color.clear), radius: 4, x: 0, y: 2)
            }
            .disabled(set.completed)
        }
        .padding(16)
        .background(setRowBackground)
        .sheet(isPresented: $showingRepsPicker) {
            NumberPickerView(
                title: "Reps for Set \(setNumber)",
                value: $set.reps,
                range: 1...100,
                increment: 1
            )
        }
        .sheet(isPresented: $showingWeightPicker) {
            NumberPickerView(
                title: "Weight for Set \(setNumber)",
                value: Binding(
                    get: { Int(set.weight * 2) }, // Convert to 0.5kg increments
                    set: { set.weight = Double($0) / 2.0 }
                ),
                range: 0...400, // 0kg to 200kg in 0.5kg increments  
                increment: 1,
                formatter: { value in String(format: "%.1f kg", Double(value) / 2.0) }
            )
        }
    }
    
    private var canComplete: Bool {
        return set.reps > 0
    }
    
    private var setNumberBackground: some View {
        Circle()
            .fill(set.completed ? Color.green : themeManager.customBackgroundColor.opacity(0.1))
            .overlay(
                Circle()
                    .stroke(set.completed ? Color.clear : themeManager.customBackgroundColor.opacity(0.3), lineWidth: 2)
            )
    }
    
    private var setRowBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.surfaceBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(set.completed ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
    
    private func toggleCompletion() {
        if !set.completed && canComplete {
            set.completed = true
            onComplete()
        } else if set.completed {
            set.completed = false
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
            
            Text(timer.formattedTime)
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

struct ExerciseReorderView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exercises: [LiveExercise]
    @Binding var currentIndex: Int
    
    @State private var draggedItem: LiveExercise?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundColor(Color.primaryOrange1)
                        
                        Text("Exercise Order")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    Text("Tap an exercise to jump to it, or drag to reorder")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                
                // Exercise List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(exercises.indices, id: \.self) { index in
                            ExerciseReorderRow(
                                exercise: exercises[index],
                                index: index,
                                currentIndex: currentIndex,
                                onTap: {
                                    currentIndex = index
                                    dismiss()
                                }
                            )
                            .onDrag {
                                draggedItem = exercises[index]
                                return NSItemProvider(object: String(index) as NSString)
                            }
                            .onDrop(of: [.text], delegate: ExerciseDropDelegate(
                                destinationItem: exercises[index],
                                exercises: $exercises,
                                draggedItem: $draggedItem,
                                currentIndex: $currentIndex
                            ))
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                }
                .background(Color.gray.opacity(0.1))
            }
            .navigationTitle("Workout Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryBlue1)
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct ExerciseReorderRow: View {
    let exercise: LiveExercise
    let index: Int
    let currentIndex: Int
    let onTap: () -> Void
    
    private var isCurrentExercise: Bool {
        index == currentIndex
    }
    
    private var completedSets: Int {
        exercise.sets.filter { $0.completed }.count
    }
    
    private var exerciseNumberBackground: some View {
        Circle()
            .fill(isCurrentExercise ? Color.blue : Color.gray.opacity(0.1))
            .overlay(
                Circle()
                    .stroke(isCurrentExercise ? Color.clear : Color.textSecondary.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isCurrentExercise ? Color.blue.opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrentExercise ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Exercise number and status indicator
                VStack(spacing: 4) {
                    Text("\(index + 1)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isCurrentExercise ? .white : .textPrimary)
                        .frame(width: 32, height: 32)
                        .background(exerciseNumberBackground)
                    
                    if isCurrentExercise {
                        Text("Current")
                            .font(.caption2)
                            .foregroundColor(.primaryBlue1)
                            .fontWeight(.medium)
                    } else if exercise.isCompleted {
                        Text("Done")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
                
                // Exercise info
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let targetMuscle = exercise.targetMuscle {
                        Text(targetMuscle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        Label("\(completedSets)/\(exercise.sets.count) sets", 
                              systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(exercise.isCompleted ? .green : .textSecondary)
                        
                        Label(exercise.restTime.formattedRestTime, 
                              systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Drag indicator
                VStack(spacing: 2) {
                    ForEach(0..<3) { _ in
                        Capsule()
                            .fill(Color.textSecondary.opacity(0.4))
                            .frame(width: 3, height: 3)
                    }
                }
            }
        }
        .padding(16)
        .background(rowBackground)
    }
}

struct ExerciseDropDelegate: DropDelegate {
    let destinationItem: LiveExercise
    @Binding var exercises: [LiveExercise]
    @Binding var draggedItem: LiveExercise?
    @Binding var currentIndex: Int
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem else { return }
        
        if draggedItem != destinationItem {
            let fromIndex = exercises.firstIndex(of: draggedItem)!
            let toIndex = exercises.firstIndex(of: destinationItem)!
            
            // Update current index if needed
            if currentIndex == fromIndex {
                currentIndex = toIndex
            } else if currentIndex > fromIndex && currentIndex <= toIndex {
                currentIndex -= 1
            } else if currentIndex < fromIndex && currentIndex >= toIndex {
                currentIndex += 1
            }
            
            withAnimation(.default) {
                exercises.move(fromOffsets: IndexSet([fromIndex]), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }
    }
}

struct NumberPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let increment: Int
    var formatter: ((Int) -> String)?
    
    @State private var selectedValue: Int
    
    init(title: String, value: Binding<Int>, range: ClosedRange<Int>, increment: Int = 1, formatter: ((Int) -> String)? = nil) {
        self.title = title
        self._value = value
        self.range = range
        self.increment = increment
        self.formatter = formatter
        self._selectedValue = State(initialValue: value.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Tap + or - to adjust, or swipe the picker")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Current value display
                VStack(spacing: 12) {
                    Text(formatter?(selectedValue) ?? "\(selectedValue)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryBlue1)
                        .contentTransition(.numericText())
                        .animation(.bouncy, value: selectedValue)
                    
                    // Quick adjustment buttons
                    HStack(spacing: 20) {
                        Button(action: decreaseValue) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(selectedValue > range.lowerBound ? .primaryBlue1 : .textSecondary.opacity(0.5))
                        }
                        .disabled(selectedValue <= range.lowerBound)
                        .scaleEffect(selectedValue > range.lowerBound ? 1.1 : 1.0)
                        .animation(.bouncy, value: selectedValue > range.lowerBound)
                        
                        Button(action: increaseValue) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(selectedValue < range.upperBound ? .primaryBlue1 : .textSecondary.opacity(0.5))
                        }
                        .disabled(selectedValue >= range.upperBound)
                        .scaleEffect(selectedValue < range.upperBound ? 1.1 : 1.0)
                        .animation(.bouncy, value: selectedValue < range.upperBound)
                    }
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue.opacity(0.1), lineWidth: 2)
                        )
                )
                
                // Picker wheel
                Picker(title, selection: $selectedValue) {
                    ForEach(Array(stride(from: range.lowerBound, through: range.upperBound, by: increment)), id: \.self) { number in
                        Text(formatter?(number) ?? "\(number)")
                            .tag(number)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 120)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.textSecondary.opacity(0.2))
                    .foregroundColor(.textPrimary)
                    .cornerRadius(12)
                    .fontWeight(.medium)
                    
                    Button("Done") {
                        value = selectedValue
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .background(Color.gray.opacity(0.1))
            .navigationBarHidden(true)
        }
    }
    
    private func increaseValue() {
        if selectedValue < range.upperBound {
            withAnimation(.bouncy) {
                selectedValue += increment
            }
        }
    }
    
    private func decreaseValue() {
        if selectedValue > range.lowerBound {
            withAnimation(.bouncy) {
                selectedValue -= increment
            }
        }
    }
}


// MARK: - Live Workout Exercise List
struct LiveWorkoutExerciseListView: View {
    let exercises: [LiveExercise]
    @Binding var currentIndex: Int
    let onReorder: (IndexSet, Int) -> Void
    let onDismiss: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isEditMode: Bool = false
    
    private var progressPercentage: CGFloat {
        let totalSets = exercises.reduce(0) { $0 + $1.sets.count }
        let completedSets = exercises.reduce(0) { $0 + $1.sets.filter { $0.completed }.count }
        
        guard totalSets > 0 else { return 0 }
        return CGFloat(completedSets) / CGFloat(totalSets)
    }
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        onReorder(source, destination)
        
        // Update current index if necessary
        if let sourceIndex = source.first {
            if sourceIndex == currentIndex {
                // The current exercise is being moved
                if destination > sourceIndex {
                    currentIndex = destination - 1
                } else {
                    currentIndex = destination
                }
            } else if sourceIndex < currentIndex && destination > currentIndex {
                // Exercise moved from before current to after current
                currentIndex -= 1
            } else if sourceIndex > currentIndex && destination <= currentIndex {
                // Exercise moved from after current to before current
                currentIndex += 1
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header section
                    headerSection
                    
                    // Exercise list
                    if isEditMode {
                        // Edit mode with reordering
                        List {
                            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                                LiveExerciseListCard(
                                    exercise: exercise,
                                    exerciseNumber: index + 1,
                                    isCurrentExercise: index == currentIndex,
                                    isEditMode: true,
                                    onTap: {
                                        // No navigation in edit mode
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .onMove(perform: moveExercises)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .environment(\.editMode, .constant(.active))
                    } else {
                        // Normal mode
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                                    LiveExerciseListCard(
                                        exercise: exercise,
                                        exerciseNumber: index + 1,
                                        isCurrentExercise: index == currentIndex,
                                        isEditMode: false,
                                        onTap: {
                                            currentIndex = index
                                            onDismiss()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 16)
                        }
                    }
                }
                .padding(16)
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Top bar
            HStack {
                
                Button(isEditMode ? "Done" : "Order") {
                    isEditMode.toggle()
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isEditMode ? .primaryGreen1 : .red)
                
                Spacer()
                
                Text("Workout Plan")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if !isEditMode {
                    Button("Done") {
                        onDismiss()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Progress indicator
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.circle.fill")
                    .font(.title)
                    .foregroundColor(.primaryGreen1)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(exercises.count) Exercises")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Exercise \(currentIndex + 1) of \(exercises.count)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(Color.primaryGreen1.opacity(0.3), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: progressPercentage)
                        .stroke(Color.primaryGreen1, lineWidth: 3)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryGreen1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Live Exercise Card
struct LiveExerciseListCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let exercise: LiveExercise
    let exerciseNumber: Int
    let isCurrentExercise: Bool
    let isEditMode: Bool
    let onTap: () -> Void
    
    private var completedSets: Int {
        exercise.sets.filter { $0.completed }.count
    }
    
    private var isExerciseCompleted: Bool {
        exercise.isCompleted
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Exercise number indicator
                exerciseNumberView
                    .frame(width: 50)
                
                // Exercise image
                exerciseImageView
                    .frame(width: 60)
                
                // Exercise info (flexible but with priority)
                exerciseInfoView
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Status indicator (fixed width)
                statusIndicatorView
                    .frame(width: 30)
            }
            .padding(20)
            .background(cardBackground)
            .cornerRadius(16)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
            .scaleEffect(isCurrentExercise ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrentExercise)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var exerciseNumberView: some View {
        VStack(spacing: 8) {
            Text("\(exerciseNumber)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(numberTextColor)
                .frame(width: 40, height: 40)
                .background(numberBackground)
                .cornerRadius(20)
            
            if isCurrentExercise {
                Text("Current")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.customBackgroundColor)
            } else if isExerciseCompleted {
                Text("Done")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
    }
    
    private var exerciseImageView: some View {
        DetailedExerciseImageView(
            imageUrl: exercise.imageUrl,
            exerciseName: exercise.name
        )
        .frame(width: 60, height: 60)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var exerciseInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            if let targetMuscle = exercise.targetMuscle {
                Text(targetMuscle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Sets progress
            HStack(spacing: 8) {
                Label("\(completedSets)/\(exercise.sets.count)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(isExerciseCompleted ? .green : .secondary)
                    .fixedSize()
                
                Label(exercise.restTime.formattedRestTime, systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize()
            }
            .fixedSize()
        }
    }
    
    private var statusIndicatorView: some View {
        VStack(spacing: 8) {
            if isCurrentExercise && !isEditMode {
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundColor(themeManager.customBackgroundColor)
            } else if isExerciseCompleted && !isEditMode {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(Color.primaryGreen1)
            } else if !isEditMode {
                Image(systemName: "circle")
                    .font(.title)
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
            // In edit mode, don't show any icon here - we'll use long press
        }
    }
    
    // MARK: - Computed Properties for Styling
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var backgroundColor: Color {
        if isEditMode {
            return Color.cardBackground.opacity(0.95)
        } else if isCurrentExercise {
            return themeManager.customBackgroundColor.opacity(0.1)
        } else if isExerciseCompleted {
            return Color.green.opacity(0.05)
        } else {
            return Color.cardBackground
        }
    }
    
    private var borderColor: Color {
        if isCurrentExercise {
            return themeManager.customBackgroundColor.opacity(0.3)
        } else if isExerciseCompleted {
            return Color.green.opacity(0.2)
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        isCurrentExercise ? 2 : 0
    }
    
    private var numberBackground: Color {
        if isCurrentExercise {
            return themeManager.customBackgroundColor
        } else if isExerciseCompleted {
            return Color.primaryGreen1
        } else {
            return Color.secondary.opacity(0.1)
        }
    }
    
    private var numberTextColor: Color {
        if isCurrentExercise || isExerciseCompleted {
            return .white
        } else {
            return .primary
        }
    }
    
    private var shadowColor: Color {
        if isCurrentExercise {
            return themeManager.customBackgroundColor.opacity(0.3)
        } else if isExerciseCompleted {
            return Color.green.opacity(0.2)
        } else {
            return Color.black.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        if isEditMode {
            return 6
        } else {
            return isCurrentExercise ? 8 : 4
        }
    }
    
    private var shadowOffset: CGFloat {
        if isEditMode {
            return 3
        } else {
            return isCurrentExercise ? 4 : 2
        }
    }
}

#Preview {
    LiveWorkoutView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager.shared)
}
