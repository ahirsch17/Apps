import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(ProgramStore.self) private var programStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WeekHistoryRecord.endDate, order: .reverse) private var history: [WeekHistoryRecord]
    @Query(sort: \WeekRecapRecord.endDate, order: .reverse) private var recaps: [WeekRecapRecord]

    @State private var showSettings = false
    @State private var showFamily = false
    @State private var selectedWeekDetail: WeekHistoryDetailItem?
    @State private var shareName = ""

    private var attemptNumbers: [Date: Int] {
        WeekHistoryFormatting.attemptNumbers(for: history)
    }

    private var lifetimePoints: Double {
        history.reduce(0) { $0 + $1.pointsEarned } + programStore.weekPoints
    }

    private var weeksCompleted: Int {
        history.filter(\.metTarget).count
    }

    private var milestones: [MilestoneBadge] {
        GamificationEngine.milestones(
            badgesEarned: programStore.badgesEarned,
            consecutiveWeeksMet: programStore.consecutiveWeeksMet,
            bestWeekStreak: programStore.bestWeekStreak,
            lifetimePoints: lifetimePoints,
            weeksCompleted: weeksCompleted
        )
    }

    var body: some View {
        NavigationStack {
            List {
                weekProgressSections

                Section {
                    TextField("Name on snapshot", text: $shareName)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                        .onSubmit { saveShareName() }
                    Button {
                        showFamily = true
                    } label: {
                        Label("Family progress", systemImage: "person.3.fill")
                    }
                    ShareProgressLink {
                        Label("Share my week", systemImage: "square.and.arrow.up")
                    }
                } footer: {
                    Text("Sends a weekly snapshot image. Set your name so the card does not say \"You\".")
                        .font(.caption2)
                        .foregroundStyle(StokeTheme.inkMuted)
                }
                .onAppear {
                    shareName = programStore.displayName
                }
                .onChange(of: shareName) { _, newValue in
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed == programStore.displayName { return }
                    if trimmed.isEmpty && programStore.displayName.isEmpty { return }
                    saveShareName()
                }

                achievementsSection

                Section {
                    Button("Zones & settings") {
                        showSettings = true
                    }
                }

                Section {
                    Text(MedicalDisclaimer.text)
                        .font(.footnote)
                        .foregroundStyle(StokeTheme.inkMuted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(StokeTheme.cream)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showFamily) {
                FamilyProgressSheet()
                    .presentationBackground(StokeTheme.cream)
            }
            .sheet(item: $selectedWeekDetail) { item in
                WeekHistoryDetailSheet(item: item)
                    .presentationBackground(StokeTheme.cream)
            }
        }
    }

    private func saveShareName() {
        programStore.updateDisplayName(shareName)
    }

    @ViewBuilder
    private var weekProgressSections: some View {
        Section {
            Button {
                selectedWeekDetail = .current(programStore: programStore)
            } label: {
                currentWeekHistoryRow
            }
            .buttonStyle(.plain)
        } header: {
            Text("This week")
        } footer: {
            Text("Only the weekly ring counts. Rest days are fine.")
                .font(.caption2)
                .foregroundStyle(StokeTheme.inkMuted)
        }

        if !history.isEmpty {
            Section {
                ForEach(history) { record in
                    Button {
                        let endDay = Calendar.current.startOfDay(for: record.endDate)
                        let attempt = attemptNumbers[endDay] ?? 1
                        selectedWeekDetail = .archived(
                            record: record,
                            recaps: recaps,
                            attempt: attempt,
                            showAttempt: WeekHistoryFormatting.showsAttemptLabel(
                                for: record.weekNumber,
                                records: history
                            )
                        )
                    } label: {
                        archivedWeekHistoryRow(record: record)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Past weeks")
            }
        }
    }

    @ViewBuilder
    private var achievementsSection: some View {
        Section {
            StreakSummaryView(
                consecutiveWeeks: programStore.consecutiveWeeksMet,
                bestStreak: programStore.bestWeekStreak
            )

            BadgeCabinetView(
                badgesEarned: programStore.badgesEarned,
                currentBadgeIndex: programStore.badgesEarned + 1,
                tilesCompleted: programStore.badgeTilesCompleted,
                tilesRequired: programStore.badgeTilesRequired
            )

            MilestoneBadgesRow(milestones: milestones)
        } header: {
            Text("Achievements")
        } footer: {
            Text("Tiles unlock when you hit a weekly goal.")
                .font(.caption2)
                .foregroundStyle(StokeTheme.inkMuted)
        }
    }

    private var currentWeekHistoryRow: some View {
        let period = programStore.currentPeriod
        return WeekHistoryRowView(
            dateRange: WeekHistoryFormatting.dateRange(start: period.start, end: period.end),
            weekTitle: WeekHistoryFormatting.weekTitle(
                weekNumber: programStore.weekNumber,
                attempt: 1,
                showAttempt: false
            ),
            isShortWeek: period.dayCount < 7,
            target: programStore.periodTarget,
            earned: programStore.weekPoints,
            inProgress: true,
            met: nil
        )
    }

    private func archivedWeekHistoryRow(record: WeekHistoryRecord) -> some View {
        let endDay = Calendar.current.startOfDay(for: record.endDate)
        let attempt = attemptNumbers[endDay] ?? 1

        return WeekHistoryRowView(
            dateRange: WeekHistoryFormatting.dateRange(start: record.startDate, end: record.endDate),
            weekTitle: WeekHistoryFormatting.weekTitle(
                weekNumber: record.weekNumber,
                attempt: attempt,
                showAttempt: WeekHistoryFormatting.showsAttemptLabel(for: record.weekNumber, records: history)
            ),
            isShortWeek: record.dayCount < 7,
            target: record.periodTarget,
            earned: record.pointsEarned,
            inProgress: false,
            met: record.metTarget
        )
    }
}

enum MedicalDisclaimer {
    static let short = "Not medical advice. Ask your doctor if you have heart concerns."

    static let text =
        "Wellness app only. Heart-rate zones are estimates. Ask your doctor if you take heart medication or have a heart condition."
}

struct SettingsView: View {
    @Environment(ProgramStore.self) private var programStore
    @Environment(\.dismiss) private var dismiss

    @State private var age: Int = 60
    @State private var gender: UserGender = .woman
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("About you") {
                    TextField("Display name (for sharing)", text: $name)
                        .textContentType(.name)
                    Picker("Age", selection: $age) {
                        ForEach(18...99, id: \.self) { Text("\($0)").tag($0) }
                    }
                    Picker("Gender", selection: $gender) {
                        ForEach(UserGender.allCases) { Text($0.displayName).tag($0) }
                    }
                }

                Section("Intensity & zones") {
                    Text(programStore.zones.intensityModelExplanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let rhr = programStore.restingHeartRateBpm {
                        LabeledContent("Resting HR (Health)", value: "\(Int(rhr.rounded())) bpm")
                    }
                    ForEach(programStore.zones.zoneDescriptions, id: \.name) { zone in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(zone.name)
                                .font(.subheadline.weight(.medium))
                            Text("\(zone.range) bpm · \(zone.points)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Max HR estimate (for reserve math): \(Int(programStore.zones.maxHR)) bpm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Health sync (this week)") {
                    LabeledContent("Week points (raw)", value: String(format: "%.1f", programStore.weekPoints))
                    LabeledContent("Expected so far", value: String(format: "%.1f", programStore.expectedPointsSoFar()))
                    LabeledContent("HR samples (last refresh)", value: "\(programStore.lastRefreshHeartRateSampleCount)")
                    if let refreshed = programStore.lastRefreshed {
                        LabeledContent("Last refresh", value: refreshed.formatted(date: .omitted, time: .shortened))
                    }
                }

                Section {
                    Text(MedicalDisclaimer.text)
                        .font(.footnote)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        programStore.updateProfile(age: age, gender: gender, displayName: name)
                        dismiss()
                    }
                }
            }
            .onAppear {
                age = programStore.age
                gender = programStore.gender
                name = programStore.displayName
            }
        }
    }
}
