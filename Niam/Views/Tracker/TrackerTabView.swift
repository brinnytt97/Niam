import SwiftUI
import SwiftData
import Charts

struct TrackerTabView: View {
    @Environment(\.modelContext) private var context
    @State private var trackerVM: TrackerViewModel?
    @State private var fastingVM: FastingViewModel?
    @State private var showingAddMeal = false
    @State private var showingProfile = false
    @State private var editingMeal: MealRecord?
    @State private var waterIntake: WaterIntake?
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Title
                    HStack {
                        Text("Tracker")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                        Button { showingAddMeal = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color(red: 0.95, green: 0.22, blue: 0.24))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    if let tvm = trackerVM {
                        // MARK: - Calorie Card
                        calorieCard(tvm)

                        // MARK: - Macros
                        macroRow(tvm)

                        // MARK: - Fasting Card
                        if let fvm = fastingVM {
                            fastingCard(fvm)
                        }

                        // MARK: - Water
                        waterCard

                        // MARK: - Weekly Chart
                        weeklyChart(tvm)

                        // MARK: - Today's Meals
                        todayMeals(tvm)
                    }
                }
                .padding(.bottom, 20)
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
                if fastingVM == nil {
                    fastingVM = FastingViewModel(context: context)
                }
                loadWaterIntake()
                startTimer()
            }
            .onDisappear { timer?.invalidate() }
        }
    }

    // MARK: - Calorie Card

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

            // Progress bar
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

    // MARK: - Fasting Card (Dark)

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

            // Progress bar
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

            // Quick presets + button
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

    // MARK: - Water Card

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

    // MARK: - Weekly Chart

    private func weeklyChart(_ vm: TrackerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trend")
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
            .frame(height: 120)
            .chartYAxisLabel("kcal")
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    // MARK: - Today's Meals

    private func todayMeals(_ vm: TrackerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Meals")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 24)

            if vm.todayRecords.isEmpty {
                Text("No meals recorded yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            } else {
                ForEach(vm.todayRecords) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.name)
                                .font(.subheadline.weight(.medium))
                            Text(record.mealType.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(record.calories) kcal")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.orange)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.gray.opacity(0.4))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .onTapGesture { editingMeal = record }
                }
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            fastingVM?.fetchData()
        }
    }
}
