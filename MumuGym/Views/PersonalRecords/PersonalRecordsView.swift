import SwiftUI
import CoreData

struct PersonalRecordsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @FetchRequest var personalRecords: FetchedResults<PersonalRecord>
    @FetchRequest var exercises: FetchedResults<Exercise>
    
    @State private var showingAddRecord = false
    @State private var selectedRecord: PersonalRecord?
    @State private var showingDeleteAlert = false
    @State private var recordToDelete: PersonalRecord?
    
    init() {
        _personalRecords = FetchRequest(
            entity: PersonalRecord.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \PersonalRecord.exerciseName, ascending: true),
                NSSortDescriptor(keyPath: \PersonalRecord.date, ascending: false)
            ]
        )
        
        _exercises = FetchRequest(
            entity: Exercise.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.primaryOrange1, Color.primaryOrange2]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom title section
                    HStack {
                        Text("Personal Records")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.cardBackground)
                        
                        Spacer()
                        
                        Button(action: { showingAddRecord = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(Color.cardBackground)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                    
                    Group {
                        if personalRecords.isEmpty {
                            emptyStateView
                        } else {
                            recordsList
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddRecord) {
            AddPersonalRecordView(exercises: Array(exercises))
        }
        .sheet(item: $selectedRecord) { record in
            PersonalRecordDetailView(record: record)
        }
        .alert("Delete Record", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                recordToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let record = recordToDelete {
                    deleteRecord(record)
                }
            }
        } message: {
            Text("Are you sure you want to delete this personal record?")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                    .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Text("No Personal Records")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Track your best lifts and see your progress over time")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button("Add First Record") {
                    showingAddRecord = true
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.dynamicBackgroundGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 25)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
    
    private var recordsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedRecords, id: \.key) { exerciseGroup in
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "dumbbell.fill")
                                .foregroundColor(Color.primaryOrange2)
                                .font(.title2)
                            
                            Text(exerciseGroup.key)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(exerciseGroup.value.count) record\(exerciseGroup.value.count == 1 ? "" : "s")")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.primaryOrange1)
                                .cornerRadius(10)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.95))
                                .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 3)
                        )
                        
                        PersonalRecordCard(
                            records: exerciseGroup.value,
                            onTap: { record in selectedRecord = record },
                            onDelete: { record in
                                recordToDelete = record
                                showingDeleteAlert = true
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
    
    private var groupedRecords: [(key: String, value: [PersonalRecord])] {
        let grouped = Dictionary(grouping: personalRecords) { $0.exerciseName ?? "Unknown" }
        return grouped.sorted { $0.key < $1.key }
    }
    
    private func deleteRecord(_ record: PersonalRecord) {
        viewContext.delete(record)
        try? viewContext.save()
        recordToDelete = nil
    }
}

struct PersonalRecordCard: View {
    let records: [PersonalRecord]
    let onTap: (PersonalRecord) -> Void
    let onDelete: (PersonalRecord) -> Void
    
    private var bestRecord: PersonalRecord? {
        records.max { first, second in
            // Calculate 1RM using Epley formula: weight * (1 + reps/30)
            let firstRM = first.weight * (1 + Double(first.reps) / 30)
            let secondRM = second.weight * (1 + Double(second.reps) / 30)
            return firstRM < secondRM
        }
    }
    
    private var latestRecord: PersonalRecord? {
        records.max { $0.date! < $1.date! }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let best = bestRecord {
                Button(action: { onTap(best) }) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Best Performance")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 8) {
                                    Text("\(best.weight, default: "%.1f") kg")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    
                                    Text("×")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(best.reps)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Est. 1RM")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(calculateOneRM(weight: best.weight, reps: Int(best.reps)), default: "%.1f") kg")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if let latest = latestRecord, latest != best {
                            Divider()
                            
                            HStack {
                                Text("Latest: \(latest.weight, default: "%.1f") kg × \(latest.reps)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatDate(latest.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if records.count > 1 {
                recordsHistory
            }
        }
    }
    
    private var recordsHistory: some View {
        VStack(spacing: 8) {
            HStack {
                Text("History")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("See all (\(records.count))")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 6) {
                ForEach(records.prefix(3), id: \.objectID) { record in
                    HStack {
                        Text("\(record.weight, default: "%.1f") kg × \(record.reps)")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(formatDate(record.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: { onDelete(record) }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                    .onTapGesture {
                        onTap(record)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
    }
    
    private func calculateOneRM(weight: Double, reps: Int) -> Double {
        if reps == 1 {
            return weight
        }
        // Epley formula: 1RM = weight * (1 + reps/30)
        return weight * (1 + Double(reps) / 30)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "--" }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct AddPersonalRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    let exercises: [Exercise]
    
    @State private var selectedExercise: Exercise?
    @State private var weight = ""
    @State private var reps = ""
    @State private var date = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.primaryOrange1, Color.primaryOrange2]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        exerciseSection
                        performanceSection
                        dateSection
                        if selectedExercise != nil, !weight.isEmpty, !reps.isEmpty,
                           let weightValue = Double(weight), let repsValue = Int(reps) {
                            estimatedOneRMSection(weight: weightValue, reps: repsValue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("New Personal Record")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRecord()
                    }
                    .foregroundColor(isValidInput ? .white : .white.opacity(0.5))
                    .fontWeight(.semibold)
                    .disabled(!isValidInput)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var exerciseSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(Color.primaryOrange1)
                    .font(.title2)
                
                Text("Exercise")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            NavigationLink(destination: ExerciseSelectionView(
                exercises: exercises,
                selectedExercise: $selectedExercise
            )) {
                HStack {
                    Text("Exercise")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let exercise = selectedExercise {
                        Text(exercise.name ?? "Unknown")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Choose an exercise")
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var performanceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(Color.primaryOrange2)
                    .font(.title2)
                
                Text("Performance")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Weight (kg)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    TextField("0.0", text: $weight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                }
                
                HStack {
                    Text("Reps")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    TextField("0", text: $reps)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var dateSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(Color.primaryOrange1)
                    .font(.title2)
                
                Text("Date")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .padding(12)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private func estimatedOneRMSection(weight: Double, reps: Int) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "trophy.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Estimated 1RM")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                Text("One Rep Max")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(calculateOneRM(weight: weight, reps: reps), default: "%.1f") kg")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primaryOrange1)
            }
            .padding(16)
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var oldFormView: some View {
        Form {
        }
    }
    
    private var oldForm: some View {
        Form {
            Section("Exercise") {
                NavigationLink(destination: ExerciseSelectionView(
                    exercises: exercises,
                    selectedExercise: $selectedExercise
                )) {
                    HStack {
                        Text("Exercise")
                        Spacer()
                        if let exercise = selectedExercise {
                            Text(exercise.name ?? "Unknown")
                                .foregroundColor(.secondary)
                        } else {
                            Text("Choose an exercise")
                                .foregroundColor(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Performance") {
                HStack {
                    Text("Weight (kg)")
                    Spacer()
                    TextField("0.0", text: $weight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Reps")
                    Spacer()
                    TextField("0", text: $reps)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section("Date") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
        }
    }
    
    private var isValidInput: Bool {
        selectedExercise != nil &&
        !weight.isEmpty &&
        !reps.isEmpty &&
        Double(weight) != nil &&
        Int(reps) != nil &&
        Double(weight)! > 0 &&
        Int(reps)! > 0
    }
    
    private func calculateOneRM(weight: Double, reps: Int) -> Double {
        if reps == 1 {
            return weight
        }
        return weight * (1 + Double(reps) / 30)
    }
    
    private func saveRecord() {
        guard let user = authManager.currentUser,
              let exercise = selectedExercise,
              let weightValue = Double(weight),
              let repsValue = Int(reps) else {
            alertMessage = "Please fill in all fields correctly"
            showingAlert = true
            return
        }
        
        let record = PersonalRecord(context: viewContext)
        record.exerciseName = exercise.name
        record.weight = weightValue
        record.reps = Int16(repsValue)
        record.date = date
        record.user = user
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save record: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct PersonalRecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let record: PersonalRecord
    
    private var formattedDate: String {
        guard let date = record.date else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private var oneRM: Double {
        let reps = Int(record.reps)
        if reps == 1 {
            return record.weight
        }
        return record.weight * (1 + Double(reps) / 30)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.primaryOrange1, Color.primaryOrange2]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        headerSection
                        detailsSection
                        calculationsSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle(record.exerciseName ?? "Record")
            .navigationBarTitleDisplayMode(.large)
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Text(record.exerciseName ?? "Unknown Exercise")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var detailsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(Color.primaryOrange2)
                    .font(.title2)
                
                Text("Performance Details")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                RecordDetailCard(title: "Weight", value: "\(record.weight, default: "%.1f") kg", icon: "scalemass")
                RecordDetailCard(title: "Reps", value: "\(record.reps)", icon: "repeat")
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var calculationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "function")
                    .foregroundColor(Color.primaryOrange1)
                    .font(.title2)
                
                Text("Calculations")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                CalculationRow(label: "Estimated 1RM", value: "\(oneRM, default: "%.1f") kg")
                CalculationRow(label: "Volume (Weight × Reps)", value: "\(record.weight * Double(record.reps), default: "%.1f") kg")
                
                if record.reps > 1 {
                    CalculationRow(label: "75% of 1RM", value: "\(oneRM * 0.75, default: "%.1f") kg")
                    CalculationRow(label: "85% of 1RM", value: "\(oneRM * 0.85, default: "%.1f") kg")
                    CalculationRow(label: "95% of 1RM", value: "\(oneRM * 0.95, default: "%.1f") kg")
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
}

struct RecordDetailCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct CalculationRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.primaryOrange1)
        }
    }
}

struct ExerciseSelectionView: View {
    let exercises: [Exercise]
    @Binding var selectedExercise: Exercise?
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { exercise in
                exercise.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
                exercise.targetMuscle?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    private var groupedExercises: [(key: String, value: [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { exercise in
            exercise.targetMuscle?.capitalized ?? "Other"
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        List {
            ForEach(groupedExercises, id: \.key) { group in
                Section(group.key) {
                    ForEach(group.value, id: \.objectID) { exercise in
                        ExerciseRowSelectionView(
                            exercise: exercise,
                            isSelected: selectedExercise?.objectID == exercise.objectID
                        ) {
                            selectedExercise = exercise
                            dismiss()
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

struct ExerciseRowSelectionView: View {
    let exercise: Exercise
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ExerciseImageView(
                    imageUrl: exercise.imageUrl,
                    exerciseName: exercise.name ?? "",
                    size: CGSize(width: 50, height: 50)
                )
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let targetMuscle = exercise.targetMuscle {
                        Text(targetMuscle.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.primaryOrange1)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PersonalRecordsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager.shared)
}
