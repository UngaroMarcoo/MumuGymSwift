import SwiftUI
import CoreData

struct TemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    let template: WorkoutTemplate
    
    @State private var showingDeleteAlert = false
    @State private var showingEditTemplate = false
    @State private var isStartingWorkout = false
    
    private var templateExercises: [WorkoutTemplateExercise] {
        let exercisesSet = template.exercises as? Set<WorkoutTemplateExercise> ?? []
        return exercisesSet.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    headerSection
                    exercisesSection
                    actionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle(template.name ?? "Template")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Template") {
                            showingEditTemplate = true
                        }
                        
                        if !template.isDefault {
                            Divider()
                            Button("Delete", role: .destructive) {
                                showingDeleteAlert = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .alert("Delete Template", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTemplate()
            }
        } message: {
            Text("Are you sure you want to delete this template? This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditTemplate) {
            EditTemplateView(template: template)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(template.name ?? "Unknown")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if template.isDefault {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("\(templateExercises.count) exercises")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                InfoCard(title: "Exercises", value: "\(templateExercises.count)", icon: "dumbbell")
                InfoCard(title: "Est. Time", value: estimatedTime, icon: "clock")
                InfoCard(title: "Difficulty", value: difficulty, icon: "flame")
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var exercisesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Exercises")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(templateExercises, id: \.objectID) { templateExercise in
                    TemplateExerciseDetailCard(templateExercise: templateExercise)
                }
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            NavigationLink(destination: LiveWorkoutView(template: template)) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Workout")
                        .fontWeight(.semibold)
                    
                    if isStartingWorkout {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isStartingWorkout)
            
            Button("Edit Template") {
                showingEditTemplate = true
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.vertical, 20)
    }
    
    private var estimatedTime: String {
        let totalRestTime = templateExercises.reduce(0) { sum, exercise in
            sum + Int(exercise.sets) * Int(exercise.restTime)
        }
        let workTime = templateExercises.count * 5 * 60 // 5 minutes per exercise
        let totalMinutes = (totalRestTime + workTime) / 60
        return "\(totalMinutes) min"
    }
    
    private var difficulty: String {
        let avgSets = templateExercises.reduce(0) { $0 + Int($1.sets) } / max(templateExercises.count, 1)
        switch avgSets {
        case 1...2: return "Easy"
        case 3...4: return "Medium"
        default: return "Hard"
        }
    }
    
    private func deleteTemplate() {
        viewContext.delete(template)
        try? viewContext.save()
        dismiss()
    }
}

struct TemplateExerciseDetailCard: View {
    let templateExercise: WorkoutTemplateExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(templateExercise.exercise?.name ?? "Unknown")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(templateExercise.exercise?.targetMuscle ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("#\(templateExercise.order + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            HStack(spacing: 20) {
                ExerciseDetailItem(label: "Sets", value: "\(templateExercise.sets)")
                ExerciseDetailItem(label: "Reps", value: "\(templateExercise.reps)")
                
                if templateExercise.weight > 0 {
                    ExerciseDetailItem(label: "Weight", value: "\(templateExercise.weight, default: "%.1f") kg")
                }
                
                ExerciseDetailItem(label: "Rest", value: "\(templateExercise.restTime) sec")
            }
            
            if let instructions = templateExercise.exercise?.instructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ExerciseDetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct EditTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    let template: WorkoutTemplate
    
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
            ScrollView {
                VStack(spacing: 25) {
                    templateInfoSection
                    exercisesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValidTemplate)
                }
            }
        }
        .onAppear {
            loadTemplateData()
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
                Text("Template Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Template Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter template name", text: $templateName)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var exercisesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Exercises")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Add Exercise") {
                    showingExercisePicker = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if selectedExercises.isEmpty {
                emptyExercisesView
            } else {
                exercisesList
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var emptyExercisesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No exercises added")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Add exercises to create your workout template")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add First Exercise") {
                showingExercisePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
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
    
    private func loadTemplateData() {
        templateName = template.name ?? ""
        
        let templateExercises = (template.exercises as? Set<WorkoutTemplateExercise> ?? [])
            .sorted { $0.order < $1.order }
        
        selectedExercises = templateExercises.compactMap { templateEx in
            guard let exercise = templateEx.exercise else { return nil }
            return TemplateExerciseData(
                exercise: exercise,
                sets: Int(templateEx.sets),
                reps: Int(templateEx.reps),
                weight: templateEx.weight,
                restTime: Int(templateEx.restTime)
            )
        }
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
    
    private func saveChanges() {
        // Update template properties
        template.name = templateName
        
        // Clear existing exercises
        if let existingExercises = template.exercises as? Set<WorkoutTemplateExercise> {
            for exercise in existingExercises {
                viewContext.delete(exercise)
            }
        }
        
        // Add updated exercises
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
            alertMessage = "Failed to save changes: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let template = WorkoutTemplate(context: context)
    template.name = "Sample Workout"
    template.isDefault = false
    template.createdDate = Date()
    
    return TemplateDetailView(template: template)
        .environment(\.managedObjectContext, context)
        .environmentObject(AuthenticationManager.shared)
}