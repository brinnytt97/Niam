import SwiftUI
import SwiftData
import AuthenticationServices

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var displayName = ""
    @State private var sex: BiologicalSex = .male
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var birthYear: Int = 2000
    @State private var activity: ActivityLevel = .moderate
    @State private var goal: DietGoal = .maintain

    var onComplete: () -> Void

    private let totalSteps = 8

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            if step > 0 && step < totalSteps - 1 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 3)
                        Rectangle()
                            .fill(Color(red: 0.95, green: 0.22, blue: 0.24))
                            .frame(width: geo.size.width * Double(step) / Double(totalSteps - 2), height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.top, 8)
            }

            // Step content
            Group {
                switch step {
                case 0: welcomeStep
                case 1: genderStep
                case 2: heightStep
                case 3: weightStep
                case 4: birthYearStep
                case 5: activityStep
                case 6: goalStep
                case 7: doneStep
                default: EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: step)

            Spacer()
        }
        .background(.white)
    }

    // MARK: - Step 0: Welcome + Name

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer().frame(height: 60)

            Text("Welcome to Niam!")
                .font(.system(size: 32, weight: .bold))

            Text("What should we call you?")
                .font(.body)
                .foregroundStyle(.secondary)

            // Name input with shuffle button
            HStack(spacing: 12) {
                TextField("Your name", text: $displayName)
                    .font(.title3)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    displayName = funNames.randomElement() ?? "Chef"
                } label: {
                    Image(systemName: "shuffle")
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .frame(width: 52, height: 52)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 8)

            Spacer()

            Button {
                if displayName.isEmpty { displayName = "there" }
                step = 1
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(displayName.isEmpty ? Color(.systemGray4) : Color(red: 0.95, green: 0.22, blue: 0.24))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            HStack {
                Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                Rectangle().fill(Color(.systemGray4)).frame(height: 1)
            }

            AppleSignInButton {
                // Pre-fill name from Apple if available, then skip to finish
                if displayName.isEmpty { displayName = "there" }
                saveProfileAndFinish()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Step 1: Gender

    private var genderStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            backButton

            Text("What is your gender?")
                .font(.system(size: 28, weight: .bold))

            Text("This helps us calculate your nutrition goals.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach(BiologicalSex.allCases, id: \.self) { s in
                    selectCard(s.rawValue) {
                        sex = s
                        step = 2
                    }
                }
            }
            .padding(.top, 12)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 2: Height

    private var heightStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            backButton

            Text("What is your height?")
                .font(.system(size: 28, weight: .bold))

            Text("Used to calculate your daily nutrition goals.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Picker("Height", selection: $heightCm) {
                ForEach(120...220, id: \.self) { cm in
                    Text("\(cm) cm").tag(Double(cm))
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)

            Spacer()

            continueButton { step = 3 }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Step 3: Weight

    private var weightStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            backButton

            Text("What is your weight?")
                .font(.system(size: 28, weight: .bold))

            Text("Used to calculate your daily nutrition goals.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Picker("Weight", selection: $weightKg) {
                ForEach(30...200, id: \.self) { kg in
                    Text("\(kg) kg").tag(Double(kg))
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)

            Spacer()

            continueButton { step = 4 }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Step 4: Birth Year

    private var birthYearStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            backButton

            Text("What year were you born?")
                .font(.system(size: 28, weight: .bold))

            Text("We only need the year to estimate your age.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Picker("Birth Year", selection: $birthYear) {
                ForEach(1940...2015, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)

            Spacer()

            continueButton { step = 5 }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Step 5: Activity Level

    private var activityStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            backButton

            Text("How active are you?")
                .font(.system(size: 28, weight: .bold))

            VStack(spacing: 12) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    Button {
                        activity = level
                        step = 6
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                Text(level.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 6: Diet Goal

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            backButton

            Text("What is your goal?")
                .font(.system(size: 28, weight: .bold))

            VStack(spacing: 12) {
                ForEach(DietGoal.allCases, id: \.self) { g in
                    selectCard(g.rawValue) {
                        goal = g
                        saveProfileAndFinish()
                    }
                }
            }
            .padding(.top, 12)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 7: Done

    private var doneStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("All set!")
                .font(.system(size: 32, weight: .bold))

            Text("Your daily calorie target")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let profile = UserProfile(
                displayName: displayName,
                heightCm: heightCm,
                weightKg: weightKg,
                birthYear: birthYear,
                biologicalSex: sex,
                activityLevel: activity,
                goal: goal
            )

            Text("\(profile.dailyCalorieTarget)")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(Color(red: 0.95, green: 0.22, blue: 0.24))

            Text("kcal / day")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                onComplete()
            } label: {
                Text("Start Using Niam")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.95, green: 0.22, blue: 0.24))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .sensoryFeedback(.success, trigger: step)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Shared Components

    private var backButton: some View {
        HStack {
            Button {
                step -= 1
            } label: {
                Image(systemName: "arrow.left")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
            Spacer()

            Button("Skip") {
                saveProfileAndFinish()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private func selectCard(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(18)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func continueButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.95, green: 0.22, blue: 0.24))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Save

    private func saveProfileAndFinish() {
        let profile = UserProfile(
            displayName: displayName.isEmpty ? "there" : displayName,
            heightCm: heightCm,
            weightKg: weightKg,
            birthYear: birthYear,
            biologicalSex: sex,
            activityLevel: activity,
            goal: goal
        )
        context.insert(profile)
        try? context.save()
        step = 7
    }

    private let funNames = [
        "Chef Panda",
        "Kitchen Hero",
        "Cooking Genius",
        "Foodie Fox",
        "Master Chef",
        "Spice Queen",
        "Noodle King",
        "Veggie Warrior",
        "Flavor Hunter",
        "Wok Star",
    ]
}
