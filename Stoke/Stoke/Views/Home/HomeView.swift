import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(ProgramStore.self) private var programStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var showProfile = false
    @State private var showFamily = false

    var body: some View {
        NavigationStack {
            ZStack {
                StokeTheme.cream
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if programStore.consecutiveWeeksMet >= 2 {
                            streakChip
                        }
                        todayCard
                        weekSection
                        paceLine
                        if let error = programStore.refreshError {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .refreshable {
                    await programStore.refresh(modelContext: modelContext)
                }
            }
            .toolbarBackground(StokeTheme.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Week \(programStore.weekNumber)")
                        .font(.system(.headline, design: .serif))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFamily = true
                    } label: {
                        Image(systemName: "person.3")
                            .font(.body)
                            .foregroundStyle(StokeTheme.terracottaDeep)
                    }
                    .accessibilityLabel("Family")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundStyle(StokeTheme.terracottaDeep)
                    }
                    .accessibilityLabel("Profile")
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .presentationBackground(StokeTheme.cream)
            }
            .sheet(isPresented: $showFamily) {
                FamilyProgressSheet()
                    .presentationBackground(StokeTheme.cream)
            }
            .task {
                await programStore.refresh(modelContext: modelContext)
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task {
                    await programStore.refresh(modelContext: modelContext)
                }
            }
            .onChange(of: showProfile) { _, showing in
                guard !showing else { return }
                Task {
                    await programStore.refresh(modelContext: modelContext)
                }
            }
        }
    }

    private var streakChip: some View {
        Label("\(programStore.consecutiveWeeksMet) week streak", systemImage: "flame.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(StokeTheme.sage)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    private var todayCard: some View {
        VStack(spacing: 4) {
            Text("Today")
                .font(.subheadline)
                .foregroundStyle(StokeTheme.inkMuted)
            Text("\(Int(programStore.todayPoints.rounded()))")
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundStyle(StokeTheme.terracottaDeep)
            Text("points")
                .font(.footnote)
                .foregroundStyle(StokeTheme.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .stokeCard()
    }

    private var weekSection: some View {
        VStack(spacing: 16) {
            TimelineView(.periodic(from: .now, by: 60.0)) { context in
                WeekProgressRingView(
                    actualFraction: programStore.actualProgressFraction(),
                    paceDisplayFraction: programStore.paceRingDisplayFraction(now: context.date),
                    weekPoints: Int(programStore.weekPoints.rounded()),
                    periodTarget: programStore.periodTarget
                )
            }

            HStack(spacing: 16) {
                legendItem(color: StokeTheme.progressFill, label: "You")
                legendItem(color: StokeTheme.paceFill, label: "Pace")
            }
            .font(.caption)
            .foregroundStyle(StokeTheme.inkMuted)

            DayTilesView(
                dates: programStore.currentPeriod.datesInPeriod(),
                pointsByDay: programStore.dayPointsInPeriod
            )

            if let caption = programStore.goalCaption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(StokeTheme.inkMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .stokeCard()
    }

    private var paceLine: some View {
        TimelineView(.periodic(from: .now, by: 60.0)) { context in
            Text(programStore.paceStatus(now: context.date))
                .font(.body.weight(.medium))
                .foregroundStyle(StokeTheme.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}
