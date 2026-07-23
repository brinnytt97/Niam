import SwiftUI

struct PublishRecipeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthService.shared
    @StateObject private var repo = CommunityRecipeRepository.shared

    let recipe: Recipe
    var onPublished: () -> Void

    @State private var isPublishing = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Recipe preview card
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.title3.weight(.bold))
                    HStack(spacing: 8) {
                        Text(recipe.cuisine.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        ForEach(recipe.scenes.prefix(2), id: \.self) { scene in
                            Text(scene.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.12))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    HStack(spacing: 12) {
                        if let cal = recipe.caloriesPerServing {
                            Label("\(cal) kcal", systemImage: "flame")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if recipe.totalTimeMinutes > 0 {
                            Label("\(recipe.totalTimeMinutes) min", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Label("\(recipe.allIngredients.count) ingredients", systemImage: "list.bullet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Label("Your recipe will be visible to all Niam users", systemImage: "globe")
                    Label("You can withdraw it at any time from the recipe detail", systemImage: "eye.slash")
                    Label("Your name will be shown as the author", systemImage: "person")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Auth gate
                if !auth.isSignedIn {
                    VStack(spacing: 12) {
                        Text("Sign in to publish")
                            .font(.subheadline.weight(.semibold))
                        AppleSignInButton()
                    }
                } else {
                    Button {
                        Task { await publish() }
                    } label: {
                        Group {
                            if isPublishing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Publish to Community")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.95, green: 0.22, blue: 0.24))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isPublishing)
                }
            }
            .padding(24)
            .navigationTitle("Share Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Publish Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func publish() async {
        isPublishing = true
        defer { isPublishing = false }
        do {
            let id = try await repo.publish(recipe)
            recipe.publishedRecipeID = id
            recipe.isPublished = true
            recipe.publishedAt = .now
            onPublished()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
