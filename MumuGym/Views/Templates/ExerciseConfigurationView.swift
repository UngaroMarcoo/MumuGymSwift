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
    @State private var isSuperSet: Bool = false
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
            _isSuperSet = State(initialValue: existing.restTime == 0)
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
                Color.surfaceBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        exerciseInfoSection
                        configurationSection
                        notesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Configure Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(existingData != nil ? "Update" : "Add") {
                        let exerciseData = TemplateExerciseData(
                            exercise: exercise,
                            sets: sets,
                            reps: reps,
                            weight: weight,
                            restTime: isSuperSet ? 0 : restTime,
                            notes: notes
                        )
                        onSave(exerciseData)
                        dismiss()
                    }
                    .foregroundColor(.primaryBlue1)
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private var exerciseInfoSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
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
                    
                    if let muscle = exercise.targetMuscle {
                        HStack {
                            Image(systemName: "target")
                                .font(.caption)
                                .foregroundColor(.primaryOrange1)
                            
                            Text(muscle)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
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
            
            // Instructions if available
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
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
    
    private var configurationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.primaryBlue1)
                    .font(.title2)
                
                Text("Exercise Parameters")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Vertical list of parameter cards
            VStack(spacing: 12) {
                parameterCard(
                    title: "Sets",
                    value: sets,
                    range: 1...15,
                    binding: $sets,
                    icon: "repeat",
                    color: .blue
                )
                
                parameterCard(
                    title: "Reps",
                    value: reps,
                    range: 1...100,
                    binding: $reps,
                    icon: "arrow.clockwise",
                    color: .green
                )
                
                weightCard()
                
                restTimeCard()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func parameterCard(title: String, value: Int, range: ClosedRange<Int>, binding: Binding<Int>, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
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
                        .font(.title2)
                        .foregroundColor(binding.wrappedValue > range.lowerBound ? color : .secondary.opacity(0.5))
                }
                .disabled(binding.wrappedValue <= range.lowerBound)
                
                Text("\(binding.wrappedValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(minWidth: 40)
                
                Button(action: {
                    if binding.wrappedValue < range.upperBound {
                        binding.wrappedValue += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(binding.wrappedValue < range.upperBound ? color : .secondary.opacity(0.5))
                }
                .disabled(binding.wrappedValue >= range.upperBound)
            }
        }
        .padding(16)
        .background(Color.surfaceBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func weightCard() -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "scalemass")
                    .font(.caption)
                    .foregroundColor(.orange)
                
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
                        .font(.title2)
                        .foregroundColor(weight > 0 ? .orange : .secondary.opacity(0.5))
                }
                .disabled(weight <= 0)
                
                Text(String(format: "%.1f", weight))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(minWidth: 40)
                
                Button(action: {
                    weight += 2.5
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(16)
        .background(Color.surfaceBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func restTimeCard() -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                Text("Rest")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // SuperSet toggle first
            HStack {
                Button("SS") {
                    isSuperSet = true
                    restTime = 0
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSuperSet ? .white : .purple)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSuperSet ? Color.purple : Color.purple.opacity(0.1))
                )
                
                Text("Super Set")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            if !isSuperSet {
                HStack(spacing: 12) {
                    Button(action: {
                        if restTime >= 15 {
                            restTime -= 15
                        } else if restTime > 0 {
                            restTime = 0
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(restTime > 0 ? .purple : .secondary.opacity(0.5))
                    }
                    .disabled(restTime <= 0)
                    
                    Text(restTime.formattedRestTime)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .frame(minWidth: 40)
                    
                    Button(action: {
                        restTime += 15
                        isSuperSet = false
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                }
                
                // Quick preset buttons
                VStack(spacing: 8) {
                    Text("Quick Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 8) {
                        ForEach([30, 60, 90, 120], id: \.self) { preset in
                            Button("\(preset)s") {
                                restTime = preset
                                isSuperSet = false
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(restTime == preset && !isSuperSet ? .white : .purple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(restTime == preset && !isSuperSet ? Color.purple : Color.purple.opacity(0.1))
                            )
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                        
                        Text("No Rest")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Go directly to next exercise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Use Rest Time Instead") {
                        isSuperSet = false
                        restTime = 60
                    }
                    .font(.caption2)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color.surfaceBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var notesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.primaryBlue1)
                    .font(.title2)
                
                Text("Personal Notes")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Add notes for this exercise (optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("e.g., Focus on form, increase weight next time...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(16)
                    .background(Color.surfaceBackground)
                    .cornerRadius(12)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium.opacity(0.15), radius: 8, x: 0, y: 4)
        )
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
