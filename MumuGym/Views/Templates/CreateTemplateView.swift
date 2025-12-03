import SwiftUI
import CoreData

struct CreateTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @State private var templateName = ""
    @State private var selectedGoal = "Massa"
    @State private var selectedExercises: [TemplateExerciseData] = []
    @State private var showingExercisePicker = false
    @State private var showingExerciseConfiguration = false
    @State private var editingIndex: Int?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @FetchRequest(
        entity: Exercise.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
    ) private var availableExercises: FetchedResults<Exercise>
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceBackground
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        templateInfoSection
                        exercisesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.textPrimary)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .foregroundColor(isValidTemplate ? Color.textPrimary : Color.textSecondary)
                    .fontWeight(.semibold)
                    .disabled(!isValidTemplate)
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(
                exercises: Array(availableExercises),
                onExerciseAdded: addExercise
            )
        }
        .sheet(isPresented: $showingExerciseConfiguration) {
            if let editingIndex = editingIndex {
                ExerciseConfigurationView(
                    exercise: selectedExercises[editingIndex].exercise,
                    existingData: selectedExercises[editingIndex]
                ) { exerciseData in
                    selectedExercises[editingIndex] = exerciseData
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var templateInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(Color.primaryBlue1)
                    .font(.title2)
                
                Text("Template Details")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Template Name")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField("Enter template name", text: $templateName)
                        .padding(12)
                        .background(Color.surfaceBackground)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Obiettivo Allenamento")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    goalSelector
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var exercisesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(Color.primaryBlue1)
                    .font(.title2)
                
                Text("Exercises")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Add Exercise") {
                    showingExercisePicker = true
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primaryGradient)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            if selectedExercises.isEmpty {
                emptyExercisesView
            } else {
                exercisesList
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var emptyExercisesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.primaryBlue1.opacity(0.6))
            
            Text("No exercises added")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Add exercises to create your workout template")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add First Exercise") {
                showingExercisePicker = true
            }
            .frame(width: 180, height: 44)
            .background(Color.buttonPrimary)
            .foregroundColor(.white)
            .cornerRadius(22)
            .fontWeight(.semibold)
            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var exercisesList: some View {
        LazyVStack(spacing: 12) {
            ForEach(selectedExercises.indices, id: \.self) { index in
                ExercisePreviewCard(
                    exerciseData: selectedExercises[index],
                    onEdit: {
                        editingIndex = index
                        showingExerciseConfiguration = true
                    },
                    onDelete: {
                        selectedExercises.remove(at: index)
                    }
                )
            }
            .onMove(perform: moveExercises)
        }
    }
    
    private var isValidTemplate: Bool {
        !templateName.isEmpty && !selectedExercises.isEmpty
    }
    
    private var goalSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(workoutGoals, id: \.self) { goal in
                    Button(goal) {
                        selectedGoal = goal
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(selectedGoal == goal ? AnyShapeStyle(Color.dynamicBackgroundGradient) : AnyShapeStyle(Color.surfaceBackground))
                    .foregroundColor(selectedGoal == goal ? .white : .primary)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private let workoutGoals = ["Massa", "Definizione", "Forza", "Resistenza", "Powerlifting", "Funzionale", "Riabilitazione", "Generale"]
    
    private func addExercise(_ exerciseData: TemplateExerciseData) {
        selectedExercises.append(exerciseData)
    }
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        selectedExercises.move(fromOffsets: source, toOffset: destination)
    }
    
    private func saveTemplate() {
        guard let user = authManager.currentUser else { return }
        
        let template = WorkoutTemplate(context: viewContext)
        template.name = templateName
        template.goal = selectedGoal
        template.user = user
        template.isDefault = false
        template.createdDate = Date()
        
        for (index, exerciseData) in selectedExercises.enumerated() {
            let templateExercise = WorkoutTemplateExercise(context: viewContext)
            templateExercise.order = Int16(index)
            templateExercise.sets = Int16(exerciseData.sets)
            templateExercise.reps = Int16(exerciseData.reps)
            templateExercise.weight = exerciseData.weight
            templateExercise.restTime = Int32(exerciseData.restTime)
            templateExercise.notes = exerciseData.notes
            templateExercise.exercise = exerciseData.exercise
            templateExercise.template = template
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save template: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct TemplateExerciseData: Identifiable {
    let id = UUID()
    let exercise: Exercise
    var sets: Int
    var reps: Int
    var weight: Double
    var restTime: Int
    var notes: String
}

struct ExercisePreviewCard: View {
    let exerciseData: TemplateExerciseData
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise image
            ExerciseImageView(
                imageUrl: exerciseData.exercise.imageUrl,
                exerciseName: exerciseData.exercise.name ?? "Unknown",
                size: CGSize(width: 60, height: 60)
            )
            
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseData.exercise.name ?? "Unknown")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(exerciseData.exercise.targetMuscle ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Quick summary
                HStack(spacing: 8) {
                    parameterChip(icon: "repeat", value: "\(exerciseData.sets)")
                    parameterChip(icon: "arrow.clockwise", value: "\(exerciseData.reps)")
                    
                    if exerciseData.weight > 0 {
                        parameterChip(icon: "scalemass", value: String(format: "%.1f", exerciseData.weight) + "kg")
                    }
                    
                    parameterChip(icon: "clock", value: exerciseData.restTime.formattedRestTime)
                }
                
                if !exerciseData.notes.isEmpty {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundColor(.primaryOrange1)
                        
                        Text(exerciseData.notes)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 6) {
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func parameterChip(icon: String, value: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.primaryOrange1)
            
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.primaryOrange1.opacity(0.1))
        .cornerRadius(6)
    }
}

struct TemplateExerciseRow: View {
    @Binding var exerciseData: TemplateExerciseData
    let onDelete: () -> Void
    
    @State private var showingNotesField = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with exercise info and delete button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseData.exercise.name ?? "Unknown")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(exerciseData.exercise.targetMuscle ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Notes button
                    Button(action: { showingNotesField.toggle() }) {
                        Image(systemName: showingNotesField ? "note.text.badge.plus" : "note.text")
                            .font(.title3)
                            .foregroundColor(exerciseData.notes.isEmpty ? .secondary : .primaryOrange1)
                    }
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.deleteButtonColor)
                    }
                }
            }
            
            // Parameters section with improved stepper design
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Sets
                    parameterCard(
                        title: "Sets",
                        value: exerciseData.sets,
                        range: 1...10,
                        binding: $exerciseData.sets
                    )
                    
                    // Reps
                    parameterCard(
                        title: "Reps",
                        value: exerciseData.reps,
                        range: 1...100,
                        binding: $exerciseData.reps
                    )
                }
                
                HStack(spacing: 12) {
                    // Weight
                    weightCard()
                    
                    // Rest time
                    restTimeCard()
                }
            }
            
            // Notes field (expandable)
            if showingNotesField {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note esercizio")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("Aggiungi note per questo esercizio...", text: $exerciseData.notes, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(12)
                        .background(Color.surfaceBackground)
                        .cornerRadius(12)
                        .font(.subheadline)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .animation(.easeInOut(duration: 0.3), value: showingNotesField)
    }
    
    @ViewBuilder
    private func parameterCard(title: String, value: Int, range: ClosedRange<Int>, binding: Binding<Int>) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Button(action: {
                    if binding.wrappedValue > range.lowerBound {
                        binding.wrappedValue -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(binding.wrappedValue > range.lowerBound ? .primaryOrange1 : .secondary.opacity(0.5))
                }
                .disabled(binding.wrappedValue <= range.lowerBound)
                
                Text("\(binding.wrappedValue)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(minWidth: 30)
                
                Button(action: {
                    if binding.wrappedValue < range.upperBound {
                        binding.wrappedValue += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(binding.wrappedValue < range.upperBound ? .primaryOrange1 : .secondary.opacity(0.5))
                }
                .disabled(binding.wrappedValue >= range.upperBound)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.surfaceBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func weightCard() -> some View {
        VStack(spacing: 8) {
            Text("Peso (kg)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Button(action: {
                    if exerciseData.weight >= 2.5 {
                        exerciseData.weight -= 2.5
                    } else if exerciseData.weight > 0 {
                        exerciseData.weight = 0
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(exerciseData.weight > 0 ? .primaryOrange1 : .secondary.opacity(0.5))
                }
                .disabled(exerciseData.weight <= 0)
                
                TextField("0", value: $exerciseData.weight, format: .number)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .frame(minWidth: 40)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Button(action: {
                    exerciseData.weight += 2.5
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.primaryOrange1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.surfaceBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func restTimeCard() -> some View {
        VStack(spacing: 8) {
            Text("Riposo (sec)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Button(action: {
                    if exerciseData.restTime >= 15 {
                        exerciseData.restTime -= 15
                    } else if exerciseData.restTime > 0 {
                        exerciseData.restTime = 0
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(exerciseData.restTime > 0 ? .primaryOrange1 : .secondary.opacity(0.5))
                }
                .disabled(exerciseData.restTime <= 0)
                
                TextField("60", value: $exerciseData.restTime, format: .number)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 40)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Button(action: {
                    exerciseData.restTime += 15
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.primaryOrange1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.surfaceBackground)
        .cornerRadius(12)
    }
}

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let exercises: [Exercise]
    let onExerciseAdded: (TemplateExerciseData) -> Void
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup = "All"
    @State private var showingConfiguration = false
    @State private var selectedExercise: Exercise?
    
    private let muscleGroups = ["All", "Petto", "Schiena", "Gambe", "Braccia", "Spalle", "Core", "Full Body", "Cardio"]
    
    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty || exercise.name?.localizedCaseInsensitiveContains(searchText) == true
            let matchesMuscle = selectedMuscleGroup == "All" || exercise.targetMuscle == selectedMuscleGroup
            return matchesSearch && matchesMuscle
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                filterSection
                exerciseList
            }
            .navigationTitle("Select Exercise")
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
    
    private var filterSection: some View {
        VStack {
            SearchBar(text: $searchText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(muscleGroups, id: \.self) { group in
                        Button(group) {
                            selectedMuscleGroup = group
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedMuscleGroup == group ? AnyShapeStyle(Color.dynamicBackgroundGradient) : AnyShapeStyle(Color(.systemGray5)))
                        .foregroundColor(selectedMuscleGroup == group ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 10)
    }
    
    private var exerciseList: some View {
        List {
            if filteredExercises.isEmpty && searchText.isEmpty && selectedMuscleGroup == "All" {
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No exercises found")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("There might be an issue loading exercises. Please restart the app.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry Loading") {
                        PersistenceController.shared.ensureExercisesSeeded()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(filteredExercises, id: \.objectID) { exercise in
                    ExercisePickerRow(exercise: exercise) {
                        selectedExercise = exercise
                        showingConfiguration = true
                    }
                }
            }
        }
        .sheet(item: Binding<Exercise?>(
            get: { showingConfiguration ? selectedExercise : nil },
            set: { _ in showingConfiguration = false }
        )) { exercise in
            ExerciseConfigurationView(exercise: exercise) { exerciseData in
                onExerciseAdded(exerciseData)
                showingConfiguration = false
            }
        }
    }
}

struct ExercisePickerRow: View {
    let exercise: Exercise
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ExerciseImageView(
                    imageUrl: exercise.imageUrl,
                    exerciseName: exercise.name ?? "Unknown",
                    size: CGSize(width: 50, height: 50)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(exercise.targetMuscle ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let instructions = exercise.instructions, !instructions.isEmpty {
                        Text(instructions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(exercise.type?.capitalized ?? "")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primaryOrange1.opacity(0.15))
                        .foregroundColor(Color.primaryOrange1)
                        .cornerRadius(8)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.shadowMedium, radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search exercises...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 20)
    }
}

#Preview {
    CreateTemplateView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager.shared)
}
