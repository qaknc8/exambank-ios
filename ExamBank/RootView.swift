import SwiftUI

struct RootView: View {
    @EnvironmentObject private var bank: BankStore

    var body: some View {
        Group {
            if let error = bank.loadError {
                BankLoadErrorView(message: error)
            } else {
                TabView {
                    HomeView()
                        .tabItem { Label("홈", systemImage: "house.fill") }

                    NavigationStack {
                        LibraryView()
                    }
                    .tabItem { Label("문제", systemImage: "square.stack.3d.up.fill") }

                    SettingsView()
                        .tabItem { Label("설정", systemImage: "gearshape.fill") }
                }
            }
        }
        .task {
            bank.loadIfNeeded()
        }
    }
}

private struct BankLoadErrorView: View {
    let message: String

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                Text("문제은행을 불러오지 못했습니다")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.ink)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(Color.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
        }
    }
}

struct SessionPresenter: Identifiable {
    let id = UUID()
    let session: StudySession
}
