import SwiftUI
import CoreData

struct HomeView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var themeManager = ThemeManager.shared
    @Binding var selectedTab: Int
    
    @State private var currentWeight = ""
    @State private var showingWeightEntry = false
    @State private var showingProfile = false
    @State private var showingWeightTracking = false
    
    var body: some View {
        ZStack {
            themeManager.currentBackgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome section
                    HStack {
                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.cardBackground)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 5)
                    
                    headerSection
                    weightSection
                    quickStatsSection
                    quickActionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 5)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            loadUserWeights()
        }
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntryView(currentWeight: $currentWeight, targetWeight: .constant(""))
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingWeightTracking) {
            WeightEntryView(currentWeight: $currentWeight, targetWeight: .constant(""))
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Gradient header bar
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello, \(authManager.currentUser?.firstName ?? "User")!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Ready for today's workout?")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingProfile = true }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(themeManager.customBackgroundColor)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private var weightSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(Color.primaryPurple2)
                    .font(.title3)
                
                Text("Current Weight")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
            }
            
            Button(action: { showingWeightTracking = true }) {
                VStack(spacing: 8) {
                    Text(currentWeight.isEmpty ? "--" : "\(currentWeight) kg")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primaryPurple2)
                    
                    Text("Tap to track weight")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfaceBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primaryPurple2.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
    
    
    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Color.accentTeal)
                    .font(.title3)
                
                Text("This Week")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                statCard(title: "Workouts", value: "3", icon: "dumbbell")
                statCard(title: "Duration", value: "4.5h", icon: "clock")
                statCard(title: "Calories", value: "1,250", icon: "flame")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.accentTeal)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentTeal.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color.primaryOrange2)
                    .font(.title3)
                
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                Button(action: { selectedTab = 2 }) {
                    actionButton(title: "Start Quick Workout", icon: "play.fill", gradient: Color.successGradient)
                }
                
                Button(action: { selectedTab = 1 }) {
                    actionButton(title: "Browse Templates", icon: "doc.text.fill", gradient: Color.primaryGradient)
                }
                
                Button(action: { selectedTab = 4 }) {
                    actionButton(title: "Log Personal Record", icon: "trophy.fill", gradient: Color.warningGradient)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
    
    private func actionButton(title: String, icon: String, gradient: LinearGradient) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(gradient)
                .shadow(color: Color.shadowMedium, radius: 6, x: 0, y: 2)
        )
    }
    
    private func loadUserWeights() {
        guard let user = authManager.currentUser else { return }
        
        if user.currentWeight > 0 {
            currentWeight = String(format: "%.1f", user.currentWeight)
        }
    }
}

