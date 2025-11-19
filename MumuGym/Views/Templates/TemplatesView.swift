import SwiftUI
import CoreData

struct TemplatesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @FetchRequest var templates: FetchedResults<WorkoutTemplate>
    @FetchRequest var defaultTemplates: FetchedResults<WorkoutTemplate>
    
    @State private var showingCreateTemplate = false
    @State private var showingTemplateChoice = false
    @State private var selectedTemplate: WorkoutTemplate?
    
    init() {
        _templates = FetchRequest(
            entity: WorkoutTemplate.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutTemplate.createdDate, ascending: false)],
            predicate: NSPredicate(format: "isDefault == false")
        )
        
        _defaultTemplates = FetchRequest(
            entity: WorkoutTemplate.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutTemplate.name, ascending: true)],
            predicate: NSPredicate(format: "isDefault == true")
        )
    }
    
    var body: some View {
        NavigationView {
            Group {
                if templates.isEmpty && defaultTemplates.isEmpty {
                    emptyTemplatesView
                } else {
                    ScrollView {
                        VStack(spacing: 25) {
                            if !defaultTemplates.isEmpty {
                                defaultTemplatesSection
                            }
                            
                            customTemplatesSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Workout Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !templates.isEmpty || !defaultTemplates.isEmpty {
                        Button(action: { showingCreateTemplate = true }) {
                            Image(systemName: "plus")
                        }
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
                    createDefaultTemplates()
                },
                onCustomSelected: {
                    showingTemplateChoice = false
                    showingCreateTemplate = true
                }
            )
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(template: template)
        }
        .onAppear {
            createDefaultTemplates()
        }
    }
    
    private var defaultTemplatesSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Recommended Templates")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(defaultTemplates, id: \.objectID) { template in
                    TemplateCard(template: template) {
                        selectedTemplate = template
                    }
                }
            }
        }
    }
    
    private var customTemplatesSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("My Templates")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("New Template") {
                    showingCreateTemplate = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if templates.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    ForEach(templates, id: \.objectID) { template in
                        TemplateCard(template: template) {
                            selectedTemplate = template
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Custom Templates")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Create your first workout template to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Template") {
                showingCreateTemplate = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var emptyTemplatesView: some View {
        VStack(spacing: 25) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("Create Your First Template")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Start with predefined workouts or create your own custom template")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 15) {
                Button("Use Predefined Templates") {
                    createDefaultTemplates()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 40)
                
                Button("Create Custom Template") {
                    showingCreateTemplate = true
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(.systemGray6))
                .foregroundColor(.blue)
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private func createDefaultTemplates() {
        let context = viewContext
        
        let request: NSFetchRequest<WorkoutTemplate> = WorkoutTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == true")
        
        do {
            let existingCount = try context.count(for: request)
            if existingCount == 0 {
                createDefaultTemplate(
                    name: "Push Day",
                    exercises: [
                        ("Panca Piana", 4, 8, 60.0, 180),
                        ("Lento Avanti", 3, 10, 40.0, 120),
                        ("Piegamenti", 3, 15, 0.0, 60),
                        ("Dip", 3, 12, 0.0, 90)
                    ]
                )
                
                createDefaultTemplate(
                    name: "Pull Day",
                    exercises: [
                        ("Trazioni a Presa prona", 4, 8, 0.0, 180),
                        ("Rematore a Busto flesso", 4, 10, 50.0, 120),
                        ("Trazioni alla Lat Machine", 3, 12, 45.0, 90),
                        ("Curl con Manubri", 3, 15, 15.0, 60)
                    ]
                )
                
                createDefaultTemplate(
                    name: "Leg Day",
                    exercises: [
                        ("Squat", 5, 8, 80.0, 240),
                        ("Stacco da Terra", 4, 6, 100.0, 300),
                        ("Sled Leg Press", 3, 15, 120.0, 120),
                        ("Calf Raise con Macchina", 4, 20, 30.0, 60)
                    ]
                )
                
                try context.save()
            }
        } catch {
            print("Failed to create default templates: \(error)")
        }
    }
    
    private func createDefaultTemplate(name: String, exercises: [(String, Int16, Int16, Double, Int32)]) {
        let template = WorkoutTemplate(context: viewContext)
        template.name = name
        template.isDefault = true
        template.createdDate = Date()
        
        for (index, (exerciseName, sets, reps, weight, restTime)) in exercises.enumerated() {
            if let exercise = getExercise(name: exerciseName) {
                let templateExercise = WorkoutTemplateExercise(context: viewContext)
                templateExercise.order = Int16(index)
                templateExercise.sets = sets
                templateExercise.reps = reps
                templateExercise.weight = weight
                templateExercise.restTime = restTime
                templateExercise.exercise = exercise
                templateExercise.template = template
            }
        }
    }
    
    private func getExercise(name: String) -> Exercise? {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let exercises = try viewContext.fetch(request)
            return exercises.first
        } catch {
            return nil
        }
    }
}

struct TemplateCard: View {
    let template: WorkoutTemplate
    let action: () -> Void
    
    var exerciseCount: Int {
        template.exercises?.count ?? 0
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(template.name ?? "Unknown")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if template.isDefault {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
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
            .padding(16)
            .frame(height: 120)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
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

#Preview {
    TemplatesView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager.shared)
}