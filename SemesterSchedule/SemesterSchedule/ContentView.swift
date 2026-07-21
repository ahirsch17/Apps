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
    @State private var appeared = false
    @State private var parsePulse = false

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
                AtmosphereBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)

                        inputBlock
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)

                        parseBanner
                            .scaleEffect(parsePulse ? 1.02 : 1)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: parsePulse)

                        semesterRow

                        if events.isEmpty == false {
                            actionsRow
                            eventCards
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)).combined(with: .offset(y: 12)),
                                    removal: .opacity
                                ))
                            destinationBlock
                            importBlock
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                    .animation(.spring(response: 0.45, dampingFraction: 0.86), value: events.count)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(ScheduleTheme.teal)
        .onAppear {
            parseFeedback.prepare()
            importFeedback.prepare()
            refreshCalendars()
            withAnimation(.easeOut(duration: 0.45)) { appeared = true }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Schedule")
                .font(ScheduleTheme.brandFont)
                .foregroundStyle(ScheduleTheme.ink)
                .tracking(-0.5)

            Text("Paste a semester → review → add to your calendar.")
                .font(ScheduleTheme.bodyFont)
                .foregroundStyle(ScheduleTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }

    private var inputBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PASTE")
                .font(ScheduleTheme.sectionFont)
                .foregroundStyle(ScheduleTheme.inkMuted)
                .tracking(1.2)

            ZStack(alignment: .topLeading) {
                if pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Banner · VT table · timetable · weekly grid")
                        .font(ScheduleTheme.monoFont)
                        .foregroundStyle(ScheduleTheme.inkMuted.opacity(0.55))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $pastedText)
                    .frame(minHeight: 168)
                    .font(ScheduleTheme.monoFont)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .foregroundStyle(ScheduleTheme.ink)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ScheduleTheme.surfaceSolid)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(ScheduleTheme.hairline, lineWidth: 1)
            )

            HStack(spacing: 10) {
                Button(action: pasteAndScan) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(SoftButtonStyle())

                Button(action: parse) {
                    Text("Parse")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(PrimaryButtonStyle())
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
            statusChip(
                text: "No meetings found",
                tone: .warn
            )
        case let .found(meetings, courses, needs, tba):
            VStack(alignment: .leading, spacing: 6) {
                Text(parseSummaryLine(meetings: meetings, courses: courses))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(ScheduleTheme.ink)
                if needs > 0 {
                    Text("\(needs) need weekdays tapped below")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(ScheduleTheme.amber)
                }
                if tba > 0 {
                    Text("\(tba) TBA / async — skipped for calendar")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(ScheduleTheme.inkMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ScheduleTheme.teal.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(ScheduleTheme.teal.opacity(0.22), lineWidth: 1)
            )
        }
    }

    private var semesterRow: some View {
        HStack(spacing: 12) {
            Toggle(isOn: $useCustomSemesterEnd) {
                Text("Last day of term")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(ScheduleTheme.ink)
            }
            .tint(ScheduleTheme.teal)

            if useCustomSemesterEnd {
                DatePicker("", selection: $semesterEnd, displayedComponents: .date)
                    .labelsHidden()
                    .colorMultiply(ScheduleTheme.teal)
            }
        }
        .padding(.vertical, 4)
    }

    private var actionsRow: some View {
        HStack(spacing: 10) {
            Text("MEETINGS")
                .font(ScheduleTheme.sectionFont)
                .foregroundStyle(ScheduleTheme.inkMuted)
                .tracking(1.2)

            Spacer()

            Button("All") {
                for i in events.indices where events[i].isTBA == false {
                    events[i].isSelected = true
                }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(ScheduleTheme.teal)

            Button("None") {
                for i in events.indices { events[i].isSelected = false }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(ScheduleTheme.inkMuted)
        }
    }

    private var eventCards: some View {
        VStack(spacing: 12) {
            ForEach($events) { $ev in
                EventEditorRow(event: $ev, weekdaySymbols: weekdaySymbols)
            }
        }
    }

    private var destinationBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ADD TO")
                .font(ScheduleTheme.sectionFont)
                .foregroundStyle(ScheduleTheme.inkMuted)
                .tracking(1.2)

            HStack(spacing: 0) {
                ForEach(CalendarDestination.allCases) { dest in
                    let on = destination == dest
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            destination = dest
                        }
                    } label: {
                        Text(dest.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .foregroundStyle(on ? Color.white : ScheduleTheme.ink)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(on ? ScheduleTheme.teal : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ScheduleTheme.mistDeep.opacity(0.55))
            )

            Text(destination.detail)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(ScheduleTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            if destination.usesEventKit {
                if calendars.isEmpty {
                    Text("Calendar access is requested when you add events.")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(ScheduleTheme.inkMuted)
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
                    .tint(ScheduleTheme.teal)
                }
            }
        }
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
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isImporting || selectedImportable.isEmpty || selectedNeedingDays > 0)
            .opacity(isImporting || selectedImportable.isEmpty || selectedNeedingDays > 0 ? 0.45 : 1)

            if let importNote {
                Text(importNote)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(ScheduleTheme.inkMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }
        }
        .padding(.top, 4)
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

    private enum StatusTone { case warn, ok }

    private func statusChip(text: String, tone: StatusTone) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(tone == .warn ? ScheduleTheme.amber : ScheduleTheme.teal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill((tone == .warn ? ScheduleTheme.amber : ScheduleTheme.teal).opacity(0.12))
            )
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
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            events = parsed
        }

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
            parsePulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { parsePulse = false }
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
                    withAnimation { events = []; parseOutcome = .none }
                } else if destination == .apple {
                    importNote = "Select rows with days picked"
                }
            } else {
                importNote = "Open the .ics in Google Calendar (or any calendar app)."
                withAnimation { events = []; parseOutcome = .none }
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
    case found(meetings: Int, courses: Int?, needs: Int, tba: Int)
}

// MARK: - Atmosphere

private struct AtmosphereBackground: View {
    var body: some View {
        ZStack {
            ScheduleTheme.mist

            // Soft teal wash top-trailing
            RadialGradient(
                colors: [ScheduleTheme.tealBright.opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 340
            )

            // Cool depth bottom-leading
            RadialGradient(
                colors: [ScheduleTheme.mistDeep.opacity(0.9), .clear],
                center: .bottomLeading,
                startRadius: 40,
                endRadius: 380
            )

            // Subtle vertical drift
            LinearGradient(
                colors: [
                    Color.white.opacity(0.35),
                    Color.clear,
                    ScheduleTheme.teal.opacity(0.05),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Buttons

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ScheduleTheme.teal)
                    .opacity(configuration.isPressed ? 0.88 : 1)
                    .scaleEffect(configuration.isPressed ? 0.985 : 1)
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(ScheduleTheme.ink)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ScheduleTheme.surfaceSolid)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(ScheduleTheme.hairline, lineWidth: 1)
                    )
                    .opacity(configuration.isPressed ? 0.85 : 1)
                    .scaleEffect(configuration.isPressed ? 0.985 : 1)
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Event row

private struct EventEditorRow: View {
    @Binding var event: EditableScheduleEvent
    let weekdaySymbols: [String]

    private let weekdayOrder = [1, 2, 3, 4, 5, 6, 7]
    @State private var showDetailFields = false

    private var needsDays: Bool { event.needsWeekdayPick }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $event.isSelected) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(ScheduleTheme.ink)
            }
            .tint(ScheduleTheme.teal)
            .disabled(event.isTBA)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.displayTimeRange())
                    .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(ScheduleTheme.ink)
                Text(event.displaySemesterRange())
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(ScheduleTheme.inkMuted)
                if event.location.isEmpty == false {
                    Text(event.location)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(ScheduleTheme.teal)
                }
            }

            if let kind = event.sessionKind {
                Text(kind.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(ScheduleTheme.inkMuted)
            }

            if event.isTBA {
                Text("No timed meetings — skipped for calendar import.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(ScheduleTheme.amber)
            } else {
                HStack(spacing: 6) {
                    ForEach(weekdayOrder, id: \.self) { wd in
                        let on = event.weekdays.contains(wd)
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                if on { event.weekdays.remove(wd) }
                                else { event.weekdays.insert(wd) }
                            }
                        } label: {
                            Text(shortSymbol(for: wd))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .frame(width: 36, height: 36)
                                .foregroundStyle(on ? Color.white : ScheduleTheme.ink)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(on ? ScheduleTheme.teal : ScheduleTheme.mistDeep.opacity(0.65))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(
                                            needsDays && !on ? ScheduleTheme.amber.opacity(0.7) : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            DisclosureGroup(isExpanded: $showDetailFields) {
                VStack(spacing: 8) {
                    TextField("Title", text: $event.title)
                    TextField("Location", text: $event.location)
                }
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .padding(.top, 6)
            } label: {
                Text("Edit details")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(ScheduleTheme.inkMuted)
            }
            .tint(ScheduleTheme.teal)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ScheduleTheme.surfaceSolid)
                .shadow(color: ScheduleTheme.ink.opacity(0.04), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    needsDays || event.isTBA ? ScheduleTheme.amber.opacity(0.45) : ScheduleTheme.hairline,
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
