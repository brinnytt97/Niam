import SwiftUI
import SwiftData

struct MeView: View {
    @Environment(\.modelContext) private var context
    @State private var profile: UserProfile?
    @State private var showingProfile = false
    @State private var showingNameEdit = false
    @State private var editName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Avatar + Name
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 80, height: 80)
                            Text("👤")
                                .font(.system(size: 36))
                        }

                        Text(profile?.displayName ?? "Niam User")
                            .font(.title2.weight(.bold))

                        Button("Edit name") {
                            editName = profile?.displayName ?? ""
                            showingNameEdit = true
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // MARK: - Stats Row
                    if let p = profile {
                        HStack(spacing: 0) {
                            statItem(value: "\(p.dailyCalorieTarget)", label: "Daily Target", unit: "kcal")
                            statItem(value: "\(Int(p.bmr))", label: "BMR", unit: "kcal")
                            statItem(value: p.goal.rawValue, label: "Goal", unit: "")
                        }
                        .padding(.vertical, 16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
                        .padding(.horizontal, 24)
                    }

                    // MARK: - Profile Section
                    settingsGroup(title: "Profile", items: [
                        SettingsItem(icon: "ruler", label: "Body Measurements") {
                            showingProfile = true
                        },
                        SettingsItem(icon: "figure.walk", label: "Activity Level") {
                            showingProfile = true
                        },
                        SettingsItem(icon: "target", label: "Diet Goal") {
                            showingProfile = true
                        },
                    ])

                    // MARK: - Settings Section
                    settingsGroup(title: "Settings", items: [
                        SettingsItem(icon: "globe", label: "Language") {},
                        SettingsItem(icon: "bell", label: "Notifications") {},
                        SettingsItem(icon: "icloud", label: "iCloud Sync") {},
                    ])

                    // MARK: - About Section
                    settingsGroup(title: "About", items: [
                        SettingsItem(icon: "star", label: "Rate App") {},
                        SettingsItem(icon: "envelope", label: "Feedback") {},
                        SettingsItem(icon: "info.circle", label: "Version 0.1.0") {},
                    ])
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGray6).opacity(0.5))
            .sheet(isPresented: $showingProfile) {
                ProfileView(existingProfile: profile) { newProfile in
                    // Delete old and save new
                    if let existing = profile {
                        context.delete(existing)
                    }
                    context.insert(newProfile)
                    try? context.save()
                    profile = newProfile
                }
            }
            .onAppear { loadProfile() }
            .alert("Edit Name", isPresented: $showingNameEdit) {
                TextField("Your name", text: $editName)
                Button("Save") {
                    if !editName.isEmpty {
                        profile?.displayName = editName
                        try? context.save()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Components

    private func statItem(value: String, label: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(unit.isEmpty ? label : "\(label) (\(unit))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private struct SettingsItem {
        let icon: String
        let label: String
        let action: () -> Void
    }

    private func settingsGroup(title: String, items: [SettingsItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Button(action: item.action) {
                        HStack(spacing: 14) {
                            Image(systemName: item.icon)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .frame(width: 24)
                            Text(item.label)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    if index < items.count - 1 {
                        Divider().padding(.leading, 58)
                    }
                }
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
        }
    }

    private func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        profile = (try? context.fetch(descriptor))?.first
    }
}
