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
    @State private var showingSuccessAnimation = false
    
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
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Hero section with exercise info
                        heroSection
                            .frame(height: geometry.size.height * 0.4)
                        
                        // Configuration content
                        VStack(spacing: 24) {
                            parametersSection
                            notesSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                        .padding(.bottom, 100)
                        .background(Color(.systemGroupedBackground))
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                // Custom close button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .black.opacity(0.3))
                }
                .padding(.top, 50)
                .padding(.trailing, 20)
            }
            .overlay(alignment: .bottom) {
                // Floating save button
                saveButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
            }
            .overlay {
                if showingSuccessAnimation {
                    successAnimation
                }
            }
        }
    }
    
    private var heroSection: some View {
        ZStack {
            // Dynamic background gradient based on muscle group
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Exercise image with glowing effect
                ExerciseImageView(
                    imageUrl: exercise.imageUrl,
                    exerciseName: exercise.name ?? "Unknown",
                    size: CGSize(width: 120, height: 120)
                )
                .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 0)
                .scaleEffect(showingSuccessAnimation ? 1.1 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessAnimation)
                
                VStack(spacing: 8) {
                    Text(exercise.name ?? "Unknown")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        if let muscle = exercise.targetMuscle {
                            Label(muscle, systemImage: "figure.strengthtraining.traditional")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        if let type = exercise.type {
                            Label(type.capitalized, systemImage: "bolt.fill")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var backgroundGradient: LinearGradient {
        let muscleGroup = exercise.targetMuscle?.lowercased() ?? ""
        
        switch muscleGroup {
        case let muscle where muscle.contains("petto"):
            return LinearGradient(
                colors: [Color.red.opacity(0.8), Color.orange.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let muscle where muscle.contains("schiena"):
            return LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.teal.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let muscle where muscle.contains("gambe"):
            return LinearGradient(
                colors: [Color.green.opacity(0.8), Color.mint.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let muscle where muscle.contains("braccia"):
            return LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let muscle where muscle.contains("spalle"):
            return LinearGradient(
                colors: [Color.indigo.opacity(0.8), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color.primaryOrange1.opacity(0.8), Color.primaryOrange2.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var parametersSection: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.primaryOrange1)
                    .font(.title2)
                
                Text("Exercise Parameters")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                modernParameterCard(
                    title: "Sets",
                    value: sets,
                    range: 1...15,
                    binding: $sets,
                    icon: "repeat",
                    color: .blue
                )
                
                modernParameterCard(
                    title: "Reps",
                    value: reps,
                    range: 1...100,
                    binding: $reps,
                    icon: "arrow.clockwise",
                    color: .green
                )
                
                modernWeightCard()
                
                modernRestTimeCard()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    @ViewBuilder
    private func modernParameterCard(title: String, value: Int, range: ClosedRange<Int>, binding: Binding<Int>, icon: String, color: Color) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    if binding.wrappedValue > range.lowerBound {
                        binding.wrappedValue -= 1
                        HapticManager.shared.impact(.light)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(binding.wrappedValue > range.lowerBound ? color : .secondary.opacity(0.5))
                }
                .disabled(binding.wrappedValue <= range.lowerBound)
                .scaleEffect(binding.wrappedValue <= range.lowerBound ? 0.9 : 1.0)
                .animation(.spring(response: 0.3), value: binding.wrappedValue <= range.lowerBound)
                
                Text("\(binding.wrappedValue)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(minWidth: 60)
                    .contentTransition(.numericText())
                    .animation(.bouncy, value: binding.wrappedValue)
                
                Button(action: {
                    if binding.wrappedValue < range.upperBound {
                        binding.wrappedValue += 1
                        HapticManager.shared.impact(.light)
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(binding.wrappedValue < range.upperBound ? color : .secondary.opacity(0.5))
                }
                .disabled(binding.wrappedValue >= range.upperBound)
                .scaleEffect(binding.wrappedValue >= range.upperBound ? 0.9 : 1.0)
                .animation(.spring(response: 0.3), value: binding.wrappedValue >= range.upperBound)
            }
        }
        .padding(20)
        .background(color.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func modernWeightCard() -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "scalemass")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                Text("Weight (kg)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    if weight >= 2.5 {
                        weight -= 2.5
                        HapticManager.shared.impact(.light)
                    } else if weight > 0 {
                        weight = 0
                        HapticManager.shared.impact(.light)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(weight > 0 ? .orange : .secondary.opacity(0.5))
                }
                .disabled(weight <= 0)
                .scaleEffect(weight <= 0 ? 0.9 : 1.0)
                .animation(.spring(response: 0.3), value: weight <= 0)
                
                VStack(spacing: 4) {
                    TextField("0", value: $weight, format: .number)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(minWidth: 60)
                    
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(height: 2)
                }
                
                Button(action: {
                    weight += 2.5
                    HapticManager.shared.impact(.light)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(20)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func modernRestTimeCard() -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock")
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Text("Rest (sec)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    if restTime >= 15 {
                        restTime -= 15
                        HapticManager.shared.impact(.light)
                    } else if restTime > 0 {
                        restTime = 0
                        HapticManager.shared.impact(.light)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(restTime > 0 ? .purple : .secondary.opacity(0.5))
                }
                .disabled(restTime <= 0)
                .scaleEffect(restTime <= 0 ? 0.9 : 1.0)
                .animation(.spring(response: 0.3), value: restTime <= 0)
                
                VStack(spacing: 4) {
                    TextField("60", value: $restTime, format: .number)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(minWidth: 60)
                    
                    Rectangle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(height: 2)
                }
                
                Button(action: {
                    restTime += 15
                    HapticManager.shared.impact(.light)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                }
            }
            
            // Quick rest time presets
            HStack(spacing: 8) {
                ForEach([30, 60, 90, 120], id: \.self) { preset in
                    Button("\(preset)s") {
                        restTime = preset
                        HapticManager.shared.impact(.medium)
                    }
                    .font(.caption)
                    .foregroundColor(restTime == preset ? .white : .purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(restTime == preset ? Color.purple : Color.purple.opacity(0.1))
                    )
                    .scaleEffect(restTime == preset ? 1.05 : 1.0)
                    .animation(.bouncy, value: restTime)
                }
            }
        }
        .padding(20)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var notesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.teal)
                    .font(.title2)
                
                Text("Personal Notes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Add notes to remember form cues, weights used, or what to focus on next time.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("e.g., Focus on form, felt easy today, increase weight next time...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(16)
                    .background(Color.teal.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.teal.opacity(0.2), lineWidth: 1)
                    )
                    .font(.body)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var saveButton: some View {
        Button(action: saveExercise) {
            HStack(spacing: 12) {
                Image(systemName: existingData != nil ? "arrow.clockwise" : "plus")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(existingData != nil ? "Update Exercise" : "Add to Template")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.primaryOrange1, Color.primaryOrange2],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.primaryOrange1.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(showingSuccessAnimation ? 1.05 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessAnimation)
    }
    
    private var successAnimation: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showingSuccessAnimation = false
                    }
                }
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(showingSuccessAnimation ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showingSuccessAnimation)
                
                Text("Exercise Added!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .opacity(showingSuccessAnimation ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: showingSuccessAnimation)
    }
    
    private func saveExercise() {
        let exerciseData = TemplateExerciseData(
            exercise: exercise,
            sets: sets,
            reps: reps,
            weight: weight,
            restTime: restTime,
            notes: notes
        )
        
        // Show success animation
        HapticManager.shared.success()
        withAnimation {
            showingSuccessAnimation = true
        }
        
        // Save and dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onSave(exerciseData)
            dismiss()
        }
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