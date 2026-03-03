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

    /// Our app's own keychain service name (no prompt needed since we create it)
    private static let appServiceName = "ClaudeUsageBar-credentials"

    /// Account name for our keychain item
    private static let appAccountName = "oauth-token-cache"

    private var cachedToken: String?

    // MARK: - Public

    func readOAuthToken() throws -> String {
        if let cached = cachedToken {
            return cached
        }

        // Try our own keychain item first (silent, no macOS prompt)
        if let token = try? readTokenFromAppKeychain() {
            cachedToken = token
            return token
        }

        // Fall back to Claude Code's keychain item (may trigger prompt once)
        let token = try readTokenFromClaudeCode()

        // Persist to our own keychain for future silent access
        saveTokenToAppKeychain(token)

        cachedToken = token
        return token
    }

    func clearCache() {
        cachedToken = nil
    }

    /// Clears in-memory cache AND deletes our app's keychain copy,
    /// forcing a re-read from Claude Code's keychain item on next access.
    func invalidateToken() {
        cachedToken = nil
        deleteAppKeychainToken()
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

    // MARK: - Private: Read from our app's keychain (plain token string)

    private func readTokenFromAppKeychain() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.appServiceName,
            kSecAttrAccount as String: Self.appAccountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw KeychainError.itemNotFound
        }

        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty
        else {
            throw KeychainError.unexpectedData
        }

        return token
    }

    // MARK: - Private: Write/Delete our app's keychain item

    private func saveTokenToAppKeychain(_ token: String) {
        guard let tokenData = token.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.appServiceName,
            kSecAttrAccount as String: Self.appAccountName,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: tokenData,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = tokenData
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }

    private func deleteAppKeychainToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.appServiceName,
            kSecAttrAccount as String: Self.appAccountName,
        ]

        SecItemDelete(query as CFDictionary)
    }
}
