import Foundation

enum ScheduleTextParser {
    private static let dateRangePattern = try! NSRegularExpression(
        pattern: #"(\d{1,2}/\d{1,2}/\d{4})\s*(?:--|–|-|—|to|through)\s*(\d{1,2}/\d{1,2}/\d{4})"#
    )
    private static let isoDateRangePattern = try! NSRegularExpression(
        pattern: #"(\d{4}-\d{2}-\d{2})\s*(?:--|–|-|—|to|through|until)\s*(\d{4}-\d{2}-\d{2})"#,
        options: [.caseInsensitive]
    )
    private static let timeRangePattern = try! NSRegularExpression(
        pattern: #"(\d{1,2}:\d{2}\s*[AP]M)\s*-\s*(\d{1,2}:\d{2}\s*[AP]M)"#,
        options: .caseInsensitive
    )
    /// Inserts a space when minutes run straight into AM/PM (`10:45AM` → `10:45 AM`). Uses full `h:mm` so `10:50AM` does not become `10:5 0 AM`.
    private static let amPmGluePattern = try! NSRegularExpression(
        pattern: #"(\d{1,2}:\d{2})([AP]M)\b"#,
        options: .caseInsensitive
    )
    private static let crnPattern = try! NSRegularExpression(pattern: #"CRN:\s*(\d+)"#, options: .caseInsensitive)
    /// Matches `CRN 11886` (notes) or `CRN: 11966` (paste line).
    private static let notesCrnPattern = try! NSRegularExpression(pattern: #"CRN\s*:?\s*(\d+)"#, options: .caseInsensitive)
    private static let courseTitlePattern = try! NSRegularExpression(
        pattern: #"^(.+\|\s*.+?\s+Section\s+[^|]+?)(?:\s*\|\s*Class Begin:.*)?$"#
    )

    /// Parses pasted registrar text: **Banner / Format A** (Registered, date ranges, weekday-as-row
    /// context, time blocks, CRN, title), **table** rows, or **Mon–Sun grid**. Banner output is one
    /// `EditableScheduleEvent` per meeting (multiple rows per CRN when the schedule has multiple
    /// days/times for that class).
    static func parse(_ raw: String, defaultSemesterEnd: Date?) -> [EditableScheduleEvent] {
        let newlinesOnly = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let normalized = newlinesOnly.replacingOccurrences(of: "\t", with: " ")

        let fromBanner = parseBanner(normalized, defaultSemesterEnd: defaultSemesterEnd)
        if fromBanner.isEmpty == false {
            return dedupeBannerSameSlot(mergeDuplicates(fromBanner))
        }

        if VTTabularScheduleParser.looksLikeVtTabularPaste(newlinesOnly),
           let vtRows = VTTabularScheduleParser.parse(newlinesOnly), vtRows.isEmpty == false
        {
            let end = defaultSemesterEnd ?? Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
            let start = Calendar.current.date(byAdding: .month, value: -4, to: end) ?? end
            return mergeDuplicates(VTTabularScheduleParser.toEditableScheduleEvents(vtRows, semesterStart: start, semesterEnd: end))
        }

        let gridExpanded = expandTabsForGrid(newlinesOnly)
        let fromGrid = parseTimeGridSchedule(gridExpanded, defaultSemesterEnd: defaultSemesterEnd)
        if fromGrid.isEmpty == false {
            return mergeDuplicates(fromGrid)
        }

        let fromTable = parseTableLike(normalized, defaultSemesterEnd: defaultSemesterEnd)
        return mergeDuplicates(fromTable)
    }

    /// Unique CRNs across parsed events (from each row’s notes). When every row has a CRN, this is the registrar “class” count even if one course produced several meeting rows. Returns `nil` if no notes contained a CRN (common for some grid-only pastes).
    static func distinctRegisteredCourseCount(in events: [EditableScheduleEvent]) -> Int? {
        let crns = Set(events.compactMap { crnFromEventNotes($0.notes) })
        if crns.isEmpty { return nil }
        return crns.count
    }

    // MARK: - Banner (Format A: Registered, dates, weekday rows, times, CRN, title)

    private struct PartialMeeting {
        var semesterStart: Date
        var semesterEnd: Date
        /// Catalog line from the course header immediately above this block’s `Registered` (same for every row in the enrollment).
        var registrationCatalogLine: String?
        var weekday: Int?
        var startHour: Int?
        var startMinute: Int?
        var endHour: Int?
        var endMinute: Int?
        var sessionKind: String?
        var locationLines: [String] = []
        var instructorLines: [String] = []
        var crn: String?
        var title: String?
    }

    private static func nextNonEmptyLineIndex(after index: Int, in lines: [String]) -> Int? {
        var j = index + 1
        while j < lines.count {
            if lines[j].isEmpty == false { return j }
            j += 1
        }
        return nil
    }

    private static func findBannerCrnLineIndex(_ lines: [String], crn: String, startingAt: Int) -> Int? {
        for idx in startingAt ..< lines.count {
            guard let m = firstMatch(crnPattern, lines[idx]),
                  m.numberOfRanges >= 2,
                  let r = Range(m.range(at: 1), in: lines[idx])
            else { continue }
            if String(lines[idx][r]) == crn { return idx }
        }
        return nil
    }

    /// Lines strictly after `CRN:` and before the next `Registered` (Banner’s usual place for the closing course line).
    private static func scanBannerTitleAfterCrnUntilRegistered(_ lines: [String], crnLineIndex: Int) -> String? {
        var j = crnLineIndex + 1
        while j < lines.count {
            let line = lines[j]
            if line.caseInsensitiveCompare("Registered") == .orderedSame { return nil }
            if let t = matchCourseTitle(line) { return t }
            if line.contains("|"), line.contains("Section") { return line }
            j += 1
        }
        return nil
    }

    /// Forward-only: never scan above the CRN line (that pulled in the wrong course for the next CRN).
    private static func recoverUntitledBannerRows(_ events: [EditableScheduleEvent], lines: [String]) -> [EditableScheduleEvent] {
        var out = events
        var slots: [(Int, String)] = []
        for (i, e) in out.enumerated() where e.title == "Untitled" || e.title.hasPrefix("Class (CRN ") {
            if let c = crnFromEventNotes(e.notes) { slots.append((i, c)) }
        }
        var searchFrom = 0
        for (evIdx, crn) in slots {
            guard let crnLine = findBannerCrnLineIndex(lines, crn: crn, startingAt: searchFrom) else { continue }
            if let t = scanBannerTitleAfterCrnUntilRegistered(lines, crnLineIndex: crnLine) {
                out[evIdx].title = t
            }
            searchFrom = crnLine + 1
        }
        return out
    }

    //
    // MARK: — Cross-format enrollment model (conceptual state machine) —
    //
    // **Core idea:** one *enrollment* (one CRN + catalog identity) can have several *meeting patterns*
    // (different day sets + times + type + location). The parser must emit **one calendar row per
    // distinct pattern**, no matter which school’s surface syntax produced the paste.
    //
    // **Abstract states** (Banner / table / grid are adapters that emit the same transitions):
    //
    // - **S0 — OutsideRegistration** — not inside a school block; skip noise until a block starts.
    // - **S1 — InRegistration** — accumulating `pending` partial rows for the current enrollment
    //   until CRN/title flush.
    // - **S2 — RowNeedsDayOrTime** — the current open `PartialMeeting` still needs weekday and/or
    //   clock times. A **standalone day line is a reset for the open row**, not a tweak to the prior
    //   row’s semantics.
    // - **S3 — RowHasTime** — times set; type/location/instructor (and similar) refine this row.
    // - **S4 — AwaitingIdentity** — CRN (and optional lead title) known; closing title or fallback
    //   triggers **flush** → N `EditableScheduleEvent`s, then back toward S0/S1.
    //
    // **Transitions (simplified):**
    //
    // - S0→S1: block header (e.g. Banner `Registered`).
    // - S1→S2: “new meeting row” token (Banner: date line appends `PartialMeeting`; grid: CRN + block).
    // - S2→S2: more **day** tokens for the **same** slot before a time line (e.g. M/W/F accumulate
    //   into one row in grid/table); **or** Banner weekday then time on that row.
    // - S2→S3: time range parsed for the open row.
    // - S3→S2: another **day+time** pair begins (new partial in the same CRN group) — *different times
    //   on different days each close their own pattern*.
    // - S3→S4: `CRN:` applies to every row still pending in this Banner group.
    // - S4→S0: `CRN:` on a complete row group flushes with the block’s `registrationCatalogLine` (or
    //   closing title / `Untitled` + forward-only `recoverUntitledBannerRows`); legacy closes on a
    //   catalog pipe line after CRN still flush if anything remains pending.
    // - S1→S0: next `Registered` with complete untitled pending flushed first (no merge across blocks).
    //
    // Format-specific lexing (how to spot a day vs a time vs CRN) is **secondary**; it should only
    // feed these states. Implementations live in `parseBanner`, `parseTableLike`, `parseTimeGridSchedule`.
    //
    // **Banner mapping (S2/S3):** a standalone weekday (`Monday`, `Thursday`, …) applies to the
    // *current* open meeting row:
    // typically the `PartialMeeting` created by the most recent date-range line that does not yet
    // have a weekday. The next time line + detail lines attach to that row until the next weekday,
    // another date-range line (new row), or the block ends at CRN/title flush.
    //
    // **One calendar event per distinct meeting.**
    // The same registrar class (one CRN) can yield multiple rows (e.g. Thursday lab + Monday lecture).
    // Do not collapse those into one event unless they are true duplicates (same CRN + same slot).
    //
    // **Events vs classes (product copy / summaries).**
    // “Meetings” / parsed row count = calendar events. “Classes” (when shown) = distinct CRNs in
    // notes — e.g. five CRNs can still produce seven events. Never equate the two in UI labels.
    //
    // **Title lines:** the catalog line immediately above `Registered` is copied onto each `PartialMeeting`
    // as `registrationCatalogLine`. When `CRN:` arrives on a complete row group, we flush using that line
    // (so the next block’s header is never mistaken for this block’s title). `leadCourseTitle` still
    // refines rare closes. If still missing, emit `Untitled` (CRN stays in notes) and `recoverUntitledBannerRows`
    // scans **forward-only** after `CRN:` until the next `Registered`.

    private static func parseBanner(_ text: String, defaultSemesterEnd: Date?) -> [EditableScheduleEvent] {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        var i = 0
        var pending: [PartialMeeting] = []
        var result: [EditableScheduleEvent] = []
        /// Banner sometimes prints the course line *above* `Registered` for the next block; use it once when the closing title line is processed.
        var leadCourseTitle: String?
        /// Same catalog string as `leadCourseTitle` when we accept a header+`Registered` pair — copied onto new date-range rows until flush.
        var activeRegistrationCatalogLine: String?
        /// Prevents a **duplicate** closing course line (same text as the block we just flushed) from becoming `leadCourseTitle` and poisoning the next registration’s title.
        var lastClosedBannerTitle: String?

        func applyBannerCatalogTitleBeforeFlush(closingMatchTitle: String? = nil, closingRawPipeLine: String? = nil) {
            let fromRows = pending.compactMap(\.registrationCatalogLine).first?.trimmingCharacters(in: .whitespacesAndNewlines)
            let leadTrim = leadCourseTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
            let mTrim = closingMatchTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
            let rTrim = closingRawPipeLine?.trimmingCharacters(in: .whitespacesAndNewlines)
            let effective = [fromRows, leadTrim, mTrim, rTrim].compactMap { $0 }.first { $0.isEmpty == false }
            if let t = effective {
                for idx in pending.indices { pending[idx].title = t }
            }
            leadCourseTitle = nil
        }

        func flushGroup() {
            var lastEmittedInThisFlush: String?
            for p in pending {
                guard let sh = p.startHour, let sm = p.startMinute,
                      let eh = p.endHour, let em = p.endMinute
                else { continue }
                let trimmed = p.title?.trimmingCharacters(in: .whitespacesAndNewlines)
                let title: String = {
                    if let t = trimmed, t.isEmpty == false { return t }
                    return "Untitled"
                }()
                let loc = formatLocation(p)
                let notes = notesForPartial(p)
                let days: Set<Int> = p.weekday.map { [$0] } ?? []
                result.append(
                    EditableScheduleEvent(
                        title: title,
                        location: loc,
                        notes: notes,
                        semesterStart: p.semesterStart,
                        semesterEnd: p.semesterEnd,
                        weekdays: days,
                        startHour: sh,
                        startMinute: sm,
                        endHour: eh,
                        endMinute: em,
                        sessionKind: p.sessionKind
                    )
                )
                lastEmittedInThisFlush = title
            }
            if let t = lastEmittedInThisFlush { lastClosedBannerTitle = t }
            pending.removeAll(keepingCapacity: true)
            activeRegistrationCatalogLine = nil
        }

        while i < lines.count {
            let line = lines[i]

            if line.caseInsensitiveCompare("Registered") == .orderedSame {
                if pending.isEmpty == false,
                   pending.allSatisfy({
                       $0.weekday != nil && $0.startHour != nil && $0.endHour != nil && $0.endMinute != nil
                   })
                {
                    applyBannerCatalogTitleBeforeFlush()
                    flushGroup()
                }
                i += 1
                continue
            }

            if pending.isEmpty {
                let headerTitle: String? = {
                    if let t = matchCourseTitle(line) { return t }
                    if line.contains("|"), line.contains("Section") { return line }
                    return nil
                }()
                if let t = headerTitle,
                   let nextIdx = nextNonEmptyLineIndex(after: i, in: lines),
                   lines[nextIdx].caseInsensitiveCompare("Registered") == .orderedSame
                {
                    let norm = t.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let prev = lastClosedBannerTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
                       prev.isEmpty == false,
                       norm.caseInsensitiveCompare(prev) == .orderedSame
                    {
                        i += 1
                        continue
                    }
                    leadCourseTitle = t
                    activeRegistrationCatalogLine = t
                    i += 1
                    continue
                }
            }

            if let range = matchDateRange(in: line) {
                let end = defaultSemesterEnd ?? range.end
                pending.append(
                    PartialMeeting(
                        semesterStart: range.start,
                        semesterEnd: end,
                        registrationCatalogLine: activeRegistrationCatalogLine
                    )
                )
                i += 1
                continue
            }

            if var last = pending.last, last.weekday == nil, let wd = parseFullWeekday(line) {
                last.weekday = wd
                pending[pending.count - 1] = last
                i += 1
                if i < lines.count, isCalendarGridStart(lines, i) {
                    i += 7
                }
                continue
            }

            if var last = pending.last, last.startHour == nil, let times = matchTimeRange(in: line) {
                last.startHour = times.startHour
                last.startMinute = times.startMinute
                last.endHour = times.endHour
                last.endMinute = times.endMinute
                let normLine = normalizeTimeLine(line)
                if let m = firstMatch(timeRangePattern, normLine), let tr = Range(m.range(at: 0), in: normLine) {
                    let tail = String(normLine[tr.upperBound...]).trimmingCharacters(in: .whitespaces)
                    applyTailFragments(tail, into: &last)
                }
                pending[pending.count - 1] = last
                i += 1
                continue
            }

            if line.lowercased().hasPrefix("type:"), var last = pending.last {
                applyDetailLine(&last, line)
                pending[pending.count - 1] = last
                i += 1
                continue
            }

            if line.lowercased().hasPrefix("location:") || line.lowercased().hasPrefix("building:") || line.lowercased().hasPrefix("room:"),
               var last = pending.last
            {
                applyDetailLine(&last, line)
                pending[pending.count - 1] = last
                i += 1
                continue
            }

            if line.lowercased().hasPrefix("instructor:"), pending.isEmpty == false {
                for idx in pending.indices {
                    var p = pending[idx]
                    p.instructorLines.append(line)
                    pending[idx] = p
                }
                i += 1
                continue
            }

            if let m = firstMatch(crnPattern, line), m.numberOfRanges >= 2,
               let r = Range(m.range(at: 1), in: line)
            {
                let crn = String(line[r])
                for idx in pending.indices { pending[idx].crn = crn }
                i += 1
                if pending.isEmpty == false,
                   pending.allSatisfy({
                       $0.weekday != nil && $0.startHour != nil && $0.endHour != nil && $0.endMinute != nil
                   })
                {
                    applyBannerCatalogTitleBeforeFlush()
                    flushGroup()
                }
                continue
            }

            if pending.isEmpty == false, let title = matchCourseTitle(line) {
                applyBannerCatalogTitleBeforeFlush(closingMatchTitle: title)
                flushGroup()
                i += 1
                continue
            }

            if line.contains("|"), line.contains("Section"), pending.isEmpty == false {
                applyBannerCatalogTitleBeforeFlush(closingRawPipeLine: line)
                flushGroup()
                i += 1
                continue
            }

            if line.allSatisfy({ $0.isNumber }), pending.isEmpty == false {
                i += 1
                continue
            }

            if pending.isEmpty == false,
               pending.contains(where: { $0.instructorLines.isEmpty == false }),
               looksLikeInstructorNameContinuation(line)
            {
                for idx in pending.indices {
                    var p = pending[idx]
                    p.instructorLines.append(line)
                    pending[idx] = p
                }
                i += 1
                continue
            }

            i += 1
        }

        flushGroup()
        return recoverUntitledBannerRows(result, lines: lines)
    }

    /// Co-instructor or continuation lines (`Last, First`) after the primary `Instructor:` line; excludes CRN, dates, times, and detail prefixes.
    private static func looksLikeInstructorNameContinuation(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.isEmpty == false, t.contains(",") else { return false }
        if t.contains("|") { return false }
        if t.contains("(") { return false }
        let lower = t.lowercased()
        if lower.hasPrefix("crn:") { return false }
        if lower.hasPrefix("type:") || lower.hasPrefix("location:") || lower.hasPrefix("building:") || lower.hasPrefix("room:")
        {
            return false
        }
        if matchDateRange(in: t) != nil { return false }
        if matchTimeRange(in: t) != nil { return false }
        return true
    }

    private static func applyTailFragments(_ tail: String, into p: inout PartialMeeting) {
        guard tail.isEmpty == false else { return }
        if let kind = firstCapture(#"Type:\s*(.+?)\s+Location:"#, tail, options: .caseInsensitive) {
            p.sessionKind = kind.trimmingCharacters(in: .whitespaces)
        } else if let kind = firstCapture(#"Type:\s*(.+)$"#, tail, options: .caseInsensitive) {
            p.sessionKind = kind.trimmingCharacters(in: .whitespaces)
        }
        p.locationLines.append(tail)
    }

    private static func applyDetailLine(_ p: inout PartialMeeting, _ line: String) {
        if line.lowercased().hasPrefix("type:") {
            let rest = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            p.sessionKind = rest.split(separator: " ").first.map(String.init)
        }
        p.locationLines.append(line)
    }

    private static func formatLocation(_ p: PartialMeeting) -> String {
        let joined = p.locationLines.joined(separator: " ")
        func clean(_ s: String) -> String {
            s.replacingOccurrences(of: "None", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        var parts: [String] = []
        if let loc = firstCapture(#"Location:\s*([^|]+?)(?:\s+Building:|$)"#, joined, options: .caseInsensitive) {
            let c = clean(loc)
            if c.isEmpty == false { parts.append(c) }
        }
        if let b = firstCapture(#"Building:\s*([^|]+?)(?:\s+Room:|$)"#, joined, options: .caseInsensitive) {
            let c = clean(b)
            if c.isEmpty == false { parts.append(c) }
        }
        if let r = firstCapture(#"Room:\s*([^|]+?)(?:\s+Instructor:|$)"#, joined, options: .caseInsensitive)
            ?? firstCapture(#"Room:\s*(.+)$"#, joined, options: .caseInsensitive)
        {
            let c = clean(r)
            if c.isEmpty == false { parts.append(c) }
        }
        if parts.isEmpty {
            // Avoid returning a noisy concatenation when every structured field was None/blank.
            return ""
        }
        return parts.joined(separator: " · ")
    }

    private static func notesForPartial(_ p: PartialMeeting) -> String {
        var bits: [String] = []
        if let crn = p.crn { bits.append("CRN \(crn)") }
        for ins in p.instructorLines {
            let t = ins.replacingOccurrences(of: "Instructor:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            if t.isEmpty == false { bits.append(t) }
        }
        return bits.joined(separator: "\n")
    }

    private static func isCalendarGridStart(_ lines: [String], _ i: Int) -> Bool {
        guard i + 6 < lines.count else { return false }
        let letters = Set("SMTWF")
        for j in 0 ..< 7 {
            let s = lines[i + j]
            guard s.count == 1, let c = s.first, letters.contains(c) else { return false }
        }
        return true
    }

    private static func matchDateRange(in line: String) -> (start: Date, end: Date)? {
        if let m = firstMatch(isoDateRangePattern, line), m.numberOfRanges >= 3,
           let r0 = Range(m.range(at: 1), in: line),
           let r1 = Range(m.range(at: 2), in: line),
           let s = yMd.date(from: String(line[r0])),
           let e = yMd.date(from: String(line[r1]))
        {
            return (s, e)
        }
        guard let m = firstMatch(dateRangePattern, line), m.numberOfRanges >= 3,
              let r0 = Range(m.range(at: 1), in: line),
              let r1 = Range(m.range(at: 2), in: line),
              let s = parseDate(String(line[r0])),
              let e = parseDate(String(line[r1]))
        else { return nil }
        return (s, e)
    }

    private static func matchTimeRange(in line: String) -> (startHour: Int, startMinute: Int, endHour: Int, endMinute: Int)? {
        let norm = normalizeTimeLine(line)
        guard let m = firstMatch(timeRangePattern, norm), m.numberOfRanges >= 3,
              let r0 = Range(m.range(at: 1), in: norm),
              let r1 = Range(m.range(at: 2), in: norm),
              let t0 = parseTime(String(norm[r0])),
              let t1 = parseTime(String(norm[r1]))
        else { return nil }
        return (t0.hour, t0.minute, t1.hour, t1.minute)
    }

    private static func normalizeTimeLine(_ line: String) -> String {
        let m = NSMutableString(string: line)
        amPmGluePattern.replaceMatches(in: m, options: [], range: NSRange(location: 0, length: m.length), withTemplate: "$1 $2")
        return m as String
    }

    private static func matchCourseTitle(_ line: String) -> String? {
        guard let m = firstMatch(courseTitlePattern, line), m.numberOfRanges >= 2,
              let r = Range(m.range(at: 1), in: line)
        else { return nil }
        return String(line[r]).trimmingCharacters(in: .whitespaces)
    }

    private static func firstMatch(_ re: NSRegularExpression, _ s: String) -> NSTextCheckingResult? {
        let range = NSRange(s.startIndex ..< s.endIndex, in: s)
        return re.firstMatch(in: s, options: [], range: range)
    }

    private static func firstCapture(_ pattern: String, _ s: String, options: NSRegularExpression.Options = []) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        guard let m = firstMatch(re, s), m.numberOfRanges >= 2,
              let r = Range(m.range(at: 1), in: s) else { return nil }
        return String(s[r])
    }

    private static let mdY: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "MM/dd/yyyy"
        return f
    }()

    private static let yMd: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func parseDate(_ s: String) -> Date? {
        mdY.date(from: s.trimmingCharacters(in: .whitespaces))
    }

    private static func parseTime(_ s: String) -> (hour: Int, minute: Int)? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "h:mm a"
        let t = normalizeTimeLine(s.trimmingCharacters(in: .whitespaces)).replacingOccurrences(of: "  ", with: " ")
        guard let d = f.date(from: t) else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let h = cal.component(.hour, from: d)
        let m = cal.component(.minute, from: d)
        return (h, m)
    }

    private static func parseFullWeekday(_ line: String) -> Int? {
        let lower = line.lowercased()
        if lower.hasPrefix("sun") { return 1 }
        if lower.hasPrefix("mon") { return 2 }
        if lower.hasPrefix("tue") { return 3 }
        if lower.hasPrefix("wed") { return 4 }
        if lower.hasPrefix("thu") { return 5 }
        if lower.hasPrefix("fri") { return 6 }
        if lower.hasPrefix("sat") { return 7 }
        return nil
    }

    // MARK: - Table-like (CRN, course, days TR / MWF, time, location)

    private static let tableRowPattern = try! NSRegularExpression(
        pattern: #"^(\d{4,5})\b\s+[A-Z]{2,10}\s+\d{4}\s+(.+?)\s+(\d{1,2}:\d{2}\s*[AP]M)\s*-\s*(\d{1,2}:\d{2}\s*[AP]M)\s+([A-Z]{1,8})\s+(.+)$"#,
        options: [.caseInsensitive]
    )
    private static let crnLineStartPattern = try! NSRegularExpression(pattern: #"^\d{4,5}\b"#, options: [])
    private static let tableFooterLinePattern = try! NSRegularExpression(pattern: #"^(?i)total\b"#, options: [])

    private static func parseTableLike(_ text: String, defaultSemesterEnd: Date?) -> [EditableScheduleEvent] {
        let end = defaultSemesterEnd ?? Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
        let start = Calendar.current.date(byAdding: .month, value: -4, to: end) ?? end
        var out: [EditableScheduleEvent] = []

        let flattened = flattenedCourseTableRecords(text)
        for record in flattened {
            guard let ev = matchTableRow(record, semesterStart: start, semesterEnd: end) else { continue }
            out.append(ev)
        }

        if out.isEmpty {
            for line in text.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.isEmpty == false else { continue }
                if let ev = matchTableRow(trimmed, semesterStart: start, semesterEnd: end) {
                    out.append(ev)
                }
            }
        }

        return out
    }

    /// Joins wrapped HTML/table rows so one logical course = one string (CRN … TR … location).
    private static func flattenedCourseTableRecords(_ text: String) -> [String] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var records: [String] = []
        var buffer: [String] = []

        func flush() {
            guard buffer.isEmpty == false else { return }
            records.append(buffer.joined(separator: " "))
            buffer.removeAll(keepingCapacity: true)
        }

        for line in lines {
            if firstMatch(tableFooterLinePattern, line) != nil {
                flush()
                continue
            }
            if firstMatch(crnLineStartPattern, line) != nil {
                flush()
                buffer.append(line)
            } else if buffer.isEmpty == false {
                buffer.append(line)
            }
        }
        flush()
        return records
    }

    private static func matchTableRow(_ record: String, semesterStart: Date, semesterEnd: Date) -> EditableScheduleEvent? {
        let record = normalizeTimeLine(record)
        guard let m = firstMatch(tableRowPattern, record), m.numberOfRanges >= 7,
              let rCRN = Range(m.range(at: 1), in: record),
              let rTitle = Range(m.range(at: 2), in: record),
              let rT0 = Range(m.range(at: 3), in: record),
              let rT1 = Range(m.range(at: 4), in: record),
              let rDays = Range(m.range(at: 5), in: record),
              let rLoc = Range(m.range(at: 6), in: record)
        else { return nil }

        let crn = String(record[rCRN])
        let title = String(record[rTitle]).trimmingCharacters(in: .whitespaces)
        let t0 = String(record[rT0])
        let t1 = String(record[rT1])
        let daysToken = String(record[rDays])
        let location = String(record[rLoc]).trimmingCharacters(in: .whitespaces)
        return buildTableEvent(
            crn: crn,
            title: title,
            t0: t0,
            t1: t1,
            daysToken: daysToken,
            location: location,
            semesterStart: semesterStart,
            semesterEnd: semesterEnd
        )
    }

    private static func buildTableEvent(
        crn: String,
        title: String,
        t0: String,
        t1: String,
        daysToken: String,
        location: String,
        semesterStart: Date,
        semesterEnd: Date
    ) -> EditableScheduleEvent? {
        guard let tStart = parseTime(t0),
              let tEnd = parseTime(t1),
              let wds = parseAbbrevDays(daysToken),
              title.isEmpty == false
        else { return nil }

        return EditableScheduleEvent(
            title: title,
            location: location,
            notes: "CRN \(crn)",
            semesterStart: semesterStart,
            semesterEnd: semesterEnd,
            weekdays: wds,
            startHour: tStart.hour,
            startMinute: tStart.minute,
            endHour: tEnd.hour,
            endMinute: tEnd.minute
        )
    }

    // MARK: - Weekly grid (Monday … Sunday header + CRN cards in columns)

    private static let gridCrnLinePattern = try! NSRegularExpression(
        pattern: #"^\s*CRN\s*:\s*(\d+)\s*$"#,
        options: [.caseInsensitive]
    )

    private static let weekdayHeaderTokens: [(needle: String, weekday: Int)] = [
        ("monday", 2), ("tuesday", 3), ("wednesday", 4), ("thursday", 5),
        ("friday", 6), ("saturday", 7), ("sunday", 1),
    ]

    /// `Mon Tue Wed …` style headers (word boundaries so `Monday` is not matched as `Mon`).
    private static let shortWeekdayHeaderTokenPattern = try! NSRegularExpression(
        pattern: #"\b(Sun|Mon|Tue|Wed|Thu|Fri|Sat)\b"#,
        options: [.caseInsensitive]
    )

    /// Expands tabs to spaces so column positions line up with a typical 8-column tab stop.
    private static func expandTabsForGrid(_ s: String, tabWidth: Int = 8) -> String {
        var column = 0
        var out = ""
        for ch in s {
            if ch == "\n" {
                out.append(ch)
                column = 0
            } else if ch == "\t" {
                let advance = max(1, tabWidth - (column % tabWidth))
                out.append(String(repeating: " ", count: advance))
                column += advance
            } else {
                out.append(ch)
                column += 1
            }
        }
        return out
    }

    /// Plain-text copies of schedule **graphs** keep weekday headers; we infer the column from where `CRN:` starts.
    /// If alignment is ambiguous (common when tabs collapse or every block lines up the same), weekdays are left empty for the user to tap.
    private static func parseTimeGridSchedule(_ expandedText: String, defaultSemesterEnd: Date?) -> [EditableScheduleEvent] {
        let lines = expandedText.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        guard let headerIdx = findWeekdayHeaderLineIndex(lines),
              let columns = buildGridColumns(from: lines[headerIdx])
        else { return [] }

        let end = defaultSemesterEnd ?? Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
        let start = Calendar.current.date(byAdding: .month, value: -4, to: end) ?? end

        var drafts: [(weekdays: Set<Int>, title: String, location: String, notes: String, sh: Int, sm: Int, eh: Int, em: Int)] = []

        var i = headerIdx + 1
        while i < lines.count {
            let line = lines[i]
            guard let m = firstMatch(gridCrnLinePattern, line), m.numberOfRanges >= 2,
                  let rFull = Range(m.range(at: 0), in: line),
                  let rC = Range(m.range(at: 1), in: line)
            else {
                i += 1
                continue
            }

            let crn = String(line[rC])
            let indent = line.distance(from: line.startIndex, to: rFull.lowerBound)
            let inferred = columnWeekday(forIndent: indent, columns: columns)

            i += 1
            var body: [String] = []
            var times: (startHour: Int, startMinute: Int, endHour: Int, endMinute: Int)?
            while i < lines.count {
                let inner = lines[i]
                if firstMatch(gridCrnLinePattern, inner) != nil { break }
                if let t = matchTimeRange(in: inner) {
                    times = (t.startHour, t.startMinute, t.endHour, t.endMinute)
                    i += 1
                    break
                }
                let trimmed = inner.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty == false {
                    body.append(trimmed)
                }
                i += 1
            }

            guard let t = times else { continue }
            let (title, location) = titleAndLocation(fromGridBody: body)
            let notes = "CRN \(crn)"
            var wds = Set<Int>()
            if let inferred {
                wds.insert(inferred)
            }
            drafts.append((wds, title, location, notes, t.startHour, t.startMinute, t.endHour, t.endMinute))
        }

        let resolved = disambiguateRepeatedGridDrafts(drafts)

        return resolved.map { d in
            EditableScheduleEvent(
                title: d.title,
                location: d.location,
                notes: d.notes,
                semesterStart: start,
                semesterEnd: end,
                weekdays: d.weekdays,
                startHour: d.sh,
                startMinute: d.sm,
                endHour: d.eh,
                endMinute: d.em
            )
        }
    }

    private static func findWeekdayHeaderLineIndex(_ lines: [String]) -> Int? {
        let fullNeedles = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        for (idx, line) in lines.enumerated().prefix(120) {
            let lower = line.lowercased()
            let fullHits = fullNeedles.filter { lower.contains($0) }.count
            if fullHits >= 3 { return idx }
            let ns = line as NSString
            let nShort = shortWeekdayHeaderTokenPattern.numberOfMatches(in: line, options: [], range: NSRange(location: 0, length: ns.length))
            if nShort >= 3 { return idx }
        }
        return nil
    }

    private static func buildGridColumns(from headerLine: String) -> [(weekday: Int, startCol: Int, endCol: Int)]? {
        if let cols = buildGridColumnsFromLongWeekdayNames(headerLine), cols.count >= 3 {
            return cols
        }
        return buildGridColumnsFromShortWeekdayTokens(headerLine)
    }

    private static func buildGridColumnsFromLongWeekdayNames(_ headerLine: String) -> [(weekday: Int, startCol: Int, endCol: Int)]? {
        var hits: [(weekday: Int, start: String.Index)] = []
        for (needle, wd) in weekdayHeaderTokens {
            var search = headerLine.startIndex
            while let r = headerLine.range(of: needle, options: [.caseInsensitive], range: search ..< headerLine.endIndex) {
                hits.append((wd, r.lowerBound))
                search = r.upperBound
            }
        }
        guard hits.count >= 3 else { return nil }
        return finalizeGridColumns(headerLine: headerLine, hits: hits)
    }

    private static func buildGridColumnsFromShortWeekdayTokens(_ headerLine: String) -> [(weekday: Int, startCol: Int, endCol: Int)]? {
        let ns = headerLine as NSString
        let full = NSRange(location: 0, length: ns.length)
        var hits: [(weekday: Int, start: String.Index)] = []
        shortWeekdayHeaderTokenPattern.enumerateMatches(in: headerLine, options: [], range: full) { match, _, _ in
            guard let m = match, m.numberOfRanges >= 2,
                  let rTok = Range(m.range(at: 1), in: headerLine),
                  let wd = weekdayFromShortHeaderToken(String(headerLine[rTok]))
            else { return }
            hits.append((wd, rTok.lowerBound))
        }
        guard hits.count >= 3 else { return nil }
        return finalizeGridColumns(headerLine: headerLine, hits: hits)
    }

    private static func weekdayFromShortHeaderToken(_ token: String) -> Int? {
        let l = token.lowercased()
        if l.hasPrefix("sun") { return 1 }
        if l.hasPrefix("mon") { return 2 }
        if l.hasPrefix("tue") { return 3 }
        if l.hasPrefix("wed") { return 4 }
        if l.hasPrefix("thu") { return 5 }
        if l.hasPrefix("fri") { return 6 }
        if l.hasPrefix("sat") { return 7 }
        return nil
    }

    private static func finalizeGridColumns(headerLine: String, hits: [(weekday: Int, start: String.Index)]) -> [(weekday: Int, startCol: Int, endCol: Int)]? {
        let sorted = hits.sorted { $0.start < $1.start }
        var seen = Set<Int>()
        var ordered: [(weekday: Int, start: String.Index)] = []
        for h in sorted {
            if seen.contains(h.weekday) { continue }
            seen.insert(h.weekday)
            ordered.append(h)
        }
        ordered.sort { $0.start < $1.start }
        guard ordered.count >= 3 else { return nil }

        var columns: [(weekday: Int, startCol: Int, endCol: Int)] = []
        for (idx, h) in ordered.enumerated() {
            let startCol = headerLine.distance(from: headerLine.startIndex, to: h.start)
            let endCol: Int
            if idx + 1 < ordered.count {
                endCol = headerLine.distance(from: headerLine.startIndex, to: ordered[idx + 1].start)
            } else {
                endCol = headerLine.distance(from: headerLine.startIndex, to: headerLine.endIndex)
            }
            columns.append((h.weekday, startCol, endCol))
        }
        return columns
    }

    private static func columnWeekday(forIndent indent: Int, columns: [(weekday: Int, startCol: Int, endCol: Int)]) -> Int? {
        for c in columns where indent >= c.startCol && indent < c.endCol {
            return c.weekday
        }
        var best: (d: Int, wd: Int)?
        for c in columns {
            let mid = (c.startCol + c.endCol) / 2
            let d = abs(indent - mid)
            if best == nil || d < best!.d {
                best = (d, c.weekday)
            }
        }
        return best?.wd
    }

    private static func titleAndLocation(fromGridBody body: [String]) -> (title: String, location: String) {
        func isCourseCode(_ s: String) -> Bool {
            s.range(of: #"^[A-Z]{2,10}\s+\d{4}\s*$"#, options: .regularExpression) != nil
        }
        func isModality(_ s: String) -> Bool {
            let l = s.lowercased()
            return l.contains("instruction") || l.contains("asynchronous") || l.contains("synchronous")
                || l.contains("face-to-face") || l.contains("face to face") || l.contains("online with")
                || l.contains("hybrid")
        }

        let code = body.first(where: isCourseCode)
        let titleLine = body.first { !isModality($0) && !isCourseCode($0) }
        let base = titleLine ?? body.first ?? "Class"
        let title = code.map { "\(base) (\($0))" } ?? base

        let location = body.reversed().first { line in
            !isModality(line) && !isCourseCode(line) && line != base
        } ?? ""

        return (title, location)
    }

    private static func disambiguateRepeatedGridDrafts(
        _ drafts: [(weekdays: Set<Int>, title: String, location: String, notes: String, sh: Int, sm: Int, eh: Int, em: Int)]
    ) -> [(weekdays: Set<Int>, title: String, location: String, notes: String, sh: Int, sm: Int, eh: Int, em: Int)] {
        typealias D = (weekdays: Set<Int>, title: String, location: String, notes: String, sh: Int, sm: Int, eh: Int, em: Int)
        var out: [D] = []
        var i = 0
        while i < drafts.count {
            let ref = drafts[i]
            var cur = ref
            var j = i + 1
            while j < drafts.count,
                  drafts[j].notes == ref.notes,
                  drafts[j].title == ref.title,
                  drafts[j].location == ref.location,
                  drafts[j].sh == ref.sh, drafts[j].sm == ref.sm,
                  drafts[j].eh == ref.eh, drafts[j].em == ref.em
            {
                cur.weekdays.formUnion(drafts[j].weekdays)
                j += 1
            }

            let span = j - i
            if span >= 2, cur.weekdays.count <= 1 {
                cur.weekdays = []
                if cur.notes.contains("Graph:") == false {
                    cur.notes += "\nGraph: repeated block without distinct columns — pick weekdays."
                }
            }

            out.append(cur)
            i = j
        }
        return out
    }

    /// US-style abbreviations: M=Mon, T=Tue, W=Wed, R=Thu, F=Fri (skip ambiguous lone T when paired).
    /// Also accepts slashes/dashes between letters (`M/W/F`, `Tu/Th`) and a few bundled tokens.
    private static func parseAbbrevDays(_ s: String) -> Set<Int>? {
        let u = s.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "–", with: "")
            .replacingOccurrences(of: "—", with: "")
            .replacingOccurrences(of: "-", with: "")
        if u == "TBA" { return nil }

        let bundles: [String: Set<Int>] = [
            "MWF": [2, 4, 6],
            "MW": [2, 4],
            "WF": [4, 6],
            "MF": [2, 6],
            "MWTH": [2, 4, 5],
            "MTWR": [2, 3, 4, 5],
            "MTWRF": [2, 3, 4, 5, 6],
        ]
        if let b = bundles[u] { return b }

        var set = Set<Int>()
        var i = u.startIndex
        while i < u.endIndex {
            let c = u[i]
            switch c {
            case "M": set.insert(2); i = u.index(after: i)
            case "W": set.insert(4); i = u.index(after: i)
            case "F": set.insert(6); i = u.index(after: i)
            case "S":
                let next = u.index(after: i)
                if next < u.endIndex, u[next] == "U" { set.insert(1); i = u.index(after: next) }
                else if next < u.endIndex, u[next] == "A" { i = u.index(after: next) }
                else { set.insert(7); i = next }
            case "T":
                let next = u.index(after: i)
                if next < u.endIndex, u[next] == "H" { set.insert(5); i = u.index(after: next) }
                else if next < u.endIndex, u[next] == "U" { set.insert(3); i = u.index(after: next) }
                else { set.insert(3); i = next }
            case "R": set.insert(5); i = u.index(after: i)
            case "U": i = u.index(after: i)
            default: i = u.index(after: i)
            }
        }
        return set.isEmpty ? nil : set
    }

    private static func mergeDuplicates(_ events: [EditableScheduleEvent]) -> [EditableScheduleEvent] {
        var map: [String: EditableScheduleEvent] = [:]
        for e in events {
            let wdKey = e.weekdays.sorted().map(String.init).joined(separator: ",")
            let kind = e.sessionKind ?? ""
            let key = "\(e.notes)|\(wdKey)|\(e.startHour):\(e.startMinute)|\(e.endHour):\(e.endMinute)|\(e.location)|\(kind)|\(e.title)"
            if var existing = map[key] {
                existing.weekdays.formUnion(e.weekdays)
                map[key] = existing
            } else {
                map[key] = e
            }
        }
        return Array(map.values).sorted { a, b in
            let aNeeds = a.weekdays.isEmpty
            let bNeeds = b.weekdays.isEmpty
            if aNeeds != bNeeds { return aNeeds && !bNeeds }
            return (a.title, a.startHour, a.startMinute) < (b.title, b.startHour, b.startMinute)
        }
    }

    private static func crnFromEventNotes(_ notes: String) -> String? {
        guard let m = firstMatch(notesCrnPattern, notes),
              m.numberOfRanges >= 2,
              let r = Range(m.range(at: 1), in: notes)
        else { return nil }
        return String(notes[r])
    }

    /// Banner sometimes repeats the same meeting; merge only when slot **and CRN** match. Different CRNs at the same time/room (e.g. two courses) stay separate.
    private static func dedupeBannerSameSlot(_ events: [EditableScheduleEvent]) -> [EditableScheduleEvent] {
        func slotKey(_ e: EditableScheduleEvent) -> String {
            let wd = e.weekdays.sorted().map(String.init).joined(separator: ",")
            let loc = e.location.lowercased().filter { !$0.isWhitespace }
            let kind = e.sessionKind ?? ""
            return "\(wd)|\(e.startHour):\(e.startMinute)-\(e.endHour):\(e.endMinute)|\(loc)|\(kind)"
        }

        var buckets: [String: [EditableScheduleEvent]] = [:]
        for e in events {
            buckets[slotKey(e), default: []].append(e)
        }

        var out: [EditableScheduleEvent] = []
        for group in buckets.values {
            if group.count == 1 {
                out.append(group[0])
                continue
            }
            let distinctCRNs = Set(group.compactMap { crnFromEventNotes($0.notes) })
            if distinctCRNs.count > 1 {
                out.append(contentsOf: group)
                continue
            }
            let distinctTitles = Set(group.map { $0.title.lowercased() })
            let hasClassTitle = group.contains { $0.title == "Class" }
            if distinctTitles.count == 1 || hasClassTitle {
                out.append(mergeBannerSlotGroup(group))
            } else {
                out.append(contentsOf: group)
            }
        }
        return out.sorted { ($0.title, $0.startHour, $0.startMinute) < ($1.title, $1.startHour, $1.startMinute) }
    }

    private static func mergeBannerSlotGroup(_ group: [EditableScheduleEvent]) -> EditableScheduleEvent {
        let ranked = group.sorted { a, b in
            func rankTitle(_ t: String) -> Int {
                if t == "Class" || t == "Untitled" { return 0 }
                return min(t.count, 500)
            }
            let ra = rankTitle(a.title)
            let rb = rankTitle(b.title)
            if ra != rb { return ra > rb }
            return a.notes.count > b.notes.count
        }
        var best = ranked[0]
        for extra in ranked.dropFirst() {
            let n = extra.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            if n.isEmpty == false, best.notes.contains(n) == false {
                best.notes += "\n\(n)"
            }
        }
        return best
    }
}
