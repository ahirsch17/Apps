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
    @State private var isReadingInput = false
    @State private var importNote: String?
    @State private var inputNote: String?
    @State private var inputSource: InputSource = .none
    @State private var showTextEditor = false
    @State private var destination: CalendarDestination = .apple
    @State private var calendars: [EKCalendar] = []
    @State private var selectedCalendarID: String?
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var showFileImporter = false
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

    private var hasText: Bool {
        pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)

                        inputBlock
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)

                        if let inputNote {
                            Text(inputNote)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(ScheduleTheme.amber)
                                .transition(.opacity)
                        }

                        if let importNote {
                            Text(importNote)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(ScheduleTheme.teal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(ScheduleTheme.teal.opacity(0.10))
                                )
                                .transition(.opacity)
                        }

                        parseBanner
                            .scaleEffect(parsePulse ? 1.02 : 1)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: parsePulse)

                        if events.isEmpty == false {
                            WeekScheduleView(events: events) { id in
                                if let i = events.firstIndex(where: { $0.id == id }) {
                                    events[i].isSelected.toggle()
                                }
                            }
                            semesterRow
                            actionsRow
                            eventCards
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)).combined(with: .offset(y: 12)),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .animation(.spring(response: 0.45, dampingFraction: 0.86), value: events.count)
                    .animation(.easeOut(duration: 0.2), value: inputNote)
                    .animation(.easeOut(duration: 0.2), value: importNote)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if events.isEmpty == false {
                        stickyImportBar
                    }
                }

                if isReadingInput {
                    readingOverlay
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
                inputSource = .none
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ActivityView(activityItems: [shareURL])
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: ScheduleFileReader.supportedTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else { return }
                Task { await loadFile(url) }
            case let .failure(error):
                inputNote = error.localizedDescription
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            WeekStripMark()
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                Text("Schedule")
                    .font(ScheduleTheme.brandFont)
                    .foregroundStyle(ScheduleTheme.ink)
                    .tracking(-0.8)

                Text("Paste your classes. Check them. Drop them on your calendar.")
                    .font(ScheduleTheme.bodyFont)
                    .foregroundStyle(ScheduleTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 12)
    }

    private var inputBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YOUR SCHEDULE")
                    .font(ScheduleTheme.sectionFont)
                    .foregroundStyle(ScheduleTheme.inkMuted)
                    .tracking(1.2)

                Spacer()

                if inputSource != .none {
                    Text(inputSource.label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(ScheduleTheme.teal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(ScheduleTheme.teal.opacity(0.12))
                        )
                }
            }

            Button(action: pasteAndScan) {
                HStack(spacing: 14) {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 22, weight: .semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Paste schedule")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Text("Copy Student Schedule, then tap")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .opacity(0.88)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .opacity(0.7)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isReadingInput)

            Text("Works with the Student Schedule page a lot of US schools share (title, days, times, CRN). A syllabus line is fine too. Paste text — not a screenshot.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(ScheduleTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            DisclosureGroup(isExpanded: $showTextEditor) {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack(alignment: .topLeading) {
                        if hasText == false {
                            Text("Paste the schedule text here if you want to edit it first.")
                                .font(ScheduleTheme.monoFont)
                                .foregroundStyle(ScheduleTheme.inkMuted.opacity(0.55))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $pastedText)
                            .frame(minHeight: 140)
                            .font(ScheduleTheme.monoFont)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .foregroundStyle(ScheduleTheme.ink)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(ScheduleTheme.surfaceSolid)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(ScheduleTheme.hairline, lineWidth: 1)
                    )

                    HStack(spacing: 10) {
                        if hasText {
                            Button("Clear") {
                                withAnimation {
                                    pastedText = ""
                                    events = []
                                    parseOutcome = .none
                                    importNote = nil
                                    inputNote = nil
                                    inputSource = .none
                                }
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(ScheduleTheme.inkMuted)
                        }

                        Button {
                            showFileImporter = true
                        } label: {
                            Text("From file")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(ScheduleTheme.inkMuted)
                        }

                        Spacer()

                        Button(action: parse) {
                            Text(events.isEmpty ? "Find classes" : "Find again")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(hasText == false || isReadingInput)
                    }
                }
                .padding(.top, 8)
            } label: {
                Text(showTextEditor ? "Hide text" : (hasText ? "Edit the pasted text" : "Or type it in"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(ScheduleTheme.inkMuted)
            }
            .tint(ScheduleTheme.teal)
        }
    }

    private var readingOverlay: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(ScheduleTheme.teal)
                Text(inputSource == .file ? "Reading file…" : "Working…")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(ScheduleTheme.ink)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(ScheduleTheme.surfaceSolid)
                    .shadow(color: ScheduleTheme.ink.opacity(0.12), radius: 20, y: 8)
            )
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private var parseBanner: some View {
        switch parseOutcome {
        case .none:
            EmptyView()
        case .empty:
            VStack(alignment: .leading, spacing: 10) {
                statusChip(
                    text: "Couldn’t find any meetings in that paste. Check the text, or add a class yourself.",
                    tone: .warn
                )
                Button(action: addBlankClass) {
                    Label("Add a class by hand", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(SoftButtonStyle())
            }
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
            .onChange(of: useCustomSemesterEnd) { _, on in
                if on, hasText { parse() }
            }
            .onChange(of: semesterEnd) { _, _ in
                if useCustomSemesterEnd, hasText { parse() }
            }

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
            Text("CLASSES")
                .font(ScheduleTheme.sectionFont)
                .foregroundStyle(ScheduleTheme.inkMuted)
                .tracking(1.2)

            Spacer()

            Button("Add") {
                addBlankClass()
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(ScheduleTheme.teal)

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
                EventEditorRow(
                    event: $ev,
                    weekdaySymbols: weekdaySymbols,
                    onDelete: {
                        withAnimation {
                            events.removeAll { $0.id == ev.id }
                            if events.isEmpty { parseOutcome = .none }
                        }
                    }
                )
            }
        }
    }

    private var stickyImportBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(CalendarDestination.allCases) { dest in
                    let on = destination == dest
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            destination = dest
                        }
                    } label: {
                        Text(dest.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .foregroundStyle(on ? Color.white : ScheduleTheme.ink)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(on ? ScheduleTheme.teal : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ScheduleTheme.mistDeep.opacity(0.55))
            )

            if destination.usesEventKit, calendars.isEmpty == false {
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
                .padding(.vertical, 15)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isImporting || selectedImportable.isEmpty || selectedNeedingDays > 0)
            .opacity(isImporting || selectedImportable.isEmpty || selectedNeedingDays > 0 ? 0.45 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            ScheduleTheme.cream
                .shadow(color: ScheduleTheme.ink.opacity(0.12), radius: 16, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var importTitle: String {
        if selectedNeedingDays > 0 { return "Pick days first" }
        if selectedImportable.isEmpty { return "Select meetings" }
        switch destination {
        case .apple: return "Add to iPhone Calendar"
        case .google: return "Share .ics file"
        case .both: return "Add + Share .ics"
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

    private func addBlankClass() {
        let end = useCustomSemesterEnd
            ? semesterEnd
            : (Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date())
        let start = Calendar.current.date(byAdding: .month, value: -4, to: end) ?? Date()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            events.append(EditableScheduleEvent.blank(semesterStart: start, semesterEnd: end))
            parseOutcome = .found(
                meetings: events.count,
                courses: ScheduleTextParser.distinctRegisteredCourseCount(in: events),
                needs: events.filter(\.needsWeekdayPick).count,
                tba: events.filter(\.isTBA).count
            )
        }
    }

    private func pasteAndScan() {
        inputNote = nil
        guard let s = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            s.isEmpty == false
        else {
            inputNote = "Clipboard is empty — copy your schedule first."
            return
        }
        inputSource = .paste
        pastedText = s
        showTextEditor = false
        parse()
    }

    @MainActor
    private func loadFile(_ url: URL) async {
        inputNote = nil
        importNote = nil
        inputSource = .file
        isReadingInput = true
        defer { isReadingInput = false }

        do {
            let text = try await ScheduleFileReader.readText(from: url)
            pastedText = text
            parse()
            if events.isEmpty == false {
                showTextEditor = false
            } else {
                showTextEditor = true
                inputNote = "File was read, but no meetings matched. Edit the text and re-parse."
            }
        } catch {
            inputNote = error.localizedDescription
            showTextEditor = true
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
                    withAnimation {
                        events = []
                        parseOutcome = .none
                        pastedText = ""
                        inputSource = .none
                    }
                } else if destination == .apple {
                    importNote = "Select rows with days picked"
                }
            } else {
                importNote = "Open the .ics in Google Calendar, Outlook, or any calendar app."
                withAnimation {
                    events = []
                    parseOutcome = .none
                    pastedText = ""
                    inputSource = .none
                }
            }
        } catch {
            importFeedback.notificationOccurred(.error)
            importNote = error.localizedDescription
        }
    }
}

private enum InputSource: Equatable {
    case none
    case paste
    case file

    var label: String {
        switch self {
        case .none: return ""
        case .paste: return "From paste"
        case .file: return "From file"
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

            RadialGradient(
                colors: [ScheduleTheme.amber.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 320
            )

            RadialGradient(
                colors: [ScheduleTheme.teal.opacity(0.10), .clear],
                center: .bottomLeading,
                startRadius: 40,
                endRadius: 380
            )

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
    var onDelete: () -> Void

    private let weekdayOrder = [1, 2, 3, 4, 5, 6, 7]
    @State private var showDetailFields = false

    private var needsDays: Bool { event.needsWeekdayPick }
    private var accent: Color { ScheduleTheme.accent(for: event.title) }
    private var parseHint: String? {
        let lines = event.notes
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        return lines.first { $0.hasPrefix("Graph:") }
    }

    private var crnLabel: String? {
        guard let range = event.notes.range(of: #"CRN\s*:?\s*(\d+)"#, options: .regularExpression) else { return nil }
        return String(event.notes[range]).replacingOccurrences(of: "CRN:", with: "CRN", options: .caseInsensitive)
    }

    private var instructorLines: [String] {
        event.notes
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                guard line.isEmpty == false else { return false }
                if line.uppercased().hasPrefix("CRN") { return false }
                if line.hasPrefix("Graph:") { return false }
                if let kind = event.sessionKind, line.caseInsensitiveCompare(kind) == .orderedSame { return false }
                return true
            }
    }

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: event.startHour,
                    minute: event.startMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { newDate in
                let cal = Calendar.current
                event.startHour = cal.component(.hour, from: newDate)
                event.startMinute = cal.component(.minute, from: newDate)
            }
        )
    }

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: event.endHour,
                    minute: event.endMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { newDate in
                let cal = Calendar.current
                event.endHour = cal.component(.hour, from: newDate)
                event.endMinute = cal.component(.minute, from: newDate)
            }
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent)
                .frame(width: 5)
                .padding(.vertical, 16)
                .padding(.leading, 10)

            VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
            Toggle(isOn: $event.isSelected) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(ScheduleTheme.ink)
                    if let crnLabel {
                        Text(crnLabel)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(ScheduleTheme.inkMuted)
                    }
                }
            }
            .tint(ScheduleTheme.teal)
            .disabled(event.isTBA)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ScheduleTheme.inkMuted)
                    .padding(8)
                    .background(Circle().fill(ScheduleTheme.mistDeep.opacity(0.55)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove class")
            }

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
                ForEach(instructorLines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(ScheduleTheme.inkMuted)
                }
            }

            if let kind = event.sessionKind {
                Text(kind.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(ScheduleTheme.inkMuted)
            }

            if let parseHint {
                Text(parseHint.replacingOccurrences(of: "Graph: ", with: ""))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(ScheduleTheme.amber)
            }

            if event.isTBA {
                Text("No timed meetings — skipped for calendar import.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(ScheduleTheme.amber)
            } else {
                if needsDays {
                    Text("Tap the days this class meets")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(ScheduleTheme.amber)
                }

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
                VStack(spacing: 10) {
                    TextField("Title", text: $event.title)
                    TextField("Location", text: $event.location)

                    if event.isTBA == false {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Starts")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(ScheduleTheme.inkMuted)
                                DatePicker("", selection: startTimeBinding, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ends")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(ScheduleTheme.inkMuted)
                                DatePicker("", selection: endTimeBinding, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                    }
                }
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .padding(.top, 6)
            } label: {
                Text("Edit title, time, location")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(ScheduleTheme.inkMuted)
            }
            .tint(ScheduleTheme.teal)
            }
            .padding(.vertical, 16)
            .padding(.trailing, 16)
            .padding(.leading, 8)
        }
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
        .onAppear {
            if needsDays || parseHint != nil {
                showDetailFields = true
            }
        }
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
