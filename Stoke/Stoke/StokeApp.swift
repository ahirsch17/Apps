import SwiftData
import SwiftUI

@main
struct StokeApp: App {
    init() {
        PickerContrast.applyUIPickerLabels()
    }

    @State private var programStore = ProgramStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(programStore)
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [WeekHistoryRecord.self, DayPointsRecord.self, WeekRecapRecord.self])
    }
}
