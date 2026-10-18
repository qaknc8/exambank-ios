import Foundation
import SwiftUI
import UIKit

struct SessionView: View {
    let session: StudySession

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bank: BankStore
    @EnvironmentObject private var progress: ProgressStore

    @State private var index: Int
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var showAnswer = false
    @State private var showExitConfirm = false

    init(session: StudySession) {
        self.session = session
        _index = State(initialValue: min(session.startIndex, max(0, session.questions.count - 1)))
    }

    private var question: Question? {
        guard session.questions.indices.contains(index) else { return nil }
        return session.questions[index]
    }

    private var selectedChoice: Int? {
        question.flatMap { progress.choice(for: $0.id) }
    }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                imageArea
                bottomPanel
            }
        }
        .task(id: index) {
            loadImage()
        }
        .confirmationDialog(
            "풀이를 그만둘까요?",
            isPresented: $showExitConfirm,
            titleVisibility: .visible
        ) {
            Button("그만두기", role: .destructive) { dismiss() }
            Button("계속 풀기", role: .cancel) {}
        }
        .sheet(isPresented: $showAnswer) {
            if let question {
                AnswerSheet(question: question)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                showExitConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.bold))
                    .frame(width: 34, height: 34)
                    .background(Color.paper, in: Circle())
                    .foregroundStyle(Color.ink)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(question.map { "\($0.subject) · " + String($0.year) + "년" } ?? "문제")
                    .font(.caption)
                    .foregroundStyle(Color.inkSoft)
                Text(String(index + 1) + " / " + String(session.questions.count))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.ink)
                    .monospacedDigit()
            }

            Spacer()

            if let question {
                Button {
                    progress.toggleBookmark(question.id)
                } label: {
                    Image(
                        systemName: progress.isBookmarked(question.id)
                            ? "bookmark.fill" : "bookmark"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.paper, in: Circle())
                    .foregroundStyle(
                        progress.isBookmarked(question.id) ? Color.brand : Color.inkSoft
                    )
                }
                .buttonStyle(.plain)

                if question.answer != nil {
                    Button {
                        showAnswer = true
                    } label: {
                        Image(systemName: "text.book.closed")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 34, height: 34)
                            .background(Color.paper, in: Circle())
                            .foregroundStyle(Color.inkSoft)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var imageArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.card)

            if let image {
                ZoomableQuestionImage(image: image, resetToken: index + 1)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(alignment: .bottomTrailing) {
                        Label("두 번 탭 확대", systemImage: "plus.magnifyingglass")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundStyle(Color.inkSoft)
                            .padding(10)
                            .allowsHitTesting(false)
                    }
            } else if isLoading {
                ProgressView()
                    .tint(.brand)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(Color.inkSoft)
                    Text("이미지를 불러오지 못했습니다")
                        .font(.footnote)
                        .foregroundStyle(Color.inkSoft)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.line, lineWidth: 1)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            if let question {
                HStack {
                    Text("문 \(String(format: "%02d", question.number))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.brandDeep)
                    Text(question.grade)
                        .font(.caption)
                        .foregroundStyle(Color.inkSoft)
                    Spacer()
                    if progress.isSolved(question.id) {
                        Label("완료", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brand)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { choice in
                        choiceButton(choice, selected: selectedChoice == choice) {
                            progress.setChoice(choice, for: question.id)
                        }
                    }
                }

                HStack(spacing: 12) {
                    navButton(
                        icon: "chevron.left",
                        label: "이전",
                        enabled: index > 0
                    ) {
                        go(to: index - 1)
                    }

                    Button {
                        progress.toggleSolved(question.id)
                    } label: {
                        Label(
                            progress.isSolved(question.id) ? "완료 취소" : "완료 표시",
                            systemImage: progress.isSolved(question.id)
                                ? "arrow.uturn.backward" : "checkmark"
                        )
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            progress.isSolved(question.id)
                                ? Color.paper : Color.brand.opacity(0.14),
                            in: Capsule()
                        )
                        .foregroundStyle(
                            progress.isSolved(question.id) ? Color.inkSoft : Color.brandDeep
                        )
                    }
                    .buttonStyle(.plain)

                    navButton(
                        icon: "chevron.right",
                        label: "다음",
                        enabled: index < session.questions.count - 1,
                        trailingIcon: true
                    ) {
                        go(to: index + 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 22,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 22,
                style: .continuous
            )
            .fill(Color.card)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func choiceButton(
        _ choice: Int,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(Question.choiceSymbols[choice - 1])
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    selected ? Color.brand : Color.paper,
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(selected ? Color.brand : Color.line, lineWidth: 1)
                )
                .foregroundStyle(selected ? Color.paper : Color.ink)
        }
        .buttonStyle(.plain)
    }

    private func navButton(
        icon: String,
        label: String,
        enabled: Bool,
        trailingIcon: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if !trailingIcon {
                    Image(systemName: icon)
                }
                Text(label)
                if trailingIcon {
                    Image(systemName: icon)
                }
            }
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.paper, in: Capsule())
            .foregroundStyle(enabled ? Color.ink : Color.inkSoft.opacity(0.4))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func go(to newIndex: Int) {
        guard session.questions.indices.contains(newIndex) else { return }
        index = newIndex
    }

    private func currentQuestionID() -> String? {
        session.questions.indices.contains(index) ? session.questions[index].id : nil
    }

    private func loadImage() {
        guard let question, let url = bank.imageURL(for: question) else {
            image = nil
            isLoading = false
            return
        }
        image = nil
        isLoading = true
        progress.markVisited(question.id)
        let requestedID = question.id
        ImageLoader.shared.image(for: url) { loaded in
            guard self.currentQuestionID() == requestedID else { return }
            self.image = loaded
            self.isLoading = false
        }
    }
}

private struct AnswerSheet: View {
    let question: Question

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let answer = question.answer {
                        HStack(spacing: 10) {
                            Text("정답")
                                .font(.headline)
                                .foregroundStyle(Color.inkSoft)
                            Text(Question.choiceSymbols[answer - 1])
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.brand)
                        }
                    }
                    if let explanation = question.explanation, !explanation.isEmpty {
                        Text(explanation)
                            .font(.body)
                            .foregroundStyle(Color.ink)
                            .textSelection(.enabled)
                    } else {
                        Text("등록된 해설이 없습니다.")
                            .font(.callout)
                            .foregroundStyle(Color.inkSoft)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .background(Color.paper.ignoresSafeArea())
            .navigationTitle("정답 및 해설")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