struct WeightEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var currentWeight: String
    @Binding var targetWeight: String
    
    @State private var selectedDate = Date()
    @State private var weightValue: Double = 70.0
    @State private var isInitialized = false
    @State private var isHoldingMinus = false
    @State private var isHoldingPlus = false
    @State private var holdTimer: Timer?
    @State private var showingEditAlert = false
    @State private var showingDeleteAlert = false
    @State private var editingWeightLog: WeightLog?
    @State private var editWeight: Double = 70.0
    @State private var targetWeightValue: Double = 70.0
    @State private var showingTargetWeightEdit = false
    
    @FetchRequest var weightLogs: FetchedResults<WeightLog>
    
    init(currentWeight: Binding<String>, targetWeight: Binding<String>) {
        _currentWeight = currentWeight
        _targetWeight = targetWeight
        _weightLogs = FetchRequest(
            entity: WeightLog.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \WeightLog.date, ascending: false)]
        )
    }
    
    private var weightLogsGroupedByDay: [String: [WeightLog]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: weightLogs) { log in
            guard let date = log.date else { return "" }
            return calendar.dateInterval(of: .day, for: date)?.start.timeIntervalSince1970.description ?? ""
        }
        return grouped
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                // Header with gradient
                VStack(spacing: 12) {
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text("Log Daily Weight")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purpleGradient)
                        .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 4)
                )
                
                // Date selector
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Color.primaryPurple2)
                            .font(.title2)
                        
                        Text("Date")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                    }
                    
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.surfaceBackground)
                        .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
                )
                
                // Weight selector with +/- buttons
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(Color.primaryPurple2)
                            .font(.title2)
                        
                        Text("Weight")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                    }
                    
                    // Weight control with +/- buttons
                    HStack(spacing: 20) {
                        // Minus button
                        Button(action: { quickDecrease() }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color.primaryPurple2)
                        }
                        .disabled(weightValue <= 30.0)
                        .opacity(weightValue <= 30.0 ? 0.3 : 1.0)
                        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                        } onPressingChanged: { pressing in
                            if pressing {
                                startHoldDecrease()
                            } else {
                                stopHolding()
                            }
                        }
                        
                        // Weight display
                        VStack(spacing: 4) {
                            Text("\(String(format: "%.1f", weightValue))")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            
                            Text("kg")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(minWidth: 120)
                        
                        // Plus button
                        Button(action: { quickIncrease() }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color.primaryPurple2)
                        }
                        .disabled(weightValue >= 200.0)
                        .opacity(weightValue >= 200.0 ? 0.3 : 1.0)
                        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                        } onPressingChanged: { pressing in
                            if pressing {
                                startHoldIncrease()
                            } else {
                                stopHolding()
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.surfaceBackground)
                        .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
                )
                
                // Save button
                Button("Save Weight") {
                    saveWeight()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.purpleGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                
                // Target weight section
                targetWeightSection
                
                // Weight history section
                weightHistorySection
                    .onAppear {
                        cleanInvalidWeightLogs()
                    }
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryBlue1)
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            initializeWeight()
            initializeTargetWeight()
        }
        .onDisappear {
            stopHolding()
        }
        .alert("Edit Weight", isPresented: $showingEditAlert) {
            TextField("Weight (30-200 kg)", value: $editWeight, format: .number)
            Button("Cancel", role: .cancel) {
                editingWeightLog = nil
            }
            Button("Save") {
                saveEditedWeight()
            }
            .disabled(editWeight < 30.0 || editWeight > 200.0)
        } message: {
            Text("Enter new weight for \(editingWeightLog?.date?.formatted(date: .abbreviated, time: .omitted) ?? "") (Range: 30-200 kg)")
        }
        .alert("Delete Weight Log", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                editingWeightLog = nil
            }
            Button("Delete", role: .destructive) {
                deleteWeightLog()
            }
        } message: {
            Text("Are you sure you want to delete this weight entry?")
        }
    }
    
    private func initializeWeight() {
        if !isInitialized {
            // Smart default: yesterday's weight > last entered > target weight > 70.0
            if authManager.currentUser != nil {
                if let current = getUserCurrentWeight(), current > 0 {
                    // Ensure current weight is within valid range
                    if current >= 30.0 && current <= 200.0 {
                        weightValue = current
                    } else {
                        // Fix invalid current weight
                        fixInvalidCurrentWeight()
                        weightValue = 70.0
                    }
                } else if let target = getUserTargetWeight(), target > 0 {
                    // Ensure target weight is within valid range
                    if target >= 30.0 && target <= 200.0 {
                        weightValue = target
                    } else {
                        weightValue = 70.0
                    }
                } else {
                    weightValue = 70.0
                }
            }
            isInitialized = true
        }
    }
    
    private func initializeTargetWeight() {
        if let target = authManager.currentUser?.targetWeight, target > 0 {
            targetWeightValue = target
        } else {
            targetWeightValue = 70.0 // Default target weight
        }
    }
    
    private func fixInvalidCurrentWeight() {
        guard let user = authManager.currentUser else { return }
        
        // Reset invalid current weight to a reasonable default
        if user.currentWeight < 30.0 || user.currentWeight > 200.0 {
            user.currentWeight = 70.0
            try? viewContext.save()
        }
    }
    
    private func getUserCurrentWeight() -> Double? {
        guard let current = authManager.currentUser?.currentWeight, current > 0 else {
            return nil
        }
        return current
    }
    
    private func getUserTargetWeight() -> Double? {
        guard let target = authManager.currentUser?.targetWeight, target > 0 else {
            return nil
        }
        return target
    }
    
    private func quickIncrease() {
        adjustWeight(0.1)
    }
    
    private func quickDecrease() {
        adjustWeight(-0.1)
    }
    
    private func startHoldIncrease() {
        isHoldingPlus = true
        holdTimer?.invalidate()
        
        var increment = 0.1
        var accelerationCount = 0
        
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            adjustWeight(increment)
            accelerationCount += 1
            
            // Exponential acceleration
            if accelerationCount % 10 == 0 {
                increment = min(increment * 1.5, 2.0)
            }
        }
    }
    
    private func startHoldDecrease() {
        isHoldingMinus = true
        holdTimer?.invalidate()
        
        var increment = 0.1
        var accelerationCount = 0
        
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            adjustWeight(-increment)
            accelerationCount += 1
            
            // Exponential acceleration
            if accelerationCount % 10 == 0 {
                increment = min(increment * 1.5, 2.0)
            }
        }
    }
    
    private func stopHolding() {
        isHoldingPlus = false
        isHoldingMinus = false
        holdTimer?.invalidate()
        holdTimer = nil
    }
    
    private func adjustWeight(_ amount: Double) {
        let newValue = weightValue + amount
        if newValue >= 30.0 && newValue <= 200.0 {
            weightValue = newValue
        }
    }
    
    private func saveWeight() {
        guard let user = authManager.currentUser else { return }
        
        // Validate weight is within acceptable range
        guard weightValue >= 30.0 && weightValue <= 200.0 else {
            // Reset to a valid value if somehow an invalid value got through
            weightValue = max(30.0, min(200.0, weightValue))
            return
        }
        
        // Update user's current weight only if it's today's entry
        let calendar = Calendar.current
        if calendar.isDate(selectedDate, inSameDayAs: Date()) {
            user.currentWeight = weightValue
            currentWeight = String(format: "%.1f", weightValue)
        }
        
        // Save to WeightLog entity
        let weightLog = WeightLog(context: viewContext)
        weightLog.weight = weightValue
        weightLog.date = selectedDate
        weightLog.user = user
        
        try? viewContext.save()
        
        // Reset the date to today and weight to a smart default for next entry
        selectedDate = Date()
        initializeWeight()
    }
    
    private var weightHistorySection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color.primaryPurple2)
                    .font(.title2)
                
                Text("Weight History")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if !weightLogs.isEmpty {
                    Text("\(weightLogs.count) entries")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.surfaceBackground)
                        .cornerRadius(8)
                }
            }
            
            if weightLogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.textSecondary)
                    
                    Text("No weight entries yet")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    Text("Start logging your weight to track progress!")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfaceBackground.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(weightLogs.enumerated()), id: \.element.objectID) { index, log in
                        WeightLogCard(
                            weightLog: log,
                            isLatest: index == 0,
                            previousWeight: index < weightLogs.count - 1 ? weightLogs[index + 1].weight : nil,
                            hasMultipleEntriesOnSameDay: hasMultipleEntriesOnSameDay(for: log),
                            targetWeight: authManager.currentUser?.targetWeight ?? 70.0,
                            onEdit: {
                                editingWeightLog = log
                                editWeight = log.weight
                                showingEditAlert = true
                            },
                            onDelete: {
                                editingWeightLog = log
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
    
    private func saveEditedWeight() {
        guard let log = editingWeightLog else { return }
        
        // Validate weight limits
        guard editWeight >= 30.0 && editWeight <= 200.0 else {
            editingWeightLog = nil
            return
        }
        
        log.weight = editWeight
        try? viewContext.save()
        editingWeightLog = nil
        
        // Update current weight if editing today's entry
        let calendar = Calendar.current
        if calendar.isDate(log.date ?? Date(), inSameDayAs: Date()) {
            authManager.currentUser?.currentWeight = editWeight
            currentWeight = String(format: "%.1f", editWeight)
            try? viewContext.save()
        }
    }
    
    private func deleteWeightLog() {
        guard let log = editingWeightLog else { return }
        viewContext.delete(log)
        try? viewContext.save()
        editingWeightLog = nil
    }
    
    private func hasMultipleEntriesOnSameDay(for log: WeightLog) -> Bool {
        guard let logDate = log.date else { return false }
        let calendar = Calendar.current
        
        let sameDayLogs = weightLogs.filter { otherLog in
            guard let otherDate = otherLog.date else { return false }
            return calendar.isDate(logDate, inSameDayAs: otherDate)
        }
        
        return sameDayLogs.count > 1
    }
    
    private var targetWeightSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(Color.accentTeal)
                    .font(.title2)
                
                Text("Target Weight")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
            }
            
            Button(action: { showingTargetWeightEdit = true }) {
                VStack(spacing: 8) {
                    Text("\(String(format: "%.1f", targetWeightValue)) kg")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.accentTeal)
                    
                    Text("Tap to update target")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfaceBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentTeal.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
        .alert("Update Target Weight", isPresented: $showingTargetWeightEdit) {
            TextField("Target Weight (30-200 kg)", value: $targetWeightValue, format: .number)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                updateTargetWeight()
            }
            .disabled(targetWeightValue < 30.0 || targetWeightValue > 200.0)
        } message: {
            Text("Enter your target weight (Range: 30-200 kg)")
        }
    }
    
    private func updateTargetWeight() {
        guard let user = authManager.currentUser else { return }
        guard targetWeightValue >= 30.0 && targetWeightValue <= 200.0 else {
            targetWeightValue = max(30.0, min(200.0, targetWeightValue))
            return
        }
        
        user.targetWeight = targetWeightValue
        targetWeight = String(format: "%.1f", targetWeightValue)
        try? viewContext.save()
    }
    
    private func cleanInvalidWeightLogs() {
        let invalidLogs = weightLogs.filter { log in
            log.weight < 30.0 || log.weight > 200.0
        }
        
        for log in invalidLogs {
            viewContext.delete(log)
        }
        
        if !invalidLogs.isEmpty {
            try? viewContext.save()
        }
    }
}

