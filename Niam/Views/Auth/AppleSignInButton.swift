import SwiftUI
import AuthenticationServices

/// A Sign in with Apple button that handles the full ASAuthorization flow.
struct AppleSignInButton: View {
    @StateObject private var auth = AuthService.shared
    @State private var errorMessage: String?
    @State private var showError = false

    var onSuccess: (() -> Void)?

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            let appleRequest = auth.appleSignInRequest()
            request.requestedScopes = appleRequest.requestedScopes
            request.nonce = appleRequest.nonce
        } onCompletion: { result in
            Task {
                switch result {
                case .success(let authorization):
                    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
                    do {
                        try await auth.handleAppleCredential(credential)
                        onSuccess?()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                case .failure(let error):
                    // User cancelled — ASAuthorizationError.canceled (code 1001) is not an error
                    let nsError = error as NSError
                    if nsError.code != ASAuthorizationError.canceled.rawValue {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .alert("Sign In Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
}
