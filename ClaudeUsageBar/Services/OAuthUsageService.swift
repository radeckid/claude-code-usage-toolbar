import Foundation

enum OAuthUsageError: LocalizedError, Sendable {
    case keychainError(String)
    case networkError(String)
    case invalidResponse(Int)
    case parseError(String)
    case sessionExpired
    case rateLimited(retryAfter: TimeInterval?)
    case rateLimitedWithCache(cached: OAuthUsageResponse, retryAfter: TimeInterval?)

    var errorDescription: String? {
        switch self {
        case .keychainError(let msg):
            return "Keychain: \(msg)"
        case .networkError(let msg):
            return "Network: \(msg)"
        case .invalidResponse(let code):
            return "API returned status \(code)"
        case .parseError(let msg):
            return "Parse: \(msg)"
        case .sessionExpired:
            return "Session expired"
        case .rateLimited, .rateLimitedWithCache:
            return "Rate limited (429)"
        }
    }
}

final class OAuthUsageService: Sendable {
    private static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    private static let cacheURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ClaudeUsageBar", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("last_usage.json")
    }()

    private let keychainService = KeychainService()

    func fetchUsage() async throws -> OAuthUsageResponse {
        let token = try readToken()

        let result = try await callAPI(token: token)

        // If 401, token might have expired — invalidate and retry from source
        if case .failure(let error) = result,
           case .invalidResponse(401) = error {
            keychainService.invalidateToken()

            let freshToken: String
            do {
                freshToken = try readToken()
            } catch {
                throw OAuthUsageError.sessionExpired
            }

            let retry = try await callAPI(token: freshToken)

            if case .failure(let retryError) = retry,
               case .invalidResponse(401) = retryError {
                keychainService.invalidateToken()
                throw OAuthUsageError.sessionExpired
            }

            let response = try retry.get()
            saveCache(response)
            return response
        }

        // If 429, return cached data immediately — no retries
        if case .failure(let error) = result,
           case .rateLimited(let retryAfter) = error {
            if let cached = loadCache() {
                throw OAuthUsageError.rateLimitedWithCache(cached: cached, retryAfter: retryAfter)
            }
            throw error
        }

        let response = try result.get()
        saveCache(response)
        return response
    }

    // MARK: - Cache

    private func saveCache(_ response: OAuthUsageResponse) {
        try? JSONEncoder().encode(response).write(to: Self.cacheURL)
    }

    func loadCache() -> OAuthUsageResponse? {
        guard let data = try? Data(contentsOf: Self.cacheURL) else { return nil }
        return try? JSONDecoder().decode(OAuthUsageResponse.self, from: data)
    }

    private func readToken() throws -> String {
        do {
            return try keychainService.readOAuthToken()
        } catch {
            throw OAuthUsageError.keychainError(error.localizedDescription)
        }
    }

    private func callAPI(token: String) async throws -> Result<OAuthUsageResponse, OAuthUsageError> {
        var request = URLRequest(url: Self.usageURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("claude-code/2.0.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw OAuthUsageError.networkError(error.localizedDescription)
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
            let retryAfterSeconds = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            return .failure(.rateLimited(retryAfter: retryAfterSeconds))
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            return .failure(.invalidResponse(httpResponse.statusCode))
        }

        do {
            return .success(try JSONDecoder().decode(OAuthUsageResponse.self, from: data))
        } catch {
            throw OAuthUsageError.parseError(error.localizedDescription)
        }
    }
}
