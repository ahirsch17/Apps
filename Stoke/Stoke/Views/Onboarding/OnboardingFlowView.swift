import SwiftData
import SwiftUI
import UIKit

struct OnboardingFlowView: View {
    @Environment(ProgramStore.self) private var programStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var step = 0
    @State private var firstName = ""
    @State private var age = 60
    @State private var gender: UserGender = .woman
    @State private var activity: ActivityLevel = .sedentary
    @State private var isCalibrating = false
    @State private var fullWeeklyGoal = 52
    @State private var thisWeekGoal = 52
    @State private var usedHealthData = false
    @State private var healthNotice: String?
    @State private var errorMessage: String?
    @State private var isFinishingOnboarding = false

    private var prospectivePeriod: WeekPeriod {
        WeekPeriod.current(onboardingDate: Date())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressDots
                    .padding(.top, 16)

                TabView(selection: $step) {
                    welcomeStep.tag(0)
                    ageStep.tag(1)
                    genderStep.tag(2)
                    activityStep.tag(3)
                    healthStep.tag(4)
                    readyStep.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)
            }
            .background(StokeTheme.cream)
            .navigationBarHidden(true)
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(index <= step ? StokeTheme.terracotta : StokeTheme.paceTrack)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var welcomeStep: some View {
        onboardingPage(
            title: "Stoke",
            subtitle: "Build your cardiovascular engine, week by week."
        ) {
            primaryButton("Get started") { step = 1 }
        }
    }

    private var ageStep: some View {
        onboardingPage(
            title: "Your age",
            subtitle: nil
        ) {
            Picker("Age", selection: $age) {
                ForEach(18...99, id: \.self) { value in
                    Text("\(value)")
                        .foregroundStyle(StokeTheme.ink)
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 168)
            .readableWheelPickerChrome()
            primaryButton("Continue") { step = 2 }
        }
    }

    private var genderStep: some View {
        onboardingPage(
            title: "Sex",
            subtitle: nil
        ) {
            VStack(spacing: 12) {
                ForEach(UserGender.allCases) { option in
                    selectionRow(option.displayName, selected: gender == option) {
                        gender = option
                    }
                }
            }
            primaryButton("Continue") { step = 3 }
        }
    }

    private var activityStep: some View {
        onboardingPage(
            title: "How active lately?",
            subtitle: nil
        ) {
            VStack(spacing: 12) {
                ForEach(ActivityLevel.allCases) { level in
                    selectionRow(level.displayName, selected: activity == level) {
                        activity = level
                    }
                }
            }
            primaryButton("Continue") { step = 4 }
        }
    }

    private var healthStep: some View {
        onboardingPage(
            title: "Apple Health",
            subtitle: "Stoke uses your heart-rate data here. Tap Allow below to continue."
        ) {
            Text(MedicalDisclaimer.short)
                .font(.caption2)
                .foregroundStyle(StokeTheme.inkMuted)
                .multilineTextAlignment(.center)

            if let errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.subheadline)
                .padding(.top, 4)
            }
            primaryButton(isCalibrating ? "Connecting..." : "Allow Apple Health access") {
                Task { await connectHealth() }
            }
            .disabled(isCalibrating)
        }
    }

    private var readyStep: some View {
        onboardingPage(
            title: "Week 1",
            subtitle: readySubtitle
        ) {
            VStack(spacing: 8) {
                Text("\(thisWeekGoal)")
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .foregroundStyle(StokeTheme.terracottaDeep)
                Text(prospectivePeriod.dayCount < 7 ? "pts through Saturday" : "points this week")
                    .font(.title3)
                    .foregroundStyle(StokeTheme.inkMuted)
                if prospectivePeriod.dayCount < 7 {
                    Text("All cycles end Saturday.")
                        .font(.subheadline)
                        .foregroundStyle(StokeTheme.inkMuted)
                        .multilineTextAlignment(.center)
                    Text("Your first 7-day cycle starts this upcoming \(prospectivePeriod.formattedSundayStartingNextSevenDayCycle()).")
                        .font(.subheadline)
                        .foregroundStyle(StokeTheme.inkMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 6) {
                Text("Your first name")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(StokeTheme.ink)
                TextField("First name", text: $firstName)
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(Color.white.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text("Shows on weekly snapshots you share. Optional.")
                    .font(.caption)
                    .foregroundStyle(StokeTheme.inkMuted)
            }

            primaryButton(isFinishingOnboarding ? "Opening..." : "Start") {
                Task { await finishOnboarding() }
            }
            .disabled(isFinishingOnboarding)
        }
    }

    private var readySubtitle: String? {
        if let healthNotice {
            return healthNotice
        }
        if usedHealthData {
            return "From Apple Health."
        }
        return nil
    }

    private func onboardingPage<Content: View>(
        title: String,
        subtitle: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(StokeTheme.ink)
                    .multilineTextAlignment(.center)
                if let subtitle {
                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(StokeTheme.inkMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 28)

            content()
                .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func selectionRow(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundStyle(StokeTheme.ink)
                    .multilineTextAlignment(.leading)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(StokeTheme.terracotta)
                }
            }
            .padding(16)
            .background(selected ? StokeTheme.parchment : Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(StokeTheme.terracotta)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.top, 8)
    }

    private func finishOnboarding() async {
        isFinishingOnboarding = true
        defer { isFinishingOnboarding = false }

        let trimmedName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        programStore.completeOnboarding(
            age: age,
            gender: gender,
            activity: activity,
            weeklyTarget: fullWeeklyGoal,
            displayName: trimmedName.isEmpty ? nil : trimmedName
        )
        await programStore.refresh(modelContext: modelContext)
    }

    private func applyCalibration(history: [Date: Double], assessment: HealthDataAssessment) {
        healthNotice = assessment.onboardingNotice
        usedHealthData = assessment.isReliable
        fullWeeklyGoal = OnboardingCalibrator.suggestedWeeklyTarget(
            age: age,
            activityLevel: activity,
            healthDailyAverages: Array(history.values),
            healthDataReliable: assessment.isReliable
        )
        thisWeekGoal = prospectivePeriod.targetForWeek(fullTarget: fullWeeklyGoal)
    }

    private func connectHealth() async {
        isCalibrating = true
        errorMessage = nil
        defer { isCalibrating = false }

        do {
            try await HealthKitService.shared.requestAuthorization()
            let resting = try? await HealthKitService.shared.medianRestingHeartRateBpm()
            let zones = HeartRateZones.compute(age: age, gender: gender, restingHeartRate: resting)
            let history = try await HealthKitService.shared.dailyPointsHistory(days: 14, zones: zones)
            let assessment = HealthDataAssessment.analyze(dailyPoints: history, daysQueried: 14)
            applyCalibration(history: history, assessment: assessment)
            step = 5
        } catch {
            let desc = error.localizedDescription.isEmpty ? "Could not reach Apple Health." : error.localizedDescription
            errorMessage =
                "\(desc) If you tapped Don't Allow, open Settings, Health, Apps, Stoke, and turn on Heart Rate."
        }
    }
}
