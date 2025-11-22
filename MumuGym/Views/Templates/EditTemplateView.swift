import SwiftUI
import CoreData

struct TemplateEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let template: WorkoutTemplate
    
    @State private var templateName: String = ""
    @State private var stagedExercises: [TemplateExerciseData] = []
    @State private var showingAddExercise = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var exerciseToEdit: TemplateExerciseData?
    @State private var editingIndex: Int?
    
    @FetchRequest(
        entity: Exercise.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
    ) private var allExercises: FetchedResults<Exercise>
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        templateNameSection
                        exercisesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryRed)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(templateName.isEmpty)
                    .foregroundColor(Color.primaryBlue1)
                }
            }
        }
        .onAppear {
            loadTemplateData()
        }
        .sheet(isPresented: $showingAddExercise) {
            ExercisePickerView(
                exercises: Array(allExercises),
                onExerciseAdded: { exerciseData in
                    stagedExercises.append(exerciseData)
                }
            )
        }
        .sheet(item: $exerciseToEdit) { exerciseToEdit in
            ExerciseConfigurationView(
                exercise: exerciseToEdit.exercise,
                existingData: exerciseToEdit,
                onSave: { updatedData in
                    if let index = editingIndex {
                        stagedExercises[index] = updatedData
                    }
                }
            )
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var templateNameSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Template Name")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            TextField("Enter template name", text: $templateName)
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .shadow(color: Color.shadowMedium, radius: 4, x: 0, y: 2)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowStrong, radius: 10, x: 0, y: 5)
        )
    }
    
    private var exercisesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.title2)
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Exercises")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Add Exercise") {
                    showingAddExercise = true
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.buttonPrimary)
                .cornerRadius(20)
                .shadow(color: Color.shadowMedium, radius: 4, x: 0, y: 2)
            }
            
            if stagedExercises.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.primaryGradient.opacity(0.6))
                    
                    Text("No exercises added yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Add exercises to customize your template")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(stagedExercises.indices, id: \.self) { index in
                        let exerciseData = stagedExercises[index]
                        TemplateExerciseDataRowView(
                            exerciseData: exerciseData,
                            onEdit: {
                                editingIndex = index
                                exerciseToEdit = exerciseData
                            },
                            onDelete: {
                                stagedExercises.remove(at: index)
                            }
                        )
                    }
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowStrong, radius: 10, x: 0, y: 5)
        )
    }
    
    private func loadTemplateData() {
        templateName = template.name ?? ""
        if let exercises = template.exercises?.allObjects as? [WorkoutTemplateExercise] {
            stagedExercises = exercises.sorted { $0.order < $1.order }.map { templateExercise in
                TemplateExerciseData(
                    exercise: templateExercise.exercise!,
                    sets: Int(templateExercise.sets),
                    reps: Int(templateExercise.reps),
                    weight: templateExercise.weight,
                    restTime: Int(templateExercise.restTime),
                    notes: templateExercise.notes ?? ""
                )
            }
        }
    }
    
    private func saveTemplate() {
        guard !templateName.isEmpty else {
            alertMessage = "Please enter a template name"
            showingAlert = true
            return
        }
        
        template.name = templateName
        
        // Remove existing exercises
        if let existingExercises = template.exercises?.allObjects as? [WorkoutTemplateExercise] {
            for exercise in existingExercises {
                viewContext.delete(exercise)
            }
        }
        
        // Add staged exercises as new Core Data objects
        for (index, exerciseData) in stagedExercises.enumerated() {
            let templateExercise = WorkoutTemplateExercise(context: viewContext)
            templateExercise.exercise = exerciseData.exercise
            templateExercise.sets = Int16(exerciseData.sets)
            templateExercise.reps = Int16(exerciseData.reps)
            templateExercise.weight = exerciseData.weight
            templateExercise.restTime = Int32(exerciseData.restTime)
            templateExercise.notes = exerciseData.notes.isEmpty ? nil : exerciseData.notes
            templateExercise.template = template
            templateExercise.order = Int16(index)
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

struct TemplateExerciseDataRowView: View {
    let exerciseData: TemplateExerciseData
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ExerciseImageView(
                imageUrl: exerciseData.exercise.imageUrl,
                exerciseName: exerciseData.exercise.name ?? "Unknown",
                size: CGSize(width: 35, height: 35)
            )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(exerciseData.exercise.name ?? "Unknown")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(exerciseData.exercise.targetMuscle ?? "")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        InfoTag(title: "Sets", value: "\(exerciseData.sets)")
                        InfoTag(title: "Reps", value: "\(exerciseData.reps)")
                    }
                    HStack(spacing: 8) {
                        InfoTag(title: "Weight", value: String(format: "%.1f kg", exerciseData.weight))
                        InfoTag(title: "Rest", value: exerciseData.restTime.formattedRestTime)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.editButtonGradient)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.deleteButtonGradient)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 4, x: 0, y: 2)
        )
    }
}

struct ModernExerciseRowView: View {
    let exercise: WorkoutTemplateExercise
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.exercise?.name ?? "Unknown")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(exercise.exercise?.targetMuscle ?? "")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        InfoTag(title: "Sets", value: "\(exercise.sets)")
                        InfoTag(title: "Reps", value: "\(exercise.reps)")
                    }
                    HStack(spacing: 8) {
                        InfoTag(title: "Weight", value: "\(exercise.weight, default: "%.1f") kg")
                        InfoTag(title: "Rest", value: Int(exercise.restTime).formattedRestTime)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.editButtonGradient)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.deleteButtonGradient)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 4, x: 0, y: 2)
        )
    }
}

struct InfoTag: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.surfaceBackground)
                .stroke(Color.textSecondary.opacity(0.1), lineWidth: 1)
        )
    }
}

// Keep the old ExerciseRowView for compatibility
struct ExerciseRowView: View {
    let exercise: WorkoutTemplateExercise
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ModernExerciseRowView(exercise: exercise, onEdit: onEdit, onDelete: onDelete)
    }
}

