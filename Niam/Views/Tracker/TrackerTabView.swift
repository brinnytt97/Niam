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
    @State private var timer: Timer?

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
                startTimer()
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
                calorieCard(tvm)
                macroRow(tvm)
                todayMeals(tvm)
            }
        }
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
            waterCard
        }
    }

    // ==========================================
    // MARK: - TRENDS SEGMENT
    // ==========================================

    private var trendsContent: some View {
        Group {
            if let tvm = trackerVM {
                weeklyChart(tvm)
            }
        }
    }

    // ==========================================
    // MARK: - Calorie Card
    // ==========================================

    private func calorieCard(_ vm: TrackerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calories")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(vm.totalCaloriesToday)")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.22, blue: 0.24))
                Text("/ \(vm.dailyTarget) kcal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(vm.totalCaloriesToday > vm.dailyTarget ? .red : .green)
                        .frame(width: min(geo.size.width, geo.size.width * Double(vm.totalCaloriesToday) / Double(max(1, vm.dailyTarget))), height: 8)
                }
            }
            .frame(height: 8)
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
    // MARK: - Fasting Card (Dark)
    // ==========================================

    private func fastingCard(_ vm: FastingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Intermittent Fasting")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.gray)
                Spacer()
                if !vm.isActive {
                    Stepper("\(vm.targetHours)h", value: Bindable(vm).targetHours, in: 1...48)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.gray)
                        .labelsHidden()
                    Text("\(vm.targetHours)h")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.gray)
                }
            }

            Text(vm.elapsedFormatted)
                .font(.system(size: 38, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            if vm.isActive {
                Text("Target: \(vm.targetHours)h · Remaining: \(vm.remainingFormatted)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * vm.progress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                if !vm.isActive {
                    ForEach([13, 16, 18, 20], id: \.self) { h in
                        Button("\(h)h") {
                            vm.targetHours = h
                        }
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
                    Text(vm.isActive ? "End" : "Start")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(vm.isActive ? .red : .green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }

    // ==========================================
    // MARK: - Water Card
    // ==========================================

    private var waterCard: some View {
        let count = waterIntake?.count ?? 0
        let target = waterIntake?.target ?? 8

        return VStack(alignment: .leading, spacing: 12) {
            Text("Water Intake 💧")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                ForEach(0..<target, id: \.self) { i in
                    Circle()
                        .fill(i < count ? Color(red: 0.4, green: 0.7, blue: 1) : Color(.systemGray5))
                        .frame(width: 32, height: 32)
                        .onTapGesture {
                            updateWater(to: i < count ? i : i + 1)
                        }
                }
            }

            Text("\(count) / \(target) glasses")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    private func updateWater(to count: Int) {
        if let intake = waterIntake {
            intake.count = count
        } else {
            let intake = WaterIntake(count: count)
            context.insert(intake)
            waterIntake = intake
        }
        try? context.save()
    }

    private func loadWaterIntake() {
        let today = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<WaterIntake>()
        let all = (try? context.fetch(descriptor)) ?? []
        waterIntake = all.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
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
