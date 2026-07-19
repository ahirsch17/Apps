import EventKit
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var pastedText = ""
    @State private var events: [EditableScheduleEvent] = []
    @State private var semesterEnd = Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
    @State private var useCustomSemesterEnd = false
    @State private var parseOutcome: ParseOutcome = .none
    @State private var isImporting = false
    @State private var importNote: String?
    @State private var destination: CalendarDestination = .apple
    @State private var calendars: [EKCalendar] = []
    @State private var selectedCalendarID: String?
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @Environment(\.colorScheme) private var colorScheme

    private let eventStore = EKEventStore()
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    private let parseFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let importFeedback = UINotificationFeedbackGenerator()

    private var selectedEvents: [EditableScheduleEvent] {
        events.filter(\.isSelected)
    }

    private var selectedNeedingDays: Int {
        selectedEvents.filter(\.needsWeekdayPick).count
    }

    private var selectedImportable: [EditableScheduleEvent] {
        selectedEvents.filter(\.canAddToCalendar)
    }

    private var selectedCalendar: EKCalendar? {
        guard let id = selectedCalendarID else { return CalendarImportService.defaultCalendar(eventStore: eventStore) }
        return calendars.first { $0.calendarIdentifier == id } ?? CalendarImportService.defaultCalendar(eventStore: eventStore)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        inputBlock
                        parseBanner
                        semesterRow
                        if events.isEmpty == false {
                            actionsRow
                            eventCards
                            destinationBlock
                            importBlock
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
        }
        .tint(accent)
        .onAppear {
            parseFeedback.prepare()
            importFeedback.prepare()
            refreshCalendars()
        }
        .onChange(of: pastedText) { _, new in
            if new.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                events = []
                parseOutcome = .none
                importNote = nil
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ActivityView(activityItems: [shareURL])
            }
        }
    }

    private var accent: Color {
        Color(red: 0.25, green: 0.52, blue: 1.0)
    }

    private var backgroundGradient: LinearGradient {
        let top = colorScheme == .dark
            ? Color(red: 0.07, green: 0.08, blue: 0.12)
            : Color(red: 0.94, green: 0.95, blue: 0.98)
        let bottom = colorScheme == .dark
            ? Color.black
            : Color(red: 0.88, green: 0.90, blue: 0.96)
        return LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }

    private var inputBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Paste your schedule")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextEditor(text: $pastedText)
                .frame(height: 200)
                .font(.body.monospaced())
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.85))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text("Banner, VT table, timetable, or Mon–Sun grid. Lab and lecture each become one row. Supports TR / TuTh / M/W/F and 12h or 24h times.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(action: pasteAndScan) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)

                Button(action: parse) {
                    Text("Parse")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    @ViewBuilder
    private var parseBanner: some View {
        switch parseOutcome {
        case .none:
            EmptyView()
        case .empty:
            Text("No meetings found")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.orange.opacity(colorScheme == .dark ? 0.2 : 0.14))
                )
        case let .found(meetings, courses, needs, tba):
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(parseSummaryLine(meetings: meetings, courses: courses))
                        .font(.subheadline.weight(.semibold))
                    if needs > 0 {
                        Spacer(minLength: 8)
                        Text("\(needs) need days")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
                if tba > 0 {
                    Text("\(tba) TBA / async — not added to calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(accent.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private var semesterRow: some View {
        HStack {
            Toggle("Last day", isOn: $useCustomSemesterEnd)
                .font(.subheadline.weight(.medium))
            if useCustomSemesterEnd {
                Spacer()
                DatePicker("", selection: $semesterEnd, displayedComponents: .date)
                    .labelsHidden()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.55))
        )
    }

    private var actionsRow: some View {
        HStack(spacing: 12) {
            Button("All") {
                for i in events.indices where events[i].isTBA == false {
                    events[i].isSelected = true
                }
            }
            .buttonStyle(.bordered)

            Button("None") {
                for i in events.indices { events[i].isSelected = false }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
    }

    private var eventCards: some View {
        VStack(spacing: 14) {
            ForEach($events) { $ev in
                EventEditorRow(event: $ev, weekdaySymbols: weekdaySymbols, accent: accent, colorScheme: colorScheme)
            }
        }
    }

    private var destinationBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add to")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Destination", selection: $destination) {
                ForEach(CalendarDestination.allCases) { dest in
                    Text(dest.title).tag(dest)
                }
            }
            .pickerStyle(.segmented)

            Text(destination.detail)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            if destination.usesEventKit {
                if calendars.isEmpty {
                    Text("Grant calendar access when you tap the button below, then pick a calendar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Calendar", selection: Binding(
                        get: { selectedCalendarID ?? calendars.first?.calendarIdentifier ?? "" },
                        set: { selectedCalendarID = $0 }
                    )) {
                        ForEach(calendars, id: \.calendarIdentifier) { cal in
                            Text(calendarLabel(cal)).tag(cal.calendarIdentifier)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.55))
        )
    }

    private var importBlock: some View {
        VStack(spacing: 10) {
            Button {
                Task { await importToCalendar() }
            } label: {
                Group {
                    if isImporting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(importTitle)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
            .disabled(isImporting || selectedImportable.isEmpty || selectedNeedingDays > 0)

            if let importNote {
                Text(importNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
    }

    private var importTitle: String {
        if selectedNeedingDays > 0 { return "Pick days first" }
        if selectedImportable.isEmpty { return "Select meetings" }
        switch destination {
        case .apple: return "Add to Apple Calendar"
        case .google: return "Share for Google Calendar"
        case .both: return "Add + Share for Google"
        }
    }

    private func calendarLabel(_ cal: EKCalendar) -> String {
        let source = cal.source.title
        if source.isEmpty { return cal.title }
        return "\(cal.title) (\(source))"
    }

    private func parseSummaryLine(meetings: Int, courses: Int?) -> String {
        let m = meetings == 1 ? "1 meeting" : "\(meetings) meetings"
        guard let c = courses, c != meetings else { return m }
        let cStr = c == 1 ? "1 class" : "\(c) classes"
        return "\(m) · \(cStr)"
    }

    private func pasteAndScan() {
        if let s = UIPasteboard.general.string {
            pastedText = s
            parse()
        }
    }

    private func parse() {
        importNote = nil
        let endOverride = useCustomSemesterEnd ? semesterEnd : nil
        let parsed = ScheduleTextParser.parse(pastedText, defaultSemesterEnd: endOverride)
        events = parsed

        if parsed.isEmpty {
            parseOutcome = .empty
            importFeedback.notificationOccurred(.warning)
        } else {
            parseOutcome = .found(
                meetings: parsed.count,
                courses: ScheduleTextParser.distinctRegisteredCourseCount(in: parsed),
                needs: parsed.filter(\.needsWeekdayPick).count,
                tba: parsed.filter(\.isTBA).count
            )
            parseFeedback.impactOccurred()
        }
    }

    private func refreshCalendars() {
        calendars = CalendarImportService.writableCalendars(eventStore: eventStore)
        if selectedCalendarID == nil {
            selectedCalendarID = CalendarImportService.defaultCalendar(eventStore: eventStore)?.calendarIdentifier
                ?? calendars.first?.calendarIdentifier
        }
    }

    @MainActor
    private func importToCalendar() async {
        importNote = nil
        isImporting = true
        defer { isImporting = false }

        let plans = CalendarEventPlanner.blueprints(from: selectedImportable)
        guard plans.isEmpty == false else {
            importFeedback.notificationOccurred(.warning)
            importNote = "Select rows with days and real meeting times"
            return
        }

        do {
            var saved = 0
            if destination.usesEventKit {
                let ok = try await CalendarImportService.requestAccess(eventStore: eventStore)
                guard ok else {
                    importFeedback.notificationOccurred(.error)
                    importNote = "Calendars off — Settings → Schedule"
                    return
                }
                refreshCalendars()
                saved = try CalendarImportService.save(
                    blueprints: plans,
                    eventStore: eventStore,
                    calendar: selectedCalendar
                )
            }

            if destination.usesICSShare {
                let url = try ICSCalendarExport.writeTemporaryFile(from: plans)
                shareURL = url
                showShareSheet = true
            }

            importFeedback.notificationOccurred(saved > 0 || destination.usesICSShare ? .success : .warning)
            if destination.usesEventKit {
                if saved > 0 {
                    let calName = selectedCalendar?.title ?? "Calendar"
                    importNote = destination.usesICSShare
                        ? "Added \(saved) to \(calName). Share the .ics into Google Calendar."
                        : "Added \(saved) to \(calName)."
                    events = []
                    parseOutcome = .none
                } else if destination == .apple {
                    importNote = "Select rows with days picked"
                }
            } else {
                importNote = "Open the .ics in Google Calendar (or any calendar app)."
                events = []
                parseOutcome = .none
            }
        } catch {
            importFeedback.notificationOccurred(.error)
            importNote = error.localizedDescription
        }
    }
}

private enum ParseOutcome: Equatable {
    case none
    case empty
    /// `meetings` = calendar rows. `courses` = distinct CRNs when any notes include a CRN.
    case found(meetings: Int, courses: Int?, needs: Int, tba: Int)
}

private struct EventEditorRow: View {
    @Binding var event: EditableScheduleEvent
    let weekdaySymbols: [String]
    let accent: Color
    let colorScheme: ColorScheme

    private let weekdayOrder = [1, 2, 3, 4, 5, 6, 7]
    @State private var showDetailFields = false

    private var needsDays: Bool { event.needsWeekdayPick }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $event.isSelected) {
                Text(event.title)
                    .font(.headline.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
            }
            .tint(accent)
            .disabled(event.isTBA)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.displayTimeRange())
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                Text(event.displaySemesterRange())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if event.location.isEmpty == false {
                    Text(event.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let kind = event.sessionKind {
                Text(kind)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if event.isTBA {
                Text("No timed meetings — skipped for calendar import.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                HStack(spacing: 5) {
                    ForEach(weekdayOrder, id: \.self) { wd in
                        let on = event.weekdays.contains(wd)
                        Button {
                            if on { event.weekdays.remove(wd) }
                            else { event.weekdays.insert(wd) }
                        } label: {
                            Text(shortSymbol(for: wd))
                                .font(.caption.weight(.bold))
                                .frame(width: 34, height: 34)
                                .background(
                                    Circle().fill(on ? accent : (needsDays ? Color.orange.opacity(0.18) : Color.primary.opacity(0.07)))
                                )
                                .foregroundStyle(on ? Color.white : .primary)
                                .overlay(
                                    Circle()
                                        .stroke(needsDays && !on ? Color.orange.opacity(0.55) : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            DisclosureGroup(isExpanded: $showDetailFields) {
                TextField("Title", text: $event.title)
                TextField("Location", text: $event.location)
            } label: {
                Text("Edit")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.07) : Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    needsDays || event.isTBA ? Color.orange.opacity(0.45) : Color.primary.opacity(0.06),
                    lineWidth: needsDays || event.isTBA ? 1.5 : 1
                )
        )
    }

    private func shortSymbol(for weekday: Int) -> String {
        guard weekday >= 1, weekday <= weekdaySymbols.count else { return "?" }
        return String(weekdaySymbols[weekday - 1].prefix(1))
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
