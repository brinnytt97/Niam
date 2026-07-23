import Foundation
import AuthenticationServices
import CryptoKit
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var isSignedIn = false
    @Published private(set) var userEmail: String?
    @Published private(set) var isLoading = false

    private var currentNonce: String?

    private init() {
        Task { await refreshSession() }
    }

    // MARK: - Session

    func refreshSession() async {
        do {
            let session = try await supabase.auth.session
            isSignedIn = true
            userEmail = session.user.email
        } catch {
            isSignedIn = false
            userEmail = nil
        }
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {}
        isSignedIn = false
        userEmail = nil
    }

    // MARK: - Sign in with Apple

    /// Returns a configured ASAuthorizationAppleIDRequest with a fresh nonce.
    func appleSignInRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonce()
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }

    /// Call after ASAuthorizationController delivers a credential.
    func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async throws {
        guard
            let nonce = currentNonce,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw AuthError.missingToken
        }

        isLoading = true
        defer { isLoading = false }

        let fullName = [
            credential.fullName?.givenName,
            credential.fullName?.familyName
        ].compactMap { $0 }.joined(separator: " ")

        _ = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )

        // Update display name if provided (first sign-in only)
        if !fullName.isEmpty {
            _ = try? await supabase.auth.update(
                user: UserAttributes(data: ["full_name": .string(fullName)])
            )
        }

        await refreshSession()
    }

    // MARK: - Nonce helpers

    private func randomNonce(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum AuthError: LocalizedError {
    case missingToken

    var errorDescription: String? {
        switch self {
        case .missingToken: "Apple did not provide an identity token."
        }
    }
}
