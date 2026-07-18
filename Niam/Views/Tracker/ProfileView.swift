import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String
    @State private var height: Double
    @State private var weight: Double
    @State private var birthYear: Int
    @State private var sex: BiologicalSex
    @State private var activity: ActivityLevel
    @State private var goal: DietGoal

    var onSave: (UserProfile) -> Void

    init(existingProfile: UserProfile?, onSave: @escaping (UserProfile) -> Void) {
        let p = existingProfile
        _displayName = State(initialValue: p?.displayName ?? "there")
        _height = State(initialValue: p?.heightCm ?? 170)
        _weight = State(initialValue: p?.weightKg ?? 70)
        _birthYear = State(initialValue: p?.birthYear ?? 2000)
        _sex = State(initialValue: p?.biologicalSex ?? .male)
        _activity = State(initialValue: p?.activityLevel ?? .moderate)
        _goal = State(initialValue: p?.goal ?? .maintain)
        self.onSave = onSave
    }

    private var previewProfile: UserProfile {
        UserProfile(
            displayName: displayName,
            heightCm: height,
            weightKg: weight,
            birthYear: birthYear,
            biologicalSex: sex,
            activityLevel: activity,
            goal: goal
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Display name", text: $displayName)
                }

                Section("Body") {
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("cm", value: $height, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm")
                    }
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("kg", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                    }
                    Picker("Birth Year", selection: $birthYear) {
                        ForEach(1940...2015, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    Picker("Sex", selection: $sex) {
                        ForEach(BiologicalSex.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                }

                Section("Lifestyle") {
                    Picker("Activity Level", selection: $activity) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    Picker("Goal", selection: $goal) {
                        ForEach(DietGoal.allCases, id: \.self) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                }

                Section("Estimated Daily Calories") {
                    HStack {
                        Text("BMR")
                        Spacer()
                        Text("\(Int(previewProfile.bmr)) kcal")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("TDEE")
                        Spacer()
                        Text("\(Int(previewProfile.tdee)) kcal")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Daily Target")
                        Spacer()
                        Text("\(previewProfile.dailyCalorieTarget) kcal")
                            .font(.headline)
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(previewProfile)
                        dismiss()
                    }
                }
            }
        }
    }
}