struct WeightLogCard: View {
    let weightLog: WeightLog
    let isLatest: Bool
    let previousWeight: Double?
    let hasMultipleEntriesOnSameDay: Bool
    let targetWeight: Double
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var formattedDate: String {
        guard let date = weightLog.date else { return "Unknown" }
        let formatter = DateFormatter()
        
        let calendar = Calendar.current
        var dateString: String
        
        if calendar.isDate(date, inSameDayAs: Date()) {
            dateString = "Today"
        } else if calendar.isDate(date, inSameDayAs: Date().addingTimeInterval(-24*60*60)) {
            dateString = "Yesterday"
        } else {
            formatter.dateStyle = .medium
            dateString = formatter.string(from: date)
        }
        
        // Add time if there are multiple entries on the same day
        if hasMultipleEntriesOnSameDay {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            dateString += " at \(timeFormatter.string(from: date))"
        }
        
        return dateString
    }
    
    private var weightChange: (amount: Double, isGoodProgress: Bool, isIncrease: Bool, isNeutral: Bool, noChange: Bool)? {
        guard let previous = previousWeight else { return nil }
        let change = weightLog.weight - previous
        let isIncrease = change > 0
        
        // Check if there's no change (same weight as previous)
        if abs(change) < 0.01 { // Consider changes less than 0.01kg as "no change"
            return (0.0, false, false, false, true)
        }
        
        // Determine if this change brings us closer to the target weight
        let currentWeight = weightLog.weight
        let previousDistanceFromTarget = abs(previous - targetWeight)
        let currentDistanceFromTarget = abs(currentWeight - targetWeight)
        
        var isGoodProgress = false
        var isNeutral = false
        
        // Check if we're getting closer to or farther from target
        if currentDistanceFromTarget < previousDistanceFromTarget {
            // Getting closer to target = good progress
            isGoodProgress = true
        } else if currentDistanceFromTarget > previousDistanceFromTarget {
            // Getting farther from target = bad progress
            isGoodProgress = false
        } else {
            // Same distance from target = neutral (shouldn't happen with weight change)
            isNeutral = true
        }
        
        return (abs(change), isGoodProgress, isIncrease, isNeutral, false)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    HStack(spacing: 4) {
                        Text(formattedDate)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        if hasMultipleEntriesOnSameDay {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundColor(Color.primaryPurple2)
                        }
                    }
                    
                    if isLatest {
                        Text("LATEST")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primaryPurple2)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Text("\(String(format: "%.1f", weightLog.weight)) kg")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primaryPurple2)
                    
                    if let change = weightChange {
                        if change.noChange {
                            // Show a dash for no change
                            HStack(spacing: 2) {
                                Image(systemName: "minus")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("0.0 kg")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                        } else {
                            let arrowColor: Color = {
                                if change.isNeutral {
                                    return .gray
                                } else {
                                    return change.isGoodProgress ? .green : .red
                                }
                            }()
                            
                            HStack(spacing: 2) {
                                Image(systemName: change.isIncrease ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                                    .foregroundColor(arrowColor)
                                
                                Text("\(String(format: "%.1f", change.amount)) kg")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(arrowColor)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(arrowColor.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(Color.textSecondary)
                        .padding(8)
                        .background(Circle().fill(Color.textSecondary.opacity(0.1)))
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Circle().fill(Color.red.opacity(0.1)))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isLatest ? Color.primaryPurple2.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
        .environmentObject(AuthenticationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
