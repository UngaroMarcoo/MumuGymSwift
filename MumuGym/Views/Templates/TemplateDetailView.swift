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
    @State private var refreshID = UUID()
    
    private var templateExercises: [WorkoutTemplateExercise] {
        let exercisesSet = template.exercises as? Set<WorkoutTemplateExercise> ?? []
        return exercisesSet.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        headerSection
                        exercisesSection
                        actionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
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
            TemplateEditView(template: template)
        }
        .onChange(of: showingEditTemplate) { _, isPresented in
            if !isPresented {
                // Refresh the view when sheet is dismissed
                refreshID = UUID()
            }
        }
        .id(refreshID)
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Template Title Section
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                        .foregroundStyle(Color.primaryGradient)
                    
                    Text("Template Details")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    if template.isDefault {
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundStyle(Color.primaryGradient)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.name ?? "Unknown")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("\(templateExercises.count) exercises")
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
            
            // Stats Cards
            HStack(spacing: 15) {
                ModernInfoCard(title: "Exercises", value: "\(templateExercises.count)", icon: "dumbbell")
                ModernInfoCard(title: "Est. Time", value: estimatedTime, icon: "clock")
                ModernInfoCard(title: "Difficulty", value: difficulty, icon: "flame")
            }
        }
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
            }
            
            LazyVStack(spacing: 12) {
                ForEach(templateExercises, id: \.objectID) { templateExercise in
                    ModernTemplateExerciseDetailCard(templateExercise: templateExercise)
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
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            NavigationLink(destination: LiveWorkoutView(template: template)) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.title3)
                    Text("Start Workout")
                        .fontWeight(.semibold)
                    
                    if isStartingWorkout {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(Color.successGradient)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Color.shadowMedium, radius: 6, x: 0, y: 3)
            }
            .disabled(isStartingWorkout)
            
            Button("Edit Template") {
                showingEditTemplate = true
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(Color.primaryGradient)
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color.shadowMedium, radius: 6, x: 0, y: 3)
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

struct ModernTemplateExerciseDetailCard: View {
    let templateExercise: WorkoutTemplateExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ExerciseImageView(
                    imageUrl: templateExercise.exercise?.imageUrl,
                    exerciseName: templateExercise.exercise?.name ?? "Unknown",
                    size: CGSize(width: 50, height: 50)
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(templateExercise.exercise?.name ?? "Unknown")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text(templateExercise.exercise?.targetMuscle ?? "")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Text("#\(templateExercise.order + 1)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.dynamicBackgroundGradient.opacity(0.15))
                    .foregroundStyle(Color.dynamicBackgroundGradient)
                    .cornerRadius(8)
            }
            
            HStack(spacing: 15) {
                ModernExerciseDetailItem(label: "Sets", value: "\(templateExercise.sets)", icon: "repeat")
                ModernExerciseDetailItem(label: "Reps", value: "\(templateExercise.reps)", icon: "arrow.clockwise")
                
                if templateExercise.weight > 0 {
                    ModernExerciseDetailItem(label: "Weight", value: "\(templateExercise.weight, default: "%.1f") kg", icon: "scalemass")
                }
                
                ModernExerciseDetailItem(label: "Rest", value: Int(templateExercise.restTime).formattedRestTime, icon: "clock")
            }
            
            
            // Show template-specific notes if available
            if let notes = templateExercise.notes, !notes.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(.primaryBlue1)
                    
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.textPrimary)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding(12)
                .background(Color.primaryBlue1.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.shadowMedium, radius: 4, x: 0, y: 2)
    }
}

struct ModernExerciseDetailItem: View {
    let label: String
    let value: String
    let icon: String
    
    private var iconColor: Color {
        switch icon {
        case "repeat":
            return .blue
        case "arrow.clockwise":
            return .green
        case "scalemass":
            return .orange
        case "clock":
            return .purple
        default:
            return .blue
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.surfaceBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(iconColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ModernInfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.primaryGradient)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.shadowMedium, radius: 4, x: 0, y: 2)
    }
}

// Keep old components for compatibility
struct TemplateExerciseDetailCard: View {
    let templateExercise: WorkoutTemplateExercise
    
    var body: some View {
        ModernTemplateExerciseDetailCard(templateExercise: templateExercise)
    }
}

struct ExerciseDetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        ModernInfoCard(title: title, value: value, icon: icon)
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
