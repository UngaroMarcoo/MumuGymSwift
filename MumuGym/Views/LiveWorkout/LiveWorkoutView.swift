import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct LiveWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    let template: WorkoutTemplate?
    
    @StateObject private var workoutSession = WorkoutSession()
    @State private var showingEndWorkoutAlert = false
    @State private var showingAddExercise = false
    @State private var currentExerciseIndex = 0
    @State private var showingExerciseList = false
    @State private var selectedTemplate: WorkoutTemplate?
    
    @FetchRequest(
        entity: WorkoutTemplate.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutTemplate.createdDate, ascending: false)]
    ) private var templates: FetchedResults<WorkoutTemplate>
    
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
            .background(Color.warningGradient)
            .navigationBarBackButtonHidden(workoutSession.isActive)
            .navigationBarHidden(!workoutSession.isActive)
            .toolbar {
                if workoutSession.isActive {
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
        .sheet(isPresented: $showingExerciseList) {
            NavigationView {
                List {
                    ForEach(workoutSession.exercises.indices, id: \.self) { index in
                        Button(action: {
                            currentExerciseIndex = index
                            showingExerciseList = false
                        }) {
                            HStack {
                                Text("\(index + 1)")
                                    .fontWeight(.bold)
                                    .frame(width: 30, height: 30)
                                    .background(currentExerciseIndex == index ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(currentExerciseIndex == index ? .white : .primary)
                                    .cornerRadius(15)
                                
                                Text(workoutSession.exercises[index].name)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if currentExerciseIndex == index {
                                    Text("Current")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .onMove { from, to in
                        workoutSession.exercises.move(fromOffsets: from, toOffset: to)
                    }
                }
                .navigationTitle("Exercise Order")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingExerciseList = false
                        }
                    }
                }
            }
        }
        .onAppear {
            if let template = template {
                setupWorkoutFromTemplate(template)
            }
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
        ZStack(alignment: .topLeading) {
            // Main content
            VStack(spacing: 0) {
                if !workoutSession.exercises.isEmpty {
                    currentExerciseView
                        .padding(.top, 100) // Space for sticky header
                } else {
                    emptyWorkoutView
                        .padding(.top, 100) // Space for sticky header
                }
                
                workoutControls
            }
            
            // Sticky header in top-left
            stickyWorkoutHeader
        }
    }
    
    private var stickyWorkoutHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Timer
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .foregroundColor(Color.primaryGreen1)
                Text("\(workoutSession.formattedDuration)")
                    .fontWeight(.bold)
                    .font(.title3)
            }
            .foregroundColor(.textPrimary)
            
            // Exercise list button
            Button(action: { showingExerciseList = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(Color.primaryGreen1)
                    Text("\(currentExerciseIndex + 1)/\(workoutSession.exercises.count)")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.cardBackground)
                .cornerRadius(12)
            }
            .disabled(workoutSession.exercises.isEmpty)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 4)
        )
        .padding(.leading, 20)
        .padding(.top, 10) // Align with toolbar
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
    
    @State private var showingRepsPicker = false
    @State private var showingWeightPicker = false
    @FocusState private var isRepsFieldFocused: Bool
    @FocusState private var isWeightFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Set number with improved styling
                Text("\(setNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(width: 40, height: 40)
                    .background(setNumberBackground)
                    .foregroundColor(set.completed ? .white : Color.blue)
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
                        .fill(set.completed ? Color.green : (canComplete ? Color.blue : Color.textSecondary.opacity(0.3)))
                )
                .foregroundColor(.white)
                .shadow(color: set.completed ? Color.green.opacity(0.3) : (canComplete ? Color.blue.opacity(0.3) : Color.clear), radius: 4, x: 0, y: 2)
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
            .fill(set.completed ? Color.green : Color.blue.opacity(0.1))
            .overlay(
                Circle()
                    .stroke(set.completed ? Color.clear : Color.blue.opacity(0.3), lineWidth: 2)
            )
    }
    
    private var setRowBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
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

#Preview {
    LiveWorkoutView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager.shared)
}
