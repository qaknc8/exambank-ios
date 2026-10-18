import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var bank: BankStore
    @EnvironmentObject private var progress: ProgressStore
    @State private var confirmReset = false

    private var solvedCount: Int {
        bank.questions.filter { progress.isSolved($0.id) }.count
    }

    private var bookmarkedCount: Int {
        progress.bookmarkedIDs.count
    }

    private var answeredBankCount: Int {
        bank.answeredCount
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.paper.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        statsCard
                        bankCard
                        resetCard
                        aboutCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "학습 기록을 모두 지울까요?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("모두 지우기", role: .destructive) {
                    progress.reset()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("완료 표시, 북마크, 선택한 답안이 모두 삭제됩니다.")
            }
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("학습 기록")
                .font(.headline)
                .foregroundStyle(Color.ink)
            HStack(spacing: 12) {
                statTile(value: "\(solvedCount)", label: "푼 문제", icon: "checkmark.circle")
                statTile(value: "\(bookmarkedCount)", label: "북마크", icon: "bookmark")
                statTile(value: "\(bank.questions.count)", label: "전체", icon: "square.stack")
            }
        }
        .examCard()
    }

    private var bankCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("문제은행")
                .font(.headline)
                .foregroundStyle(Color.ink)

            infoRow("과목", bank.subjects.map(\.name).joined(separator: ", "))
            infoRow("시험", bank.grades.map(\.name).joined(separator: ", "))
            infoRow("문항", String(bank.questions.count) + "문제")
            infoRow("정답 등록", String(answeredBankCount) + "문제")
            if let generated = bank.manifest?.sourceGeneratedAt {
                infoRow("은행 생성", String(generated.prefix(10)))
            }
            if let version = bank.manifest?.version {
                infoRow("형식 버전", String(version))
            }

            Text("문제 이미지와 텍스트를 추가하려면 tools/build_question_bank.py로 문제은행을 다시 만든 뒤 tools/sync_ios_assets.py를 실행하고 앱을 다시 빌드하세요.")
                .font(.caption)
                .foregroundStyle(Color.inkSoft)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .examCard()
    }

    private var resetCard: some View {
        Button {
            confirmReset = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("학습 기록 초기화")
                Spacer()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.red)
            .examCard(padding: 16)
        }
        .buttonStyle(.plain)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ExamBank")
                .font(.headline)
                .foregroundStyle(Color.ink)
            Text("5급 PSAT 기출을 아이폰에서 과목·연도별로 골라 푸는 개인용 학습 앱입니다. 모든 데이터는 기기 안에만 저장됩니다.")
                .font(.caption)
                .foregroundStyle(Color.inkSoft)
            Text("정답·해설은 answers/answers.json에 추가하면 자동으로 반영됩니다.")
                .font(.caption)
                .foregroundStyle(Color.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .examCard()
    }

    private func statTile(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.brand)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Color.ink)
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.paper, in: RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Color.inkSoft)
                .frame(width: 76, alignment: .leading)
            Text(value)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.ink)
            Spacer(minLength: 0)
        }
    }
}
