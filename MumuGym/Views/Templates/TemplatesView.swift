import SwiftUI
import CoreData

struct PredefinedTemplate {
    let name: String
    let description: String
    let exercises: [PredefinedExercise]
}

struct PredefinedExercise {
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double
    let restTime: Int
}

struct TemplatesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @FetchRequest var templates: FetchedResults<WorkoutTemplate>
    
    @State private var showingCreateTemplate = false
    @State private var showingTemplateChoice = false
    @State private var showingPredefinedTemplates = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var templateToEdit: WorkoutTemplate?
    @State private var showingDeleteAlert = false
    @State private var templateToDelete: WorkoutTemplate?
    
    init() {
        _templates = FetchRequest(
            entity: WorkoutTemplate.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutTemplate.createdDate, ascending: false)]
        )
    }
    
    var body: some View {
        NavigationView {
            Group {
                if templates.isEmpty {
                    emptyTemplatesView
                } else {
                    templatesList
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Workout Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !templates.isEmpty {
                        Button(action: { showingTemplateChoice = true }) {
                            Image(systemName: "plus")
                        }
                        .foregroundColor(.primaryBlue1)
                        .fontWeight(.medium)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateTemplate) {
            CreateTemplateView()
        }
        .sheet(isPresented: $showingTemplateChoice) {
            TemplateChoiceView(
                onPredefinedSelected: {
                    showingTemplateChoice = false
                    showingPredefinedTemplates = true
                },
                onCustomSelected: {
                    showingTemplateChoice = false
                    showingCreateTemplate = true
                }
            )
        }
        .sheet(isPresented: $showingPredefinedTemplates) {
            PredefinedTemplatesView { template in
                showingPredefinedTemplates = false
                createTemplateFromPredefined(template)
            }
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(template: template)
        }
        .sheet(item: $templateToEdit) { template in
            TemplateEditView(template: template)
        }
        .alert("Delete Template", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                templateToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    deleteTemplate(template)
                }
            }
        } message: {
            Text("Are you sure you want to delete this template? This action cannot be undone.")
        }
    }
    
    private var emptyTemplatesView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header with gradient
            VStack(spacing: 16) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                Text("No Templates Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Create your first workout template to get started")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.warningGradient)
                    .shadow(color: Color.primaryOrange1.opacity(0.3), radius: 12, x: 0, y: 6)
            )
            
            // Action button
            VStack {
                Button("Create Template") {
                    showingTemplateChoice = true
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.successGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
            )
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var templatesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(templates, id: \.objectID) { template in
                    TemplateCard(
                        template: template,
                        action: {
                            selectedTemplate = template
                        },
                        onEdit: {
                            templateToEdit = template
                        },
                        onDelete: {
                            templateToDelete = template
                            showingDeleteAlert = true
                        }
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
    
    private func createTemplateFromPredefined(_ templateData: PredefinedTemplate) {
        let context = viewContext
        
        let template = WorkoutTemplate(context: context)
        template.name = templateData.name
        template.isDefault = false
        template.createdDate = Date()
        template.user = authManager.currentUser
        
        for (index, exerciseData) in templateData.exercises.enumerated() {
            if let exercise = findExercise(name: exerciseData.name, context: context) {
                let templateExercise = WorkoutTemplateExercise(context: context)
                templateExercise.order = Int16(index)
                templateExercise.sets = Int16(exerciseData.sets)
                templateExercise.reps = Int16(exerciseData.reps)
                templateExercise.weight = exerciseData.weight
                templateExercise.restTime = Int32(exerciseData.restTime)
                templateExercise.exercise = exercise
                templateExercise.template = template
            }
        }
        
        try? context.save()
    }
    
    private func findExercise(name: String, context: NSManagedObjectContext) -> Exercise? {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let exercises = try context.fetch(request)
            return exercises.first
        } catch {
            return nil
        }
    }
    
    private func deleteTemplate(_ template: WorkoutTemplate) {
        viewContext.delete(template)
        try? viewContext.save()
        templateToDelete = nil
    }
    
}

struct TemplateCard: View {
    let template: WorkoutTemplate
    let action: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var exerciseCount: Int {
        template.exercises?.count ?? 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text(template.name ?? "Unknown")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(exerciseCount) exercises")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Est. 45-60 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.editButtonColor)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.deleteButtonColor)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

struct TemplateChoiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onPredefinedSelected: () -> Void
    let onCustomSelected: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Choose Template Type")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select how you want to create your workout template")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    TemplateOptionCard(
                        title: "Predefined Templates",
                        description: "Ready-to-use workout templates for Push, Pull, and Leg days",
                        icon: "star.fill",
                        color: .orange
                    ) {
                        onPredefinedSelected()
                    }
                    
                    TemplateOptionCard(
                        title: "Custom Template",
                        description: "Create your own personalized workout from scratch",
                        icon: "plus.circle.fill",
                        color: .blue
                    ) {
                        onCustomSelected()
                    }
                }
                
                Spacer()
            }
            .padding(30)
            .navigationTitle("New Template")
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
}

