import Combine
import Foundation

final class ProgressStore: ObservableObject {
    struct Snapshot: Codable {
        var solved: Set<String> = []
        var bookmarked: Set<String> = []
        var choices: [String: Int] = [:]
        var recent: [String] = []
        var lastQuestionID: String?
    }

    private static let storageKey = "examBank.progress.v1"

    @Published private(set) var snapshot: Snapshot

    var solvedIDs: Set<String> { snapshot.solved }
    var bookmarkedIDs: Set<String> { snapshot.bookmarked }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = Snapshot()
        }
    }

    func isSolved(_ id: String) -> Bool {
        snapshot.solved.contains(id)
    }

    func isBookmarked(_ id: String) -> Bool {
        snapshot.bookmarked.contains(id)
    }

    func choice(for id: String) -> Int? {
        snapshot.choices[id]
    }

    func toggleSolved(_ id: String) {
        var next = snapshot
        if next.solved.contains(id) {
            next.solved.remove(id)
        } else {
            next.solved.insert(id)
        }
        snapshot = next
        save()
    }

    func toggleBookmark(_ id: String) {
        var next = snapshot
        if next.bookmarked.contains(id) {
            next.bookmarked.remove(id)
        } else {
            next.bookmarked.insert(id)
        }
        snapshot = next
        save()
    }

    func setChoice(_ choice: Int, for id: String) {
        var next = snapshot
        if next.choices[id] == choice {
            next.choices.removeValue(forKey: id)
        } else {
            next.choices[id] = choice
        }
        snapshot = next
        save()
    }

    func markVisited(_ id: String) {
        var next = snapshot
        next.lastQuestionID = id
        next.recent.removeAll { $0 == id }
        next.recent.insert(id, at: 0)
        if next.recent.count > 30 {
            next.recent = Array(next.recent.prefix(30))
        }
        snapshot = next
        save()
    }

    func reset() {
        snapshot = Snapshot()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
