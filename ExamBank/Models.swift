import Foundation

struct Question: Identifiable, Codable, Hashable {
    let id: String
    let number: Int
    let year: Int
    let grade: String
    let subject: String
    let booklet: String
    let image: String
    let width: Int
    let height: Int
    let hasVisual: Bool
    let stem: String
    let choices: [String]
    let answer: Int?
    let explanation: String?

    static let choiceSymbols = ["①", "②", "③", "④", "⑤"]

    var preview: String {
        var text = stem.replacingOccurrences(of: "\n", with: " ")
        text = text.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        if let range = text.range(
            of: #"^문?\s*\d{1,3}\s*\.\s*"#,
            options: .regularExpression
        ) {
            text.removeSubrange(range)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var answerSymbol: String? {
        guard let answer, (1...5).contains(answer) else { return nil }
        return Self.choiceSymbols[answer - 1]
    }
}

struct SubjectSummary: Identifiable, Codable, Hashable {
    let name: String
    let years: [Int]
    let questionCount: Int

    var id: String { name }
}

struct GradeSummary: Identifiable, Codable, Hashable {
    let name: String
    let questionCount: Int

    var id: String { name }
}

struct BankManifest: Codable {
    let version: Int
    let generatedAt: String
    let sourceGeneratedAt: String?
    let subjects: [SubjectSummary]
    let grades: [GradeSummary]?
    let questions: [Question]
}

struct BankFilter: Equatable {
    var subject: String? = nil
    var year: Int? = nil
    var grade: String? = nil
    var onlyUnsolved = false
    var onlyBookmarked = false
    var query = ""

    var isActive: Bool {
        subject != nil
            || year != nil
            || grade != nil
            || onlyUnsolved
            || onlyBookmarked
            || !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func apply(
        to questions: [Question],
        solved: Set<String>,
        bookmarked: Set<String>
    ) -> [Question] {
        let terms = query
            .split(whereSeparator: { $0.isWhitespace })
            .map { $0.lowercased() }

        return questions.filter { question in
            if let subject, question.subject != subject { return false }
            if let year, question.year != year { return false }
            if let grade, question.grade != grade { return false }
            if onlyUnsolved && solved.contains(question.id) { return false }
            if onlyBookmarked && !bookmarked.contains(question.id) { return false }

            if !terms.isEmpty {
                let haystack = [
                    question.subject,
                    question.grade,
                    question.booklet,
                    String(question.year),
                    question.stem,
                    question.choices.joined(separator: " "),
                ]
                .joined(separator: " ")
                .replacingOccurrences(of: "\n", with: " ")
                .lowercased()

                if !terms.allSatisfy({ haystack.contains($0) }) { return false }
            }
            return true
        }
    }
}

struct StudySession: Identifiable {
    let id = UUID()
    let questions: [Question]
    let startIndex: Int
}
