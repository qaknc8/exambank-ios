import Foundation
import SwiftUI
import UIKit

struct LibraryView: View {
    var initialSubject: String? = nil

    var body: some View {
        QuestionBrowserView(initialSubject: initialSubject)
    }
}

struct QuestionBrowserView: View {
    @EnvironmentObject private var bank: BankStore
    @EnvironmentObject private var progress: ProgressStore
    @State private var filter = BankFilter()
    @State private var presented: SessionPresenter?
    @State private var detailQuestion: Question?

    private var availableYears: [Int] {
        let scoped = bank.questions.filter { question in
            (filter.subject == nil || question.subject == filter.subject)
                && (filter.grade == nil || question.grade == filter.grade)
        }
        return Array(Set(scoped.map(\.year))).sorted(by: >)
    }

    private var availableGrades: [String] {
        let scoped = bank.questions.filter { question in
            (filter.subject == nil || question.subject == filter.subject)
                && (filter.year == nil || question.year == filter.year)
        }
        let counts = Dictionary(grouping: scoped, by: \.grade).mapValues(\.count)
        return counts.keys.sorted { lhs, rhs in
            let left = counts[lhs] ?? 0
            let right = counts[rhs] ?? 0
            return left == right ? lhs < rhs : left > right
        }
    }

    private var filteredQuestions: [Question] {
        filter.apply(
            to: bank.questions,
            solved: progress.solvedIDs,
            bookmarked: progress.bookmarkedIDs
        )
    }

    init(initialSubject: String?) {
        if let initialSubject {
            _filter = State(initialValue: BankFilter(subject: initialSubject))
        }
    }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 12, pinnedViews: []) {
                    filterCard
                    summaryRow
                    ForEach(filteredQuestions) { question in
                        Button {
                            start(at: question)
                        } label: {
                            QuestionRowContent(
                                question: question,
                                solved: progress.isSolved(question.id),
                                bookmarked: progress.isBookmarked(question.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                detailQuestion = question
                            } label: {
                                Label("문제 정보", systemImage: "info.circle")
                            }
                            Button {
                                progress.toggleBookmark(question.id)
                            } label: {
                                Label(
                                    progress.isBookmarked(question.id) ? "북마크 해제" : "북마크",
                                    systemImage: progress.isBookmarked(question.id)
                                        ? "bookmark.slash" : "bookmark"
                                )
                            }
                            Button {
                                progress.toggleSolved(question.id)
                            } label: {
                                Label(
                                    progress.isSolved(question.id) ? "완료 취소" : "완료 표시",
                                    systemImage: progress.isSolved(question.id)
                                        ? "arrow.uturn.backward" : "checkmark.circle"
                                )
                            }
                        }
                    }
                    if filteredQuestions.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(filter.subject ?? "전체 문제")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .searchable(
            text: $filter.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "내용·과목·연도 검색"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    startPractice()
                } label: {
                    Label("풀기", systemImage: "play.fill")
                }
                .disabled(filteredQuestions.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !filteredQuestions.isEmpty {
                startBar
            }
        }
        .fullScreenCover(item: $presented) { item in
            SessionView(session: item.session)
        }
        .sheet(item: $detailQuestion) { question in
            NavigationStack {
                QuestionDetailView(question: question)
            }
        }
    }

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(title: "전체", selected: filter.subject == nil) {
                        filter.subject = nil
                        filter.year = nil
                        filter.grade = nil
                    }
                    ForEach(bank.subjects) { subject in
                        chip(title: subject.name, selected: filter.subject == subject.name) {
                            filter.subject = subject.name
                            if let year = filter.year, !subject.years.contains(year) {
                                filter.year = nil
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    Menu {
                        Button("전체 연도") { filter.year = nil }
                        ForEach(availableYears, id: \.self) { year in
                            Button(String(year) + "년") { filter.year = year }
                        }
                    } label: {
                        compactLabel(
                            icon: "calendar",
                            text: filter.year.map { String($0) + "년" } ?? "연도"
                        )
                    }
                    .buttonStyle(.plain)

                    Menu {
                        Button("전체 시험") { filter.grade = nil }
                        ForEach(availableGrades, id: \.self) { grade in
                            Button(grade) { filter.grade = grade }
                        }
                    } label: {
                        compactLabel(
                            icon: "graduationcap",
                            text: filter.grade ?? "시험"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 1)
            }

            HStack(spacing: 10) {
                toggleChip(
                    title: "안 푼 문제",
                    icon: "circle.dashed",
                    selected: filter.onlyUnsolved
                ) {
                    filter.onlyUnsolved.toggle()
                }
                toggleChip(
                    title: "북마크",
                    icon: "bookmark.fill",
                    selected: filter.onlyBookmarked
                ) {
                    filter.onlyBookmarked.toggle()
                }
                Spacer(minLength: 0)
                Text(String(filteredQuestions.count) + "문제")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.inkSoft)
            }
        }
        .examCard(padding: 14)
        .padding(.top, 4)
    }

    private var summaryRow: some View {
        HStack {
            Text(String(filteredQuestions.count) + "문제")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.inkSoft)
            if filter.isActive {
                Button("필터 초기화") {
                    filter = BankFilter()
                }
                .font(.footnote)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var startBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(filteredQuestions.count) + "문제 선택됨")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Text(filteredQuestions.first.map { "\($0.subject) · " + String($0.year) + "년부터" } ?? "")
                    .font(.caption)
                    .foregroundStyle(Color.inkSoft)
            }
            Spacer()
            Button(action: startPractice) {
                Label("풀기 시작", systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color.brand, in: Capsule())
                    .foregroundStyle(Color.paper)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(Color.inkSoft)
            Text("조건에 맞는 문제가 없습니다")
                .font(.headline)
                .foregroundStyle(Color.ink)
            Text("필터를 바꾸거나 검색어를 지워보세요.")
                .font(.callout)
                .foregroundStyle(Color.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func compactLabel(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color.paper, in: Capsule())
        .foregroundStyle(Color.ink)
    }

    private func chip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    selected ? Color.brand : Color.paper,
                    in: Capsule()
                )
                .foregroundStyle(selected ? Color.paper : Color.ink)
        }
        .buttonStyle(.plain)
    }

    private func toggleChip(
        title: String,
        icon: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                selected ? Color.brand.opacity(0.16) : Color.paper,
                in: Capsule()
            )
            .overlay(
                Capsule().stroke(selected ? Color.brand : Color.line, lineWidth: 1)
            )
            .foregroundStyle(selected ? Color.brandDeep : Color.inkSoft)
        }
        .buttonStyle(.plain)
    }

    private func startPractice() {
        guard let first = filteredQuestions.first else { return }
        start(at: first)
    }

    private func start(at question: Question) {
        guard let index = filteredQuestions.firstIndex(of: question) else { return }
        presented = SessionPresenter(
            session: StudySession(questions: filteredQuestions, startIndex: index)
        )
    }
}

