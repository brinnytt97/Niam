import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var height: Double
    @State private var weight: Double
    @State private var age: Int
    @State private var sex: BiologicalSex
    @State private var activity: ActivityLevel
    @State private var goal: DietGoal

    var onSave: (UserProfile) -> Void

    init(existingProfile: UserProfile?, onSave: @escaping (UserProfile) -> Void) {
        let p = existingProfile
        _height = State(initialValue: p?.heightCm ?? 170)
        _weight = State(initialValue: p?.weightKg ?? 70)
        _age = State(initialValue: p?.age ?? 25)
        _sex = State(initialValue: p?.biologicalSex ?? .male)
        _activity = State(initialValue: p?.activityLevel ?? .moderate)
        _goal = State(initialValue: p?.goal ?? .maintain)
        self.onSave = onSave
    }

    private var previewProfile: UserProfile {
        UserProfile(
            heightCm: height,
            weightKg: weight,
            age: age,
            biologicalSex: sex,
            activityLevel: activity,
            goal: goal
        )
    }

    var body: some View {
        NavigationStack {
            Form {
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
                    Stepper("Age: \(age)", value: $age, in: 10...100)
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
