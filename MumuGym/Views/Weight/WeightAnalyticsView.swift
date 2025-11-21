import SwiftUI
import CoreData

struct WeightAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @FetchRequest var weightLogs: FetchedResults<WeightLog>
    
    @State private var selectedTimeRange: TimeRange = .threeMonths
    @State private var showingWeightEntry = false
    
    enum TimeRange: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M" 
        case sixMonths = "6M"
        case oneYear = "1Y"
        case all = "All"
        
        var title: String {
            switch self {
            case .oneMonth: return "Last Month"
            case .threeMonths: return "Last 3 Months"
            case .sixMonths: return "Last 6 Months" 
            case .oneYear: return "Last Year"
            case .all: return "All Time"
            }
        }
        
        var days: Int {
            switch self {
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            case .all: return 3650
            }
        }
    }
    
    init() {
        _weightLogs = FetchRequest(
            entity: WeightLog.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \WeightLog.date, ascending: true)]
        )
    }
    
    private var filteredWeightLogs: [WeightLog] {
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: now) ?? now
        
        return weightLogs.filter { log in
            guard let date = log.date else { return false }
            return date >= cutoffDate
        }
    }
    
    private var weightStats: WeightStatistics {
        return WeightStatistics(logs: Array(weightLogs), targetWeight: authManager.currentUser?.targetWeight ?? 70.0)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    timeRangeSelector
                    
                    if filteredWeightLogs.isEmpty {
                        emptyStateView
                    } else {
                        weightChartSection
                        statisticsSection
                        trendsSection
                        goalsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("Weight Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryOrange1)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Entry") {
                        showingWeightEntry = true
                    }
                    .foregroundColor(.textPrimary)
                    .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntryView(currentWeight: .constant(""), targetWeight: .constant(""))
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight Analytics")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Track your progress")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.purpleGradient)
                .shadow(color: Color.shadowMedium, radius: 10, x: 0, y: 5)
        )
    }
    
    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: { selectedTimeRange = range }) {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedTimeRange == range ? .white : .textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTimeRange == range ? Color.primaryPurple2 : Color.surfaceBackground)
                                    .shadow(color: selectedTimeRange == range ? Color.shadowMedium : Color.clear, radius: 4, x: 0, y: 2)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var weightChartSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(Color.primaryPurple1)
                    .font(.title2)
                
                Text("Weight Progress")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text(selectedTimeRange.title)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.surfaceBackground)
                    .cornerRadius(8)
            }
            
            // Custom Weight Progress Chart
            WeightProgressChart(weightLogs: filteredWeightLogs, targetWeight: authManager.currentUser?.targetWeight ?? 70.0)
                .frame(height: 200)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(Color.primaryOrange2)
                    .font(.title2)
                
                Text("Statistics")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    title: "Current",
                    value: "\(String(format: "%.1f", weightStats.currentWeight)) kg",
                    icon: "scalemass.fill",
                    color: .primaryOrange1
                )
                
                StatCard(
                    title: "Target",
                    value: "\(String(format: "%.1f", weightStats.targetWeight)) kg",
                    icon: "target",
                    color: .accentTeal
                )
                
                StatCard(
                    title: "Total Change",
                    value: "\(weightStats.totalChange >= 0 ? "+" : "")\(String(format: "%.1f", weightStats.totalChange)) kg",
                    icon: weightStats.totalChange >= 0 ? "arrow.up" : "arrow.down",
                    color: weightStats.totalChange >= 0 ? .red : .green
                )
                
                StatCard(
                    title: "To Goal",
                    value: "\(String(format: "%.1f", abs(weightStats.remainingToGoal))) kg",
                    icon: "flag.fill",
                    color: .primaryOrange2
                )
                
                StatCard(
                    title: "Entries",
                    value: "\(weightStats.totalEntries)",
                    icon: "list.bullet",
                    color: .accentTeal
                )
                
                StatCard(
                    title: "Average",
                    value: "\(String(format: "%.1f", weightStats.averageWeight)) kg",
                    icon: "chart.bar.fill",
                    color: .primaryOrange1
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
    
    private var trendsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .foregroundColor(Color.accentTeal)
                    .font(.title2)
                
                Text("Trends & Insights")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                TrendCard(
                    title: "Weekly Average",
                    value: "\(String(format: "%.1f", weightStats.weeklyAverage)) kg/week",
                    trend: weightStats.weeklyTrend,
                    icon: "calendar.badge.clock"
                )
                
                TrendCard(
                    title: "Best Streak",
                    value: "\(weightStats.bestStreak) days",
                    trend: .stable,
                    icon: "flame.fill"
                )
                
                TrendCard(
                    title: "Progress Rate",
                    value: weightStats.progressPercentage,
                    trend: weightStats.overallTrend,
                    icon: "percent"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
    
    private var goalsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(Color.primaryOrange2)
                    .font(.title2)
                
                Text("Goals & Milestones")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                GoalCard(
                    title: "Target Achievement",
                    progress: weightStats.goalProgress,
                    description: weightStats.goalDescription
                )
                
                if weightStats.milestones.count > 0 {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Recent Milestones")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textSecondary)
                            Spacer()
                        }
                        
                        ForEach(weightStats.milestones.prefix(3), id: \.title) { milestone in
                            MilestoneRow(milestone: milestone)
                        }
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
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundColor(.textSecondary)
                
                Text("No Weight Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Start logging your weight to see analytics and track your progress")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { showingWeightEntry = true }) {
                Text("Log First Entry")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.purpleGradient)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct TrendCard: View {
    let title: String
    let value: String
    let trend: WeightStatistics.Trend
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentTeal)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
                
                Text(trend.description)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(trend.color.opacity(0.1))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceBackground)
        )
    }
}

