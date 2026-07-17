import HealthKit
import SwiftData

/// Bridges HealthKit **background updates** (`HKObserverQuery` + background delivery entitlement) into
/// periodic `ProgramStore.refresh` runs, collapsed with a debounce so bursts of samples become one reload.
@MainActor
final class HealthKitSyncCoordinator {
    static let shared = HealthKitSyncCoordinator()

    private var programStore: ProgramStore?
    private var modelContext: ModelContext?
    private var observerQueries: [HKObserverQuery] = []
    private var didInstallObservers = false
    private var debounceTask: Task<Void, Never>?

    private init() {}

    /// Wire dependencies before starting observers or scheduling reloads (call from `RootView`).
    func bind(programStore: ProgramStore, modelContext: ModelContext) {
        self.programStore = programStore
        self.modelContext = modelContext
    }

    /// Register HealthKit observers once after onboarding completes.
    func startObserversIfPossible() {
        guard !didInstallObservers else { return }
        guard programStore?.onboardingComplete == true else { return }
        guard HealthKitService.shared.isAvailable else { return }

        didInstallObservers = true

        let types: [HKSampleType] = [
            HKQuantityType(.heartRate),
            HKQuantityType(.restingHeartRate),
        ]
        observerQueries = HealthKitService.shared.startObserverQueries(sampleTypes: types) { [weak self] in
            self?.scheduleDebouncedRefresh()
        }
    }

    /// Debounce multiple HK callbacks (HR + resting) and rapid foreground events into one `refresh`.
    func scheduleDebouncedRefresh() {
        guard programStore?.onboardingComplete == true else { return }
        guard modelContext != nil else { return }

        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 850_000_000)
            guard let self else { return }
            guard !Task.isCancelled else { return }
            await self.runRefreshUsingBindContext()
        }
    }

    private func runRefreshUsingBindContext() async {
        guard let programStore else { return }
        guard let modelContext else { return }
        await programStore.refresh(modelContext: modelContext)
    }
}
