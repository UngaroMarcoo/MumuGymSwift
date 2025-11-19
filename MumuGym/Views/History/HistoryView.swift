import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @FetchRequest var workouts: FetchedResults<Workout>
    
    @State private var selectedWorkout: Workout?
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: Workout?
    
    init() {
        _workouts = FetchRequest(
            entity: Workout.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Workout.startTime, ascending: false)],
            predicate: NSPredicate(format: "completed == true")
        )
    }
    
    var body: some View {
        NavigationView {
            Group {
                if workouts.isEmpty {
                    emptyStateView
                } else {
                    workoutsList
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
        .alert("Delete Workout", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                workoutToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    deleteWorkout(workout)
                }
            }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start your first workout to see your history here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: LiveWorkoutView()) {
                Text("Start Workout")
                    .frame(width: 150, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var workoutsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedWorkouts, id: \.key) { dateGroup in
                    VStack(spacing: 12) {
                        HStack {
                            Text(dateGroup.key)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        ForEach(dateGroup.value, id: \.objectID) { workout in
                            WorkoutHistoryCard(
                                workout: workout,
                                onTap: { selectedWorkout = workout },
                                onDelete: { 
                                    workoutToDelete = workout
                                    showingDeleteAlert = true
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
    
    private var groupedWorkouts: [(key: String, value: [Workout])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: workouts) { workout in
            let date = workout.startTime ?? Date()
            if calendar.isDateInToday(date) {
                return "Today"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: date)
            }
        }
        
        return grouped.sorted { first, second in
            if first.key == "Today" { return true }
            if second.key == "Today" { return false }
            if first.key == "Yesterday" { return true }
            if second.key == "Yesterday" { return false }
            return first.key > second.key
        }
    }
    
    private func deleteWorkout(_ workout: Workout) {
        viewContext.delete(workout)
        try? viewContext.save()
        workoutToDelete = nil
    }
}

struct WorkoutHistoryCard: View {
    let workout: Workout
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var exerciseCount: Int {
        workout.exercises?.count ?? 0
    }
    
    private var formattedDuration: String {
        let duration = Int(workout.duration)
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var formattedTime: String {
        guard let startTime = workout.startTime else { return "--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name ?? "Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Started at \(formattedTime)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                HStack(spacing: 20) {
                    WorkoutStat(title: "Exercises", value: "\(exerciseCount)", icon: "dumbbell")
                    WorkoutStat(title: "Duration", value: formattedDuration, icon: "clock")
                    WorkoutStat(title: "Sets", value: "\(totalSets)", icon: "repeat")
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var totalSets: Int {
        let exercisesSet = workout.exercises as? Set<WorkoutExercise> ?? []
        return exercisesSet.reduce(0) { total, exercise in
            let setsCount = (exercise.sets as? Set<WorkoutSet>)?.count ?? 0
            return total + setsCount
        }
    }
}

struct WorkoutStat: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    
    private var workoutExercises: [WorkoutExercise] {
        let exercisesSet = workout.exercises as? Set<WorkoutExercise> ?? []
        return exercisesSet.sorted { $0.order < $1.order }
    }
    
    private var formattedDate: String {
        guard let startTime = workout.startTime else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    private var formattedDuration: String {
        let duration = Int(workout.duration)
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else {
            return String(format: "%dm %ds", minutes, seconds)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    headerSection
                    exercisesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle(workout.name ?? "Workout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                InfoCard(title: "Duration", value: formattedDuration, icon: "clock")
                InfoCard(title: "Exercises", value: "\(workoutExercises.count)", icon: "dumbbell")
                InfoCard(title: "Total Sets", value: "\(totalSets)", icon: "repeat")
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
                ForEach(workoutExercises, id: \.objectID) { exercise in
                    WorkoutExerciseDetailCard(workoutExercise: exercise)
                }
            }
        }
    }
    
    private var totalSets: Int {
        return workoutExercises.reduce(0) { total, exercise in
            let setsCount = (exercise.sets as? Set<WorkoutSet>)?.count ?? 0
            return total + setsCount
        }
    }
}

struct WorkoutExerciseDetailCard: View {
    let workoutExercise: WorkoutExercise
    
    private var exerciseSets: [WorkoutSet] {
        let setsSet = workoutExercise.sets as? Set<WorkoutSet> ?? []
        return Array(setsSet).sorted { first, second in
            // Since sets don't have an order property, we'll just keep them as is
            return true
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(workoutExercise.exercise?.name ?? "Unknown")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if workoutExercise.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            if !exerciseSets.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Text("Set")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                        
                        Text("Reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50)
                        
                        Text("Weight")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("✓")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(exerciseSets.indices, id: \.self) { index in
                        let set = exerciseSets[index]
                        HStack {
                            Text("\(index + 1)")
                                .font(.subheadline)
                                .frame(width: 30)
                            
                            Text("\(set.reps)")
                                .font(.subheadline)
                                .frame(width: 50)
                            
                            Text("\(set.weight, default: "%.1f") kg")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(set.completed ? .green : .gray)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager.shared)
}