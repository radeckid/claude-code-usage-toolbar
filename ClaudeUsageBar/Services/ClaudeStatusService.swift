import Foundation

@MainActor
@Observable
final class ClaudeStatusService {
    private(set) var status: ClaudeStatusResponse?
    private(set) var isLoading = false
    private(set) var lastError: String?
    private(set) var lastFetchDate: Date?

    private let statusURL = URL(string: "https://status.claude.com/api/v2/summary.json")!

    func fetch() async {
        isLoading = true
        lastError = nil

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let (data, _) = try await URLSession.shared.data(from: statusURL)
            status = try decoder.decode(ClaudeStatusResponse.self, from: data)
            lastFetchDate = Date()
        } catch {
            lastError = error.localizedDescription
        }

        isLoading = false
    }
}
