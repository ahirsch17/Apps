import HealthKit

/// Starts an indoor workout so watchOS keeps the app running / screen eligible
/// like Strava — no HR/GPS UI, just session lifetime.
@MainActor
final class WorkoutKeepAlive: NSObject {
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    func start() {
        guard session == nil else { return }
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let workoutType = HKObjectType.workoutType()
        store.requestAuthorization(toShare: [workoutType], read: []) { [weak self] success, _ in
            guard success else { return }
            Task { @MainActor in
                self?.beginSession()
            }
        }
    }

    private func beginSession() {
        guard session == nil else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .highIntensityIntervalTraining
        config.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)

            self.session = session
            self.builder = builder

            session.startActivity(with: .now)
            builder.beginCollection(withStart: .now) { _, _ in }
        } catch {
            session = nil
            builder = nil
        }
    }

    func stop() {
        guard let session else { return }
        let builder = self.builder
        self.session = nil
        self.builder = nil

        session.end()
        Task {
            try? await builder?.endCollection(at: .now)
            _ = try? await builder?.finishWorkout()
        }
    }
}