struct TemplateOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PredefinedTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onTemplateSelected: (PredefinedTemplate) -> Void
    
    private let predefinedTemplates = [
        PredefinedTemplate(
            name: "Push Day",
            description: "Petto, spalle e tricipiti",
            exercises: [
                PredefinedExercise(name: "Panca Piana", sets: 4, reps: 8, weight: 60.0, restTime: 180),
                PredefinedExercise(name: "Lento Avanti", sets: 3, reps: 10, weight: 40.0, restTime: 120),
                PredefinedExercise(name: "Piegamenti", sets: 3, reps: 15, weight: 0.0, restTime: 60),
                PredefinedExercise(name: "Dip", sets: 3, reps: 12, weight: 0.0, restTime: 90)
            ]
        ),
        PredefinedTemplate(
            name: "Pull Day",
            description: "Schiena e bicipiti",
            exercises: [
                PredefinedExercise(name: "Trazioni a Presa prona", sets: 4, reps: 8, weight: 0.0, restTime: 180),
                PredefinedExercise(name: "Rematore a Busto flesso", sets: 4, reps: 10, weight: 50.0, restTime: 120),
                PredefinedExercise(name: "Trazioni alla Lat Machine", sets: 3, reps: 12, weight: 45.0, restTime: 90),
                PredefinedExercise(name: "Curl con Manubri", sets: 3, reps: 15, weight: 15.0, restTime: 60)
            ]
        ),
        PredefinedTemplate(
            name: "Leg Day",
            description: "Gambe e glutei",
            exercises: [
                PredefinedExercise(name: "Squat", sets: 5, reps: 8, weight: 80.0, restTime: 240),
                PredefinedExercise(name: "Stacco da Terra", sets: 4, reps: 6, weight: 100.0, restTime: 300),
                PredefinedExercise(name: "Sled Leg Press", sets: 3, reps: 15, weight: 120.0, restTime: 120),
                PredefinedExercise(name: "Calf Raise con Macchina", sets: 4, reps: 20, weight: 30.0, restTime: 60)
            ]
        ),
        PredefinedTemplate(
            name: "Upper Body",
            description: "Parte superiore completa",
            exercises: [
                PredefinedExercise(name: "Panca Piana", sets: 3, reps: 10, weight: 50.0, restTime: 150),
                PredefinedExercise(name: "Trazioni alla Lat Machine", sets: 3, reps: 12, weight: 40.0, restTime: 120),
                PredefinedExercise(name: "Lento Avanti", sets: 3, reps: 12, weight: 30.0, restTime: 120),
                PredefinedExercise(name: "Curl con Manubri", sets: 3, reps: 15, weight: 12.0, restTime: 90)
            ]
        ),
        PredefinedTemplate(
            name: "Full Body",
            description: "Allenamento completo",
            exercises: [
                PredefinedExercise(name: "Squat", sets: 3, reps: 12, weight: 60.0, restTime: 180),
                PredefinedExercise(name: "Panca Piana", sets: 3, reps: 10, weight: 50.0, restTime: 150),
                PredefinedExercise(name: "Trazioni alla Lat Machine", sets: 3, reps: 12, weight: 40.0, restTime: 120),
                PredefinedExercise(name: "Lento Avanti", sets: 3, reps: 12, weight: 30.0, restTime: 120)
            ]
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(predefinedTemplates.indices, id: \.self) { index in
                        let template = predefinedTemplates[index]
                        PredefinedTemplateCard(template: template) {
                            onTemplateSelected(template)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Choose Template")
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
}

struct PredefinedTemplateCard: View {
    let template: PredefinedTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(template.exercises.count) esercizi")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(template.exercises.prefix(3).indices, id: \.self) { index in
                        let exercise = template.exercises[index]
                        HStack {
                            Text("• \(exercise.name)")
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(exercise.sets) × \(exercise.reps)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if template.exercises.count > 3 {
                        Text("e altri \(template.exercises.count - 3) esercizi...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TemplatesView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager.shared)
}
