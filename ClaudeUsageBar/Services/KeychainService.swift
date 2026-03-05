import Foundation
import Security

enum KeychainError: LocalizedError, Sendable {
    case itemNotFound
    case unexpectedData
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Claude Code credentials not found in Keychain"
        case .unexpectedData:
            return "Could not read Keychain data"
        case .parseError(let msg):
            return "Failed to parse credentials: \(msg)"
        }
    }
}

final class KeychainService: @unchecked Sendable {
    /// Keychain service name used by Claude Code CLI (source of truth, may trigger macOS prompt)
    private static let claudeCodeServiceName = "Claude Code-credentials"

    // MARK: - Public

    /// Always reads fresh from Claude Code's keychain (no caching).
    func readOAuthToken() throws -> String {
        try readTokenFromClaudeCode()
    }

    // MARK: - Private: Read from Claude Code's keychain via /usr/bin/security CLI
    // Using the system `security` binary avoids repeated Keychain prompts because
    // it has a stable Apple code signature, so "Always Allow" persists permanently.

    private func readTokenFromClaudeCode() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", Self.claudeCodeServiceName, "-w"]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw KeychainError.itemNotFound
        }

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw KeychainError.itemNotFound
        }

        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        guard let jsonString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !jsonString.isEmpty
        else {
            throw KeychainError.unexpectedData
        }

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let oauthSection = json["claudeAiOauth"] as? [String: Any],
              let accessToken = oauthSection["accessToken"] as? String
        else {
            throw KeychainError.parseError("Missing claudeAiOauth.accessToken")
        }

        return accessToken
    }

}