struct GoalCard: View {
    let title: String
    let progress: Double
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryPurple2)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.primaryPurple2))
                .scaleEffect(x: 1, y: 2)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primaryPurple1.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct MilestoneRow: View {
    let milestone: WeightStatistics.Milestone
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: milestone.icon)
                .font(.title3)
                .foregroundColor(.primaryOrange2)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Text(milestone.date)
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.surfaceBackground.opacity(0.5))
        )
    }
}

// MARK: - Custom Weight Chart

struct WeightProgressChart: View {
    let weightLogs: [WeightLog]
    let targetWeight: Double
    
    private let chartHeight: CGFloat = 180
    private let chartPadding: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let chartWidth = geometry.size.width - (chartPadding * 2)
            let chartRect = CGRect(x: chartPadding, y: 10, width: chartWidth, height: chartHeight - 20)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfaceBackground.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primaryPurple1.opacity(0.2), lineWidth: 1)
                    )
                
                if weightLogs.count >= 2 {
                    VStack(spacing: 0) {
                        chartContent(chartRect: chartRect)
                        chartLabels(chartWidth: chartWidth)
                    }
                    .padding(chartPadding)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.largeTitle)
                            .foregroundColor(.textSecondary.opacity(0.6))
                        
                        Text("Need more data points")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        Text("At least 2 weight entries required for chart")
                            .font(.caption)
                            .foregroundColor(.textSecondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
    
    private func chartContent(chartRect: CGRect) -> some View {
        let sortedLogs = weightLogs.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
        let weights = sortedLogs.map { $0.weight }
        
        guard let minWeight = weights.min(), let maxWeight = weights.max(), maxWeight > minWeight else {
            return AnyView(EmptyView())
        }
        
        let weightRange = maxWeight - minWeight
        let adjustedRange = max(weightRange, 2.0) // Minimum range of 2kg for better visualization
        let chartMinWeight = minWeight - (adjustedRange * 0.1)
        let chartMaxWeight = maxWeight + (adjustedRange * 0.1)
        let finalRange = chartMaxWeight - chartMinWeight
        
        return AnyView(
            ZStack {
                // Background grid lines
                VStack {
                    ForEach(0..<5) { i in
                        Rectangle()
                            .fill(Color.textSecondary.opacity(0.1))
                            .frame(height: 0.5)
                        if i < 4 { Spacer() }
                    }
                }
                .frame(height: chartRect.height)
                
                // Target weight line
                if targetWeight >= chartMinWeight && targetWeight <= chartMaxWeight {
                    let targetY = chartRect.height - ((targetWeight - chartMinWeight) / finalRange) * chartRect.height
                    
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: targetY))
                        path.addLine(to: CGPoint(x: chartRect.width, y: targetY))
                    }
                    .stroke(Color.primaryPurple2.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    HStack {
                        Spacer()
                        Text("Target: \(String(format: "%.1f", targetWeight)) kg")
                            .font(.caption2)
                            .foregroundColor(.primaryPurple2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primaryPurple2.opacity(0.1))
                            )
                            .offset(y: targetY - 10)
                    }
                }
                
                // Weight progression line
                Path { path in
                    for (index, log) in sortedLogs.enumerated() {
                        let x = (CGFloat(index) / CGFloat(max(sortedLogs.count - 1, 1))) * chartRect.width
                        let y = chartRect.height - ((log.weight - chartMinWeight) / finalRange) * chartRect.height
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primaryPurple1, Color.primaryPurple2]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
                // Data points
                ForEach(Array(sortedLogs.enumerated()), id: \.offset) { index, log in
                    let x = (CGFloat(index) / CGFloat(max(sortedLogs.count - 1, 1))) * chartRect.width
                    let y = chartRect.height - ((log.weight - chartMinWeight) / finalRange) * chartRect.height
                    
                    Circle()
                        .fill(Color.primaryPurple2)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                        .shadow(color: Color.primaryPurple2.opacity(0.4), radius: 2)
                }
            }
        )
    }
    
    @ViewBuilder
    private func chartLabels(chartWidth: CGFloat) -> some View {
        let sortedLogs = weightLogs.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
        
        if sortedLogs.count >= 2 {
            HStack {
                // Start date
                if let firstDate = sortedLogs.first?.date {
                    Text(formatDate(firstDate))
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // End date  
                if let lastDate = sortedLogs.last?.date {
                    Text(formatDate(lastDate))
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Weight Statistics

struct WeightStatistics {
    let logs: [WeightLog]
    private let targetWeightValue: Double
    
    enum Trend {
        case improving
        case declining
        case stable
        
        var icon: String {
            switch self {
            case .improving: return "arrow.up.circle.fill"
            case .declining: return "arrow.down.circle.fill"
            case .stable: return "minus.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .improving: return .green
            case .declining: return .red
            case .stable: return .gray
            }
        }
        
        var description: String {
            switch self {
            case .improving: return "Good"
            case .declining: return "Needs Work"
            case .stable: return "Stable"
            }
        }
    }
    
    struct Milestone {
        let title: String
        let description: String
        let date: String
        let icon: String
    }
    
    init(logs: [WeightLog], targetWeight: Double) {
        self.logs = logs.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
        self.targetWeightValue = targetWeight
    }
    
    var totalEntries: Int {
        logs.count
    }
    
    var currentWeight: Double {
        logs.last?.weight ?? 0
    }
    
    var startWeight: Double {
        logs.first?.weight ?? 0
    }
    
    var targetWeight: Double {
        return targetWeightValue
    }
    
    var averageWeight: Double {
        guard !logs.isEmpty else { return 0 }
        return logs.reduce(0) { $0 + $1.weight } / Double(logs.count)
    }
    
    var totalChange: Double {
        guard logs.count > 1 else { return 0 }
        return currentWeight - startWeight
    }
    
    var remainingToGoal: Double {
        return targetWeight - currentWeight
    }
    
    var weeklyAverage: Double {
        guard logs.count > 7 else { return 0 }
        let recentLogs = Array(logs.suffix(7))
        let weekChange = recentLogs.last!.weight - recentLogs.first!.weight
        return weekChange
    }
    
    var weeklyTrend: Trend {
        let change = weeklyAverage
        if abs(change) < 0.1 { return .stable }
        return change < 0 ? .improving : .declining
    }
    
    var overallTrend: Trend {
        let change = totalChange
        if abs(change) < 0.5 { return .stable }
        // Assuming weight loss is the goal
        return change < 0 ? .improving : .declining
    }
    
    var bestStreak: Int {
        // Calculate consecutive days of progress
        guard logs.count > 1 else { return 0 }
        
        var currentStreak = 0
        var maxStreak = 0
        
        for i in 1..<logs.count {
            if logs[i].weight < logs[i-1].weight {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
    
    var goalProgress: Double {
        guard startWeight != targetWeight else { return 1.0 }
        let totalNeeded = abs(targetWeight - startWeight)
        let achieved = abs(currentWeight - startWeight)
        return min(achieved / totalNeeded, 1.0)
    }
    
    var goalDescription: String {
        let remaining = abs(remainingToGoal)
        if remaining < 0.5 {
            return "Almost there! You're very close to your goal."
        } else if goalProgress > 0.8 {
            return "\(String(format: "%.1f", remaining)) kg to go. You're doing great!"
        } else if goalProgress > 0.5 {
            return "\(String(format: "%.1f", remaining)) kg remaining. Keep up the good work!"
        } else {
            return "\(String(format: "%.1f", remaining)) kg to go. Stay consistent!"
        }
    }
    
    var progressPercentage: String {
        return "\(Int(goalProgress * 100))% complete"
    }
    
    var milestones: [Milestone] {
        var milestones: [Milestone] = []
        
        // First entry milestone
        if let firstLog = logs.first, let firstDate = firstLog.date {
            milestones.append(Milestone(
                title: "First Entry",
                description: "Started weight tracking",
                date: DateFormatter().string(from: firstDate),
                icon: "star.fill"
            ))
        }
        
        // Weight loss milestones
        let weightLoss = abs(totalChange)
        if weightLoss >= 1.0 {
            milestones.append(Milestone(
                title: "Lost \(Int(weightLoss)) kg",
                description: "Great progress on your journey",
                date: "Recent",
                icon: "trophy.fill"
            ))
        }
        
        // Consistency milestone
        if logs.count >= 10 {
            milestones.append(Milestone(
                title: "10+ Entries",
                description: "Building a great tracking habit",
                date: "Ongoing",
                icon: "checkmark.circle.fill"
            ))
        }
        
        return milestones
    }
}

#Preview {
    WeightAnalyticsView()
        .environmentObject(AuthenticationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
