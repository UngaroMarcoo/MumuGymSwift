import SwiftUI
import CoreData

struct ExerciseConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let exercise: Exercise
    let existingData: TemplateExerciseData?
    let onSave: (TemplateExerciseData) -> Void
    
    @State private var sets: Int
    @State private var reps: Int
    @State private var weight: Double
    @State private var restTime: Int
    @State private var notes: String
    
    init(exercise: Exercise, existingData: TemplateExerciseData? = nil, onSave: @escaping (TemplateExerciseData) -> Void) {
        self.exercise = exercise
        self.existingData = existingData
        self.onSave = onSave
        
        // Initialize with existing data or defaults
        if let existing = existingData {
            _sets = State(initialValue: existing.sets)
            _reps = State(initialValue: existing.reps)
            _weight = State(initialValue: existing.weight)
            _restTime = State(initialValue: existing.restTime)
            _notes = State(initialValue: existing.notes)
        } else {
            _sets = State(initialValue: 3)
            _reps = State(initialValue: 10)
            _weight = State(initialValue: 0.0)
            _restTime = State(initialValue: 60)
            _notes = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.warningGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        exerciseInfoSection
                        configurationSection
                        notesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Configure Exercise")
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
                    Button(existingData != nil ? "Update" : "Add Exercise") {
                        let exerciseData = TemplateExerciseData(
                            exercise: exercise,
                            sets: sets,
                            reps: reps,
                            weight: weight,
                            restTime: restTime,
                            notes: notes
                        )
                        onSave(exerciseData)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var exerciseInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                ExerciseImageView(
                    imageUrl: exercise.imageUrl,
                    exerciseName: exercise.name ?? "Unknown",
                    size: CGSize(width: 80, height: 80)
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name ?? "Unknown")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Image(systemName: "target")
                            .font(.caption)
                            .foregroundColor(.primaryOrange1)
                        
                        Text(exercise.targetMuscle ?? "")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    if let type = exercise.type {
                        HStack {
                            Image(systemName: "tag.fill")
                                .font(.caption)
                                .foregroundColor(.primaryOrange2)
                            
                            Text(type.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryOrange2)
                        }
                    }
                }
                
                Spacer()
            }
            
            if let instructions = exercise.instructions, !instructions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Text("Exercise Instructions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    Text(instructions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var configurationSection: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(Color.primaryOrange1)
                    .font(.title2)
                
                Text("Exercise Parameters")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    parameterCard(
                        title: "Sets",
                        value: sets,
                        range: 1...15,
                        binding: $sets,
                        icon: "repeat"
                    )
                    
                    parameterCard(
                        title: "Reps",
                        value: reps,
                        range: 1...100,
                        binding: $reps,
                        icon: "arrow.clockwise"
                    )
                }
                
                HStack(spacing: 16) {
                    weightCard()
                    restTimeCard()
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var notesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(Color.primaryOrange2)
                    .font(.title2)
                
                Text("Exercise Notes")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Add personal notes for this exercise (optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("e.g., Focus on form, increase weight next time, etc...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(16)
                    .background(Color.surfaceBackground)
                    .cornerRadius(12)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    @ViewBuilder
    private func parameterCard(title: String, value: Int, range: ClosedRange<Int>, binding: Binding<Int>, icon: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.primaryOrange1)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    if binding.wrappedValue > range.lowerBound {
                        binding.wrappedValue -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(binding.wrappedValue > range.lowerBound ? .primaryOrange1 : .secondary.opacity(0.5))
                }
                .disabled(binding.wrappedValue <= range.lowerBound)
                
                Text("\(binding.wrappedValue)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(minWidth: 50)
                
                Button(action: {
                    if binding.wrappedValue < range.upperBound {
                        binding.wrappedValue += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(binding.wrappedValue < range.upperBound ? .primaryOrange1 : .secondary.opacity(0.5))
                }
                .disabled(binding.wrappedValue >= range.upperBound)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.surfaceBackground)
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func weightCard() -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "scalemass")
                    .font(.caption)
                    .foregroundColor(.primaryOrange1)
                
                Text("Weight (kg)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    if weight >= 2.5 {
                        weight -= 2.5
                    } else if weight > 0 {
                        weight = 0
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(weight > 0 ? .primaryOrange1 : .secondary.opacity(0.5))
                }
                .disabled(weight <= 0)
                
                VStack(spacing: 4) {
                    TextField("0", value: $weight, format: .number)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(minWidth: 50)
                    
                    Rectangle()
                        .fill(Color.primary.opacity(0.3))
                        .frame(height: 1)
                }
                
                Button(action: {
                    weight += 2.5
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.primaryOrange1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.surfaceBackground)
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func restTimeCard() -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.primaryOrange1)
                
                Text("Rest (sec)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    if restTime >= 15 {
                        restTime -= 15
                    } else if restTime > 0 {
                        restTime = 0
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(restTime > 0 ? .primaryOrange1 : .secondary.opacity(0.5))
                }
                .disabled(restTime <= 0)
                
                VStack(spacing: 4) {
                    TextField("60", value: $restTime, format: .number)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(minWidth: 50)
                    
                    Rectangle()
                        .fill(Color.primary.opacity(0.3))
                        .frame(height: 1)
                }
                
                Button(action: {
                    restTime += 15
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.primaryOrange1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.surfaceBackground)
        .cornerRadius(16)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let exercise = Exercise(context: context)
    exercise.name = "Panca Piana"
    exercise.targetMuscle = "Petto"
    exercise.type = "Strength"
    exercise.instructions = "Distenditi sulla panca con i piedi ben piantati a terra. Afferra il bilanciere con presa salda e controllata."
    
    return ExerciseConfigurationView(exercise: exercise) { _ in
        // Preview action
    }
}