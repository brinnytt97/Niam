import SwiftUI
import SwiftData
import Charts

enum TrackerSegment: String, CaseIterable {
    case meals = "Meals"
    case fasting = "Fasting"
    case hydration = "Hydration"
    case trends = "Trends"
}

struct TrackerTabView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedSegment: TrackerSegment = .meals
    @State private var trackerVM: TrackerViewModel?
    @State private var fastingVM: FastingViewModel?
    @State private var showingAddMeal = false
    @State private var showingProfile = false
    @State private var editingMeal: MealRecord?
    @State private var waterIntake: WaterIntake?
    @State private var drinkEntries: [DrinkEntry] = []
    @State private var timer: Timer?
    @StateObject private var healthKit = HealthKitService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header + Segment
                VStack(spacing: 12) {
                    HStack {
                        Text("Tracker")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                        if selectedSegment == .meals {
                            Button { showingAddMeal = true } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color(red: 0.95, green: 0.22, blue: 0.24))
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Segmented control
                    Picker("", selection: $selectedSegment) {
                        ForEach(TrackerSegment.allCases, id: \.self) { seg in
                            Text(seg.rawValue).tag(seg)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                }
                .padding(.top, 8)
                .padding(.bottom, 12)

                Divider()

                // MARK: - Segment Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedSegment {
                        case .meals:
                            mealsContent
                        case .fasting:
                            fastingContent
                        case .hydration:
                            hydrationContent
                        case .trends:
                            trendsContent
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(.white)
            .sheet(isPresented: $showingAddMeal) {
                AddMealRecordView { record in
                    trackerVM?.addRecord(record)
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(existingProfile: trackerVM?.profile) { profile in
                    trackerVM?.saveProfile(profile)
                }
            }
            .sheet(item: $editingMeal) { meal in
                AddMealRecordView(editingRecord: meal) { _ in
                    try? context.save()
                    trackerVM?.fetchData()
                }
            }
            .onAppear {
                if trackerVM == nil { trackerVM = TrackerViewModel(context: context) }
                if fastingVM == nil { fastingVM = FastingViewModel(context: context) }
                loadWaterIntake()
                loadDrinkEntries()
                startTimer()
                Task {
                    await healthKit.requestAuthorizationIfNeeded()
                    trackerVM?.exerciseCalories = healthKit.exerciseCaloriesToday
                }
            }
            .onDisappear { timer?.invalidate() }
        }
    }

    // ==========================================
    // MARK: - MEALS SEGMENT
    // ==========================================

    private var mealsContent: some View {
        Group {
            if let tvm = trackerVM {
                // Date picker
                datePicker(tvm)

                calorieCard(tvm)
                macroRow(tvm)

                // Quick log section
                quickLogSection(tvm)

                todayMeals(tvm)
            }
        }
    }

    // MARK: - Date Picker

    private func datePicker(_ vm: TrackerViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(-6...0, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: .now))!
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: vm.selectedDate)

                    Button {
                        vm.selectedDate = date
                        vm.fetchData()
                    } label: {
                        VStack(spacing: 4) {
                            Text(dayOfWeek(date))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(isSelected ? .white : .secondary)
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.subheadline.weight(isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .frame(width: 42, height: 52)
                        .background(isSelected ? Color(red: 0.95, green: 0.22, blue: 0.24) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                // Today button if not on today
                if !Calendar.current.isDateInToday(vm.selectedDate) {
                    Button {
                        vm.selectedDate = .now
                        vm.fetchData()
                    } label: {
                        Text("Today")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func dayOfWeek(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    // MARK: - Quick Log

    private func quickLogSection(_ vm: TrackerViewModel) -> some View {
        let recentMeals = recentUniqueMeals(vm)
        return Group {
            if !recentMeals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Log")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recentMeals, id: \.name) { meal in
                                Button {
                                    let newRecord = MealRecord(
                                        name: meal.name,
                                        mealType: meal.mealType,
                                        calories: meal.calories,
                                        protein: meal.protein,
                                        carbs: meal.carbs,
                                        fat: meal.fat
                                    )
                                    vm.addRecord(newRecord)
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(mealTypeEmoji(meal.mealType))
                                            .font(.caption)
                                        Text(meal.name)
                                            .font(.caption.weight(.medium))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }

    private func recentUniqueMeals(_ vm: TrackerViewModel) -> [MealRecord] {
        // Get unique meal names from last 7 days, excluding today
        let today = Calendar.current.startOfDay(for: .now)
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!

        var seen = Set<String>()
        return vm.records
            .filter { $0.date >= weekAgo && !Calendar.current.isDate($0.date, inSameDayAs: vm.selectedDate) }
            .filter { seen.insert($0.name).inserted }
            .prefix(8)
            .map { $0 }
    }

    // ==========================================
    // MARK: - FASTING SEGMENT
    // ==========================================

    private var fastingContent: some View {
        Group {
            if let fvm = fastingVM {
                fastingCard(fvm)

                // History
                if !fvm.history.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 24)

                        ForEach(fvm.history.prefix(10)) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(session.targetHours)h target")
                                        .font(.subheadline.weight(.medium))
                                    Text(session.startTime, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                let hours = Int(session.elapsedSeconds) / 3600
                                let minutes = (Int(session.elapsedSeconds) % 3600) / 60
                                Text("\(hours)h \(minutes)m")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(session.progress >= 1 ? .green : .orange)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // MARK: - HYDRATION SEGMENT
    // ==========================================

    private var hydrationContent: some View {
        VStack(spacing: 16) {
            hydrationCard
            drinkTypeCard
        }
    }

    // ==========================================
    // MARK: - TRENDS SEGMENT
    // ==========================================

    private var trendsContent: some View {
        Group {
            if let tvm = trackerVM {
                // Meal heatmap
                mealHeatmap(tvm)

                // Calorie trend
                weeklyChart(tvm)

                // Fasting trend
                if let fvm = fastingVM, !fvm.history.isEmpty {
                    fastingTrend(fvm)
                }

                // Hydration trend
                hydrationTrend
            }
        }
    }

    // MARK: - Meal Heatmap

    private func mealHeatmap(_ vm: TrackerViewModel) -> some View {
        // Build 12-week grid (84 days), Mon–Sun columns
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Align to the start of the current week (Monday)
        let weekday = calendar.component(.weekday, from: today) // 1=Sun ... 7=Sat
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
        let currentWeekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!
        let gridStart = calendar.date(byAdding: .weekOfYear, value: -11, to: currentWeekStart)!

        // Filter records in that range from the already-fetched array
        let allRecords = vm.records.filter { $0.date >= gridStart }

        // Build day→calories map
        var caloriesByDay: [Date: Int] = [:]
        for record in allRecords {
            let day = calendar.startOfDay(for: record.date)
            caloriesByDay[day, default: 0] += record.calories
        }

        let maxCal = caloriesByDay.values.max() ?? 1

        // 12 weeks × 7 days
        let weeks = (0..<12).map { weekOffset -> [Date?] in
            let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: gridStart)!
            return (0..<7).map { dayOffset in
                calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
            }
        }

        let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Meal Activity")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("12 weeks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 4) {
                // Day-of-week labels
                VStack(spacing: 3) {
                    ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .frame(width: 12, height: 12)
                    }
                }

                // Week columns
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        ForEach(Array(weeks.enumerated()), id: \.offset) { weekIdx, days in
                            VStack(spacing: 3) {
                                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                                    if let date = date {
                                        let cal = caloriesByDay[date] ?? 0
                                        let isFuture = date > today
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(isFuture
                                                ? Color(.systemGray6)
                                                : heatmapColor(calories: cal, maxCalories: maxCal))
                                            .frame(width: 12, height: 12)
                                    } else {
                                        Color.clear.frame(width: 12, height: 12)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 6) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColor(intensity: intensity))
                        .frame(width: 12, height: 12)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    private func heatmapColor(calories: Int, maxCalories: Int) -> Color {
        guard calories > 0 else { return Color(.systemGray6) }
        let intensity = Double(calories) / Double(max(1, maxCalories))
        return heatmapColor(intensity: intensity)
    }

    private func heatmapColor(intensity: Double) -> Color {
        guard intensity > 0 else { return Color(.systemGray6) }
        // Orange gradient from light to saturated
        return Color(
            red: 0.95,
            green: max(0.3, 0.85 - intensity * 0.5),
            blue: max(0.1, 0.6 - intensity * 0.55)
        ).opacity(0.3 + intensity * 0.7)
    }

    // MARK: - Fasting Trend

    private func fastingTrend(_ vm: FastingViewModel) -> some View {
        let recentSessions = Array(vm.history.prefix(7))
        let streak = vm.history.prefix(while: { $0.progress >= 1.0 }).count

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fasting")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(streak) day streak")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Recent sessions as horizontal bars
            ForEach(recentSessions) { session in
                HStack(spacing: 10) {
                    Text(shortDate(session.startTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(session.progress >= 1.0 ? .green : .orange)
                                .frame(width: geo.size.width * min(1.0, session.progress), height: 8)
                        }
                    }
                    .frame(height: 8)

                    let hours = Int(session.elapsedSeconds) / 3600
                    Text("\(hours)h")
                        .font(.caption.weight(.medium))
                        .frame(width: 30, alignment: .trailing)
                        .foregroundStyle(session.progress >= 1.0 ? .green : .secondary)
                }
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    // MARK: - Hydration Trend

    private var hydrationTrend: some View {
        let weekData = loadWeeklyWater()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Hydration")
                .font(.subheadline.weight(.semibold))

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weekData, id: \.date) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(day.count >= day.target ? Color(red: 0.4, green: 0.7, blue: 1) : Color(red: 0.4, green: 0.7, blue: 1).opacity(0.3))
                            .frame(width: 28, height: max(8, CGFloat(day.count) / CGFloat(max(1, day.target)) * 60))

                        Text(shortDayOfWeek(day.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    private struct DailyWater {
        let date: Date
        let count: Int
        let target: Int
    }

    private func loadWeeklyWater() -> [DailyWater] {
        let descriptor = FetchDescriptor<WaterIntake>()
        let all = (try? context.fetch(descriptor)) ?? []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<7).reversed().compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            let intake = all.first { calendar.isDate($0.date, inSameDayAs: date) }
            return DailyWater(date: date, count: intake?.count ?? 0, target: intake?.target ?? 8)
        }
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: date)
    }

    private func shortDayOfWeek(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f.string(from: date)
    }

    // ==========================================
    // MARK: - Calorie Card
    // ==========================================

    private func calorieCard(_ vm: TrackerViewModel) -> some View {
        let isOver = vm.totalCaloriesToday > vm.adjustedTarget
        let progress = Double(vm.totalCaloriesToday) / Double(max(1, vm.adjustedTarget))

        return VStack(alignment: .leading, spacing: 12) {
            Text("Calories")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(vm.totalCaloriesToday)")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.22, blue: 0.24))
                    .contentTransition(.numericText())
                Text("/ \(vm.adjustedTarget) kcal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOver ? Color.red : Color.green)
                        .frame(width: min(geo.size.width, geo.size.width * progress), height: 8)
                }
            }
            .frame(height: 8)

            // Exercise bonus row
            if vm.exerciseCalories > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "figure.run")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text("+\(vm.exerciseCalories) kcal from exercise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(vm.dailyTarget) base")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    // MARK: - Macros

    private func macroRow(_ vm: TrackerViewModel) -> some View {
        HStack(spacing: 0) {
            macroItem("Protein", value: "\(Int(vm.macros.protein))g", color: Color(red: 0.9, green: 0.35, blue: 0.35))
            macroItem("Carbs", value: "\(Int(vm.macros.carbs))g", color: Color(red: 0.3, green: 0.55, blue: 0.95))
            macroItem("Fat", value: "\(Int(vm.macros.fat))g", color: Color(red: 0.95, green: 0.75, blue: 0.2))
        }
        .padding(.vertical, 16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    private func macroItem(_ name: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    // ==========================================
    // MARK: - Fasting Card (Circular Timer)
    // ==========================================

    private func fastingCard(_ vm: FastingViewModel) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Intermittent Fasting")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.gray)
                Spacer()
                if !vm.isActive {
                    Stepper("", value: Bindable(vm).targetHours, in: 1...48)
                        .labelsHidden()
                    Text("\(vm.targetHours)h")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.gray)
                        .frame(width: 30)
                }
            }

            // Circular ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 16)
                    .frame(width: 200, height: 200)

                // Milestone dots (8h, 13h, 16h, 18h, 20h)
                ForEach([8, 13, 16, 18, 20], id: \.self) { milestone in
                    let milestoneAngle = Double(milestone) / Double(max(1, vm.targetHours)) * 360.0 - 90
                    let reached = vm.progress * Double(vm.targetHours) * 3600 >= Double(milestone) * 3600
                    Circle()
                        .fill(reached ? Color.green : Color.white.opacity(0.25))
                        .frame(width: 8, height: 8)
                        .offset(y: -100)
                        .rotationEffect(.degrees(milestoneAngle))
                }

                // Progress arc
                Circle()
                    .trim(from: 0, to: vm.progress)
                    .stroke(
                        LinearGradient(
                            colors: vm.progress >= 1.0
                                ? [.green, .green]
                                : [Color.orange, Color(red: 1, green: 0.6, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: vm.progress)

                // Center text
                VStack(spacing: 4) {
                    Text(vm.elapsedFormatted)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                    if vm.isActive {
                        Text("of \(vm.targetHours)h")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else if vm.progress == 0 {
                        Text("Ready")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else {
                        Text("Complete!")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
            }

            // Remaining label
            if vm.isActive {
                Text("Remaining: \(vm.remainingFormatted)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            // Preset chips + Start/End
            HStack {
                if !vm.isActive {
                    ForEach([13, 16, 18, 20], id: \.self) { h in
                        Button("\(h)h") { vm.targetHours = h }
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(vm.targetHours == h ? .white.opacity(0.2) : .white.opacity(0.08))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                Button {
                    if vm.isActive { vm.stopFasting() } else { vm.startFasting() }
                } label: {
                    Text(vm.isActive ? "End Fast" : "Start Fast")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(vm.isActive ? Color.red : Color.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: vm.isActive)
            }
        }
        .padding(20)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }

    // ==========================================
    // MARK: - Hydration Card (Circular)
    // ==========================================

    private var hydrationCard: some View {
        let count = waterIntake?.count ?? 0
        let target = waterIntake?.target ?? 8
        let progress = Double(count) / Double(max(1, target))
        let totalCaffeine = drinkEntries
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.type.caffeineMg }

        return VStack(spacing: 16) {
            HStack {
                Text("Hydration")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                // Target stepper
                HStack(spacing: 4) {
                    Button { updateWaterTarget(target - 1) } label: {
                        Image(systemName: "minus")
                            .font(.caption2)
                            .frame(width: 24, height: 24)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Text("Goal: \(target)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Button { updateWaterTarget(target + 1) } label: {
                        Image(systemName: "plus")
                            .font(.caption2)
                            .frame(width: 24, height: 24)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Circular ring
            ZStack {
                Circle()
                    .stroke(Color(red: 0.4, green: 0.7, blue: 1).opacity(0.15), lineWidth: 16)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: min(1.0, progress))
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 0.3, green: 0.6, blue: 1), Color(red: 0.5, green: 0.85, blue: 1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: count)

                VStack(spacing: 2) {
                    Text("\(count)")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(Color(red: 0.3, green: 0.6, blue: 1))
                        .contentTransition(.numericText())
                    Text("/ \(target) glasses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: count)

            // Glass tap row
            HStack(spacing: 6) {
                ForEach(0..<min(target, 10), id: \.self) { i in
                    let filled = i < count
                    Text("💧")
                        .font(.title3)
                        .opacity(filled ? 1.0 : 0.25)
                        .onTapGesture {
                            updateWater(to: filled ? i : i + 1)
                        }
                }
                if target > 10 {
                    Text("+\(target - 10)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Caffeine summary
            if totalCaffeine > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(totalCaffeine) mg caffeine today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    // MARK: - Drink Type Card

    private var drinkTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log a Drink")
                .font(.subheadline.weight(.semibold))

            // Drink type chips
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(DrinkType.allCases, id: \.self) { type in
                    Button {
                        logDrink(type)
                    } label: {
                        VStack(spacing: 4) {
                            Text(type.emoji)
                                .font(.title2)
                            Text(type.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            if type.caffeineMg > 0 {
                                Text("\(type.caffeineMg)mg")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Today's drink log
            let todayDrinks = drinkEntries.filter { Calendar.current.isDateInToday($0.date) }
            if !todayDrinks.isEmpty {
                Divider()
                Text("Today")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(todayDrinks) { entry in
                            HStack(spacing: 4) {
                                Text(entry.type.emoji)
                                Text(entry.type.rawValue)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteDrink(entry)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    private func updateWater(to count: Int) {
        let clamped = max(0, count)
        if let intake = waterIntake {
            intake.count = clamped
        } else {
            let intake = WaterIntake(count: clamped)
            context.insert(intake)
            waterIntake = intake
        }
        try? context.save()
    }

    private func updateWaterTarget(_ newTarget: Int) {
        let clamped = max(1, min(20, newTarget))
        if let intake = waterIntake {
            intake.target = clamped
        } else {
            let intake = WaterIntake(count: 0, target: clamped)
            context.insert(intake)
            waterIntake = intake
        }
        try? context.save()
    }

    private func logDrink(_ type: DrinkType) {
        let entry = DrinkEntry(drinkType: type)
        context.insert(entry)
        try? context.save()
        // If it counts as water, also increment the water counter
        if type.countsAsWater {
            updateWater(to: (waterIntake?.count ?? 0) + 1)
        }
        loadDrinkEntries()
    }

    private func deleteDrink(_ entry: DrinkEntry) {
        // If it counted as water, decrement
        if entry.type.countsAsWater {
            updateWater(to: max(0, (waterIntake?.count ?? 1) - 1))
        }
        context.delete(entry)
        try? context.save()
        loadDrinkEntries()
    }

    private func loadWaterIntake() {
        let today = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<WaterIntake>()
        let all = (try? context.fetch(descriptor)) ?? []
        waterIntake = all.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private func loadDrinkEntries() {
        let descriptor = FetchDescriptor<DrinkEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        drinkEntries = (try? context.fetch(descriptor)) ?? []
    }

    // ==========================================
    // MARK: - Weekly Chart
    // ==========================================

    private func weeklyChart(_ vm: TrackerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calorie Trend")
                .font(.subheadline.weight(.semibold))

            Chart {
                ForEach(vm.weeklyData) { day in
                    BarMark(
                        x: .value("Day", day.dayLabel),
                        y: .value("Calories", day.calories)
                    )
                    .foregroundStyle(day.calories > day.target ? .red : .orange)
                    .cornerRadius(4)
                }

                if let target = vm.weeklyData.first?.target, target > 0 {
                    RuleMark(y: .value("Target", target))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .foregroundStyle(.green.opacity(0.6))
                }
            }
            .frame(height: 160)
            .chartYAxisLabel("kcal")
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    // ==========================================
    // MARK: - Today's Meals
    // ==========================================

    private func todayMeals(_ vm: TrackerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Meals")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if !vm.todayRecords.isEmpty {
                    Text("\(vm.todayRecords.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)

            if vm.todayRecords.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 32))
                        .foregroundStyle(.gray.opacity(0.3))
                    Text("No meals recorded yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        showingAddMeal = true
                    } label: {
                        Text("Log your first meal")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.95, green: 0.22, blue: 0.24))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else {
                // Grouped by meal type
                ForEach(MealType.allCases, id: \.self) { type in
                    let meals = vm.todayRecords.filter { $0.mealType == type }
                    if !meals.isEmpty {
                        mealGroup(type: type, meals: meals)
                    }
                }
            }
        }
    }

    private func mealGroup(type: MealType, meals: [MealRecord]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Group header
            HStack(spacing: 6) {
                Text(mealTypeEmoji(type))
                    .font(.caption)
                Text(type.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                let total = meals.reduce(0) { $0 + $1.calories }
                Text("\(total) kcal")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            // Meal rows
            ForEach(meals) { record in
                HStack(spacing: 12) {
                    Circle()
                        .fill(mealTypeColor(record.mealType))
                        .frame(width: 8, height: 8)

                    Text(record.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)

                    Spacer()

                    Text("\(record.calories) kcal")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.gray.opacity(0.4))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture { editingMeal = record }
            }
        }
        .padding(.vertical, 4)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    private func mealTypeEmoji(_ type: MealType) -> String {
        switch type {
        case .breakfast: "🌅"
        case .lunch: "☀️"
        case .dinner: "🌙"
        case .snack: "🍪"
        }
    }

    private func mealTypeColor(_ type: MealType) -> Color {
        switch type {
        case .breakfast: Color(red: 1, green: 0.7, blue: 0.3)
        case .lunch: Color(red: 0.3, green: 0.8, blue: 0.4)
        case .dinner: Color(red: 0.4, green: 0.5, blue: 0.9)
        case .snack: Color(red: 0.9, green: 0.5, blue: 0.7)
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            fastingVM?.fetchData()
        }
    }
}
