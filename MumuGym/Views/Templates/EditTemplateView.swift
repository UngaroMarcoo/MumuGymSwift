import SwiftUI
import CoreData

struct TemplateEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let template: WorkoutTemplate
    
    @State private var templateName: String = ""
    @State private var templateExercises: [WorkoutTemplateExercise] = []
    @State private var showingAddExercise = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
            AddExerciseToTemplateView(
                exercises: Array(allExercises),
                onExerciseAdded: { exercise, sets, reps, weight, restTime in
                    let templateExercise = WorkoutTemplateExercise(context: viewContext)
                    templateExercise.exercise = exercise
                    templateExercise.sets = Int16(sets)
                    templateExercise.reps = Int16(reps)
                    templateExercise.weight = weight
                    templateExercise.restTime = Int32(restTime)
                    templateExercise.order = Int16(templateExercises.count)
                    templateExercises.append(templateExercise)
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
            
            if templateExercises.isEmpty {
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
                    ForEach(templateExercises.indices, id: \.self) { index in
                        let exercise = templateExercises[index]
                        ModernExerciseRowView(
                            exercise: exercise,
                            onDelete: {
                                templateExercises.remove(at: index)
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
            templateExercises = exercises.sorted { $0.order < $1.order }
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
        
        // Add updated exercises
        for (index, templateExercise) in templateExercises.enumerated() {
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

struct ModernExerciseRowView: View {
    let exercise: WorkoutTemplateExercise
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
                
                HStack(spacing: 12) {
                    InfoTag(title: "Sets", value: "\(exercise.sets)")
                    InfoTag(title: "Reps", value: "\(exercise.reps)")
                    InfoTag(title: "Weight", value: "\(exercise.weight, default: "%.1f") kg")
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.deleteButtonGradient)
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
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.surfaceBackground)
        )
    }
}

// Keep the old ExerciseRowView for compatibility
struct ExerciseRowView: View {
    let exercise: WorkoutTemplateExercise
    let onDelete: () -> Void
    
    var body: some View {
        ModernExerciseRowView(exercise: exercise, onDelete: onDelete)
    }
}

struct AddExerciseToTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    
    let exercises: [Exercise]
    let onExerciseAdded: (Exercise, Int, Int, Double, Int) -> Void
    
    @State private var selectedExercise: Exercise?
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight = 0.0
    @State private var restTime = 60
    @State private var searchText = ""
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { exercise in
                exercise.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack {
                    if selectedExercise == nil {
                        exerciseSelectionView
                    } else {
                        exerciseConfigurationView
                    }
                }
            }
            .navigationTitle(selectedExercise == nil ? "Select Exercise" : "Configure Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if selectedExercise != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add") {
                            if let exercise = selectedExercise {
                                onExerciseAdded(exercise, sets, reps, weight, restTime)
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var exerciseSelectionView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredExercises, id: \.objectID) { exercise in
                    Button(action: { selectedExercise = exercise }) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name ?? "Unknown")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                
                                Text(exercise.targetMuscle ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cardBackground)
                                .shadow(color: Color.shadowMedium, radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .searchable(text: $searchText, prompt: "Search exercises")
    }
    
    private var exerciseConfigurationView: some View {
        ScrollView {
            VStack(spacing: 25) {
                selectedExerciseCard
                configurationSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    private var selectedExerciseCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.successGradient)
                
                Text("Selected Exercise")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Change") {
                    selectedExercise = nil
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.editButtonGradient)
                .cornerRadius(20)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedExercise?.name ?? "Unknown")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text(selectedExercise?.targetMuscle ?? "")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
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
    
    private var configurationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundStyle(Color.warningGradient)
                
                Text("Exercise Configuration")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 20) {
                ConfigurationRow(title: "Sets", value: $sets, range: 1...10)
                ConfigurationRow(title: "Reps", value: $reps, range: 1...50)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (kg)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    TextField("0.0", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .background(Color.surfaceBackground)
                        .cornerRadius(12)
                        .shadow(color: Color.shadowLight, radius: 2, x: 0, y: 1)
                }
                
                ConfigurationRow(title: "Rest Time (sec)", value: $restTime, range: 30...300, step: 15)
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
}

struct ConfigurationRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            HStack {
                Text("\(value)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .frame(minWidth: 40)
                
                Stepper("", value: $value, in: range, step: step)
                    .labelsHidden()
            }
            .padding(12)
            .background(Color.surfaceBackground)
            .cornerRadius(12)
            .shadow(color: Color.shadowLight, radius: 2, x: 0, y: 1)
        }
    }
}

struct TemplateEditView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let template = WorkoutTemplate(context: context)
        template.name = "Sample Template"
        
        return TemplateEditView(template: template)
            .environment(\.managedObjectContext, context)
    }
}
