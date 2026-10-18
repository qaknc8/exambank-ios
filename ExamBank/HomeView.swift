import Foundation
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var bank: BankStore
    @EnvironmentObject private var progress: ProgressStore
    @State private var presented: SessionPresenter?
    @State private var showAllSolved = false

    private var total: Int { bank.questions.count }
    private var solved: Int { bank.questions.filter { progress.isSolved($0.id) }.count }
    private var ratio: Double {
        total == 0 ? 0 : Double(solved) / Double(total)
    }

    private var recentQuestions: [Question] {
        progress.snapshot.recent.compactMap(bank.question(withID:))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        progressCard
                        if !recentQuestions.isEmpty {
                            recentSection
                        }
                        subjectSection
                        footerNote
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $presented) { item in
                SessionView(session: item.session)
            }
            .alert("모든 문제를 풀었습니다", isPresented: $showAllSolved) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("복습을 원하면 문제 탭에서 원하는 과목과 연도를 골라 다시 풀 수 있습니다.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("5급 PSAT")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brand)
                .textCase(.uppercase)
                .kerning(1.4)
            Text("오늘도 한 문제씩")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ink)
            Text("과목과 연도로 골라서, 아이폰에서 바로 풀어보세요.")
                .font(.subheadline)
                .foregroundStyle(Color.inkSoft)
        }
        .padding(.top, 16)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("풀이 현황")
                    .font(.headline)
                    .foregroundStyle(Color.ink)
                Spacer()
                Text(String(solved) + " / " + String(total))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.brandDeep)
                    .monospacedDigit()
            }

            ProgressView(value: ratio)
                .tint(.brand)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)

            HStack(spacing: 10) {
                Button(action: startResume) {
                    Label(resumeTitle, systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Color.paper)
                }
                .buttonStyle(.plain)

                Button(action: startUnsolved) {
                    Label("안 푼 문제", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.brandWash.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Color.ink)
                }
                .buttonStyle(.plain)
            }
            .disabled(total == 0)
            .opacity(total == 0 ? 0.4 : 1)
        }
        .examCard(padding: 18)
    }

    private var resumeTitle: String {
        progress.snapshot.lastQuestionID == nil ? "처음부터 풀기" : "이어서 풀기"
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("최근 본 문제")
            VStack(spacing: 0) {
                ForEach(recentQuestions.prefix(3)) { question in
                    Button {
                        start(at: question, in: bank.questions)
                    } label: {
                        QuestionRowContent(
                            question: question,
                            solved: progress.isSolved(question.id),
                            bookmarked: progress.isBookmarked(question.id)
                        )
                    }
                    .buttonStyle(.plain)
                    if question.id != recentQuestions.prefix(3).last?.id {
                        Divider().overlay(Color.line)
                    }
                }
            }
            .examCard(padding: 4)
        }
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("과목별로 풀기")
            VStack(spacing: 12) {
                ForEach(bank.subjects) { subject in
                    NavigationLink {
                        LibraryView(initialSubject: subject.name)
                    } label: {
                        SubjectCard(subject: subject, questions: bank.questions, progress: progress)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var footerNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
            Text("문제 이미지는 원본 PDF에서 잘라낸 것이며, 정답·해설은 추후 추가할 수 있습니다.")
        }
        .font(.caption)
        .foregroundStyle(Color.inkSoft)
        .padding(.top, 4)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Color.ink)
    }

    private func startResume() {
        guard !bank.questions.isEmpty else { return }
        if let lastID = progress.snapshot.lastQuestionID,
           let index = bank.questions.firstIndex(where: { $0.id == lastID }) {
            presented = SessionPresenter(
                session: StudySession(questions: bank.questions, startIndex: index)
            )
        } else {
            startUnsolved()
        }
    }

    private func startUnsolved() {
        guard !bank.questions.isEmpty else { return }
        if let index = bank.questions.firstIndex(where: { !progress.isSolved($0.id) }) {
            presented = SessionPresenter(
                session: StudySession(questions: bank.questions, startIndex: index)
            )
        } else {
            showAllSolved = true
        }
    }

    private func start(at question: Question, in questions: [Question]) {
        guard let index = questions.firstIndex(of: question) else { return }
        presented = SessionPresenter(
            session: StudySession(questions: questions, startIndex: index)
        )
    }
}

private struct SubjectCard: View {
    let subject: SubjectSummary
    let questions: [Question]
    @ObservedObject var progress: ProgressStore

    private var subjectQuestions: [Question] {
        questions.filter { $0.subject == subject.name }
    }

    private var solvedCount: Int {
        subjectQuestions.filter { progress.isSolved($0.id) }.count
    }

    private var ratio: Double {
        subjectQuestions.isEmpty ? 0 : Double(solvedCount) / Double(subjectQuestions.count)
    }

    private var yearsText: String {
        let years = subject.years.sorted()
        guard let first = years.first, let last = years.last else { return "" }
        if first == last { return String(first) }
        return String(first) + "–" + String(last)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.line, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: max(0.001, ratio))
                    .stroke(Color.brand, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(ratio * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.brandDeep)
                    .monospacedDigit()
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(subject.name)
                    .font(.headline)
                    .foregroundStyle(Color.ink)
                Text(yearsText + " · " + String(subject.questionCount) + "문제")
                    .font(.caption)
                    .foregroundStyle(Color.inkSoft)
                Text(String(solvedCount) + "문제 완료")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.brand)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.inkSoft.opacity(0.7))
        }
        .examCard(padding: 14)
    }
}