struct QuestionRowContent: View {
    let question: Question
    let solved: Bool
    let bookmarked: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(solved ? Color.brand : Color.paper)
                Text(String(format: "%02d", question.number))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(solved ? Color.paper : Color.brandDeep)
                    .monospacedDigit()
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(question.subject)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brand)
                    Text("·")
                        .foregroundStyle(Color.inkSoft)
                    Text(String(question.year) + "년 " + question.grade)
                        .font(.caption)
                        .foregroundStyle(Color.inkSoft)
                    if question.hasVisual {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.caption2)
                            .foregroundStyle(Color.inkSoft)
                    }
                }
                Text(question.preview)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                if bookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(Color.brand)
                }
                if solved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.brand)
                }
            }
            .frame(width: 18)
        }
        .examCard(padding: 14)
        .contentShape(Rectangle())
    }
}

struct QuestionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bank: BankStore
    @EnvironmentObject private var progress: ProgressStore
    let question: Question

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let url = bank.imageURL(for: question) {
                    AsyncQuestionImage(url: url)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.line, lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("문제 텍스트")
                        .font(.headline)
                    Text(question.stem)
                        .font(.callout)
                        .foregroundStyle(Color.ink)
                        .textSelection(.enabled)
                    ForEach(question.choices.indices, id: \.self) { offset in
                        HStack(alignment: .top, spacing: 8) {
                            Text(Question.choiceSymbols[min(offset, 4)])
                                .foregroundStyle(Color.brand)
                            Text(question.choices[offset])
                                .foregroundStyle(Color.ink)
                        }
                        .font(.callout)
                    }
                }
                .examCard()

                if let answer = question.answer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("정답 \(Question.choiceSymbols[answer - 1])")
                            .font(.headline)
                            .foregroundStyle(Color.brandDeep)
                        if let explanation = question.explanation, !explanation.isEmpty {
                            Text(explanation)
                                .font(.callout)
                                .foregroundStyle(Color.ink)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .examCard()
                }
            }
            .padding(20)
        }
        .background(Color.paper.ignoresSafeArea())
        .navigationTitle("\(question.subject) \(question.number)번")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("닫기") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    progress.toggleBookmark(question.id)
                } label: {
                    Image(
                        systemName: progress.isBookmarked(question.id)
                            ? "bookmark.fill" : "bookmark"
                    )
                }
            }
        }
    }
}

struct AsyncQuestionImage: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.card)
                    .overlay(ProgressView())
                    .frame(height: 220)
            }
        }
        .task(id: url) {
            ImageLoader.shared.image(for: url) { loaded in
                self.image = loaded
            }
        }
    }
}
