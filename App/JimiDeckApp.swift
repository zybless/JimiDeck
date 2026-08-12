import SwiftUI

@main
struct JimiDeckApp: App {
    @StateObject private var model = AppModel.live()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(model)
                .frame(minWidth: 660, minHeight: 520)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 760, height: 680)
    }
}
