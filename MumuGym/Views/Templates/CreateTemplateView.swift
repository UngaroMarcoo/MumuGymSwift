import SwiftUI
import CoreData

struct CreateTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @State private var templateName = ""
    @State private var selectedExercises: [TemplateExerciseData] = []
    @State private var showingExercisePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @FetchRequest(
        entity: Exercise.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
    ) private var availableExercises: FetchedResults<Exercise>
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryGradient
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
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .foregroundColor(isValidTemplate ? .white : .white.opacity(0.5))
                    .fontWeight(.semibold)
                    .disabled(!isValidTemplate)
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(
                exercises: Array(availableExercises),
                onExerciseSelected: addExercise
            )
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
                    .foregroundColor(Color.primaryOrange1)
                    .font(.title2)
                
                Text("Template Details")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Template Name")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                TextField("Enter template name", text: $templateName)
                    .padding(12)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var exercisesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(Color.primaryOrange2)
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
                .background(Color.buttonPrimary)
                .cornerRadius(20)
                .shadow(color: Color.primaryOrange1.opacity(0.3), radius: 4, x: 0, y: 2)
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
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var emptyExercisesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.primaryOrange1.opacity(0.6))
            
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
            .shadow(color: Color.primaryOrange1.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var exercisesList: some View {
        LazyVStack(spacing: 12) {
            ForEach(selectedExercises.indices, id: \.self) { index in
                TemplateExerciseRow(
                    exerciseData: $selectedExercises[index],
                    onDelete: {
                        selectedExercises.remove(at: index)
                    }
                )
            }
        }
    }
    
    private var isValidTemplate: Bool {
        !templateName.isEmpty && !selectedExercises.isEmpty
    }
    
    private func addExercise(_ exercise: Exercise) {
        let exerciseData = TemplateExerciseData(
            exercise: exercise,
            sets: 3,
            reps: 10,
            weight: 0,
            restTime: 60
        )
        selectedExercises.append(exerciseData)
    }
    
    private func saveTemplate() {
        guard let user = authManager.currentUser else { return }
        
        let template = WorkoutTemplate(context: viewContext)
        template.name = templateName
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

struct TemplateExerciseData {
    let exercise: Exercise
    var sets: Int
    var reps: Int
    var weight: Double
    var restTime: Int
}

struct TemplateExerciseRow: View {
    @Binding var exerciseData: TemplateExerciseData
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseData.exercise.name ?? "Unknown")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(exerciseData.exercise.targetMuscle ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.deleteButtonColor)
                }
            }
            
            HStack(spacing: 15) {
                VStack {
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Stepper("\(exerciseData.sets)", value: $exerciseData.sets, in: 1...10)
                        .labelsHidden()
                }
                
                VStack {
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Stepper("\(exerciseData.reps)", value: $exerciseData.reps, in: 1...50)
                        .labelsHidden()
                }
                
                VStack {
                    Text("Weight (kg)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("0", value: $exerciseData.weight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
                
                VStack {
                    Text("Rest (sec)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("60", value: $exerciseData.restTime, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
    }
}

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let exercises: [Exercise]
    let onExerciseSelected: (Exercise) -> Void
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup = "All"
    
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
                        .background(selectedMuscleGroup == group ? Color.primaryOrange1 : Color(.systemGray5))
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
            ForEach(filteredExercises, id: \.objectID) { exercise in
                ExercisePickerRow(exercise: exercise) {
                    onExerciseSelected(exercise)
                    dismiss()
                }
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
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
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
