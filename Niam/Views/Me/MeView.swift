import SwiftUI
import SwiftData
import StoreKit
import PhotosUI

struct MeView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var auth = AuthService.shared
    @State private var profile: UserProfile?
    @State private var showingProfile = false
    @State private var showingNameEdit = false
    @State private var editName = ""
    @State private var showingAvatarPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingSignOutConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Avatar + Name
                    VStack(spacing: 12) {
                        Button { showingAvatarPicker = true } label: {
                            avatarView
                        }

                        Text(profile?.displayName ?? "there")
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
                            statItem(value: p.goal?.rawValue ?? "—", label: "Goal", unit: "")
                        }
                        .padding(.vertical, 16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
                        .padding(.horizontal, 24)
                    }

                    // MARK: - Account Section
                    accountSection

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
                        SettingsItem(icon: "globe", label: "Language") {
                            // Open iOS language settings
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        },
                        SettingsItem(icon: "bell", label: "Notifications") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        },
                        SettingsItem(icon: "icloud", label: "iCloud Sync") {
                            // Placeholder — full implementation needs CloudKit entitlement
                        },
                    ])

                    // MARK: - About Section
                    settingsGroup(title: "About", items: [
                        SettingsItem(icon: "star", label: "Rate App") {
                            requestReview()
                        },
                        SettingsItem(icon: "envelope", label: "Feedback") {
                            if let url = URL(string: "mailto:feedback@niam.app?subject=Niam%20Feedback") {
                                UIApplication.shared.open(url)
                            }
                        },
                        SettingsItem(icon: "info.circle", label: "Version \(appVersion)") {},
                    ])
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGray6).opacity(0.5))
            .sheet(isPresented: $showingProfile) {
                ProfileView(existingProfile: profile) { newProfile in
                    if let existing = profile {
                        // Update in-place to preserve displayName and other data
                        existing.heightCm = newProfile.heightCm
                        existing.weightKg = newProfile.weightKg
                        existing.birthYear = newProfile.birthYear
                        existing.biologicalSex = newProfile.biologicalSex
                        existing.activityLevel = newProfile.activityLevel
                        existing.goal = newProfile.goal
                        if !newProfile.displayName.isEmpty {
                            existing.displayName = newProfile.displayName
                        }
                    } else {
                        context.insert(newProfile)
                    }
                    try? context.save()
                    loadProfile()
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
            .sheet(isPresented: $showingAvatarPicker) {
                AvatarPickerSheet(profile: profile, context: context) {
                    loadProfile()
                }
            }
            .confirmationDialog("Sign out of your Apple account?", isPresented: $showingSignOutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    Task { await auth.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your local data stays on this device.")
            }
        }
    }

    // MARK: - Account Section

    @ViewBuilder
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ACCOUNT")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                if auth.isSignedIn {
                    HStack(spacing: 14) {
                        Image(systemName: "apple.logo")
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Signed in with Apple")
                                .font(.subheadline.weight(.medium))
                            if let email = auth.userEmail {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("Sign Out") {
                            showingSignOutConfirm = true
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                } else {
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "person.badge.key")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            Text("Sign in to sync recipes and access community features")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                        AppleSignInButton()
                            .padding(.horizontal, 20)
                            .padding(.bottom, 14)
                    }
                }
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Avatar View

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 80, height: 80)

            if let data = profile?.avatarData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else if let emoji = profile?.avatarEmoji {
                Text(emoji)
                    .font(.system(size: 40))
            } else {
                Text("👤")
                    .font(.system(size: 36))
            }

            // Camera badge
            Image(systemName: "camera.fill")
                .font(.caption2)
                .foregroundStyle(.white)
                .padding(4)
                .background(Color(.systemGray2))
                .clipShape(Circle())
                .offset(x: 28, y: 28)
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

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        profile = (try? context.fetch(descriptor))?.first
    }
}

// MARK: - Avatar Picker Sheet

private struct AvatarPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile?
    let context: ModelContext
    let onSave: () -> Void

    @State private var selectedPhoto: PhotosPickerItem?

    private let emojiOptions = [
        "👨‍🍳", "👩‍🍳", "🐼", "🦊", "🐱", "🐶",
        "🍳", "🥑", "🍕", "🧁", "🌮", "🍜",
        "😊", "🤗", "😎", "🥰", "🌸", "⭐️",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Choose your avatar")
                    .font(.headline)
                    .padding(.top, 20)

                // Photo option
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Photos")
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .onChange(of: selectedPhoto) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            profile?.avatarData = data
                            profile?.avatarEmoji = nil
                            try? context.save()
                            onSave()
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 24)

                Divider().padding(.horizontal, 24)

                // Emoji grid
                Text("Or pick an emoji")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                    ForEach(emojiOptions, id: \.self) { emoji in
                        Button {
                            profile?.avatarEmoji = emoji
                            profile?.avatarData = nil
                            try? context.save()
                            onSave()
                            dismiss()
                        } label: {
                            Text(emoji)
                                .font(.system(size: 36))
                                .frame(width: 50, height: 50)
                                .background(
                                    profile?.avatarEmoji == emoji
                                        ? Color(.systemGray4)
                                        : Color(.systemGray6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
