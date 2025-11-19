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
            VStack(spacing: 0) {
                Form {
                    Section("Template Name") {
                        TextField("Enter template name", text: $templateName)
                    }
                    
                    Section("Exercises") {
                        if templateExercises.isEmpty {
                            Text("No exercises added yet")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        } else {
                            ForEach(templateExercises.indices, id: \.self) { index in
                                let exercise = templateExercises[index]
                                ExerciseRowView(
                                    exercise: exercise,
                                    onDelete: {
                                        templateExercises.remove(at: index)
                                    }
                                )
                            }
                        }
                        
                        Button("Add Exercise") {
                            showingAddExercise = true
                        }
                        .foregroundColor(.blue)
                    }
                }
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
                        saveTemplate()
                    }
                    .disabled(templateName.isEmpty)
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

struct ExerciseRowView: View {
    let exercise: WorkoutTemplateExercise
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exercise?.name ?? "Unknown")
                    .font(.headline)
                
                HStack {
                    Text("\(exercise.sets) sets")
                    Text("•")
                    Text("\(exercise.reps) reps")
                    Text("•")
                    Text("\(exercise.weight, default: "%.1f") kg")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
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
            VStack {
                if selectedExercise == nil {
                    // Exercise selection
                    List {
                        ForEach(filteredExercises, id: \.objectID) { exercise in
                            Button(action: { selectedExercise = exercise }) {
                                HStack {
                                    Text(exercise.name ?? "Unknown")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(exercise.targetMuscle ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search exercises")
                } else {
                    // Exercise configuration
                    Form {
                        Section("Exercise") {
                            HStack {
                                Text("Selected")
                                Spacer()
                                Text(selectedExercise?.name ?? "Unknown")
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Change Exercise") {
                                selectedExercise = nil
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Section("Configuration") {
                            HStack {
                                Text("Sets")
                                Spacer()
                                Stepper("\(sets)", value: $sets, in: 1...10)
                            }
                            
                            HStack {
                                Text("Reps")
                                Spacer()
                                Stepper("\(reps)", value: $reps, in: 1...50)
                            }
                            
                            HStack {
                                Text("Weight (kg)")
                                Spacer()
                                TextField("0.0", value: $weight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("Rest Time (sec)")
                                Spacer()
                                Stepper("\(restTime)", value: $restTime, in: 30...300, step: 15)
                            }
                        }
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