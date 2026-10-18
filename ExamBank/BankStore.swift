import Combine
import Foundation

final class BankStore: ObservableObject {
    @Published private(set) var manifest: BankManifest?
    @Published private(set) var imageURLs: [String: URL] = [:]
    @Published private(set) var loadError: String?

    var questions: [Question] { manifest?.questions ?? [] }
    var subjects: [SubjectSummary] { manifest?.subjects ?? [] }
    var grades: [GradeSummary] { manifest?.grades ?? [] }
    var answeredCount: Int { questions.filter { $0.answer != nil }.count }

    func loadIfNeeded() {
        guard manifest == nil, loadError == nil else { return }
        do {
            let bundled = Bundle.main.url(
                forResource: "manifest",
                withExtension: "json",
                subdirectory: "Questions"
            )
            guard let url = bundled ?? Bundle.main.url(
                forResource: "manifest",
                withExtension: "json"
            ) else {
                throw BankError.missingManifest
            }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(BankManifest.self, from: data)
            manifest = decoded
            buildImageURLs(for: decoded)
        } catch {
            loadError = error.localizedDescription
        }
    }

    func imageURL(for question: Question) -> URL? {
        imageURLs[question.id]
    }

    func question(withID id: String) -> Question? {
        questions.first { $0.id == id }
    }

    private func buildImageURLs(for manifest: BankManifest) {
        guard let resourceRoot = Bundle.main.resourceURL else { return }
        let imageDirectory = resourceRoot.appendingPathComponent(
            "Questions/images",
            isDirectory: true
        )
        var urls: [String: URL] = [:]
        for question in manifest.questions {
            let nested = imageDirectory.appendingPathComponent(question.image)
            if FileManager.default.fileExists(atPath: nested.path) {
                urls[question.id] = nested
                continue
            }
            let flat = resourceRoot.appendingPathComponent(question.image)
            if FileManager.default.fileExists(atPath: flat.path) {
                urls[question.id] = flat
            }
        }
        imageURLs = urls
    }
}

enum BankError: LocalizedError {
    case missingManifest

    var errorDescription: String? {
        "앱 번들에서 문제은행(manifest.json)을 찾지 못했습니다. tools/sync_ios_assets.py를 실행한 뒤 다시 빌드해 주세요."
    }
}
