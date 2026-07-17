import SwiftUI

struct RootView: View {
    @Environment(ProgramStore.self) private var programStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if programStore.onboardingComplete {
                HomeView()
            } else {
                OnboardingFlowView()
            }
        }
        .background(StokeTheme.cream.ignoresSafeArea())
        .task(id: programStore.onboardingComplete) {
            guard programStore.onboardingComplete else { return }
            HealthKitSyncCoordinator.shared.bind(programStore: programStore, modelContext: modelContext)
            HealthKitSyncCoordinator.shared.startObserversIfPossible()
        }
        .onChange(of: scenePhase) { _, phase in
            guard programStore.onboardingComplete else { return }
            guard phase == .active else { return }
            HealthKitSyncCoordinator.shared.scheduleDebouncedRefresh()
        }
    }
}
