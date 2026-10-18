import SwiftUI

@main
struct ExamBankApp: App {
    @StateObject private var bank = BankStore()
    @StateObject private var progress = ProgressStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(bank)
                .environmentObject(progress)
                .tint(.brand)
        }
    }
}
