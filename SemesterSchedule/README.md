# Schedule (SemesterSchedule)

Paste a class schedule from the student portal, review the meetings, then add them as weekly calendar events for the term.

The main format is the **Student Schedule** page used across many US colleges (Ellucian Banner / self-service). That is not Virginia Tech–specific — Radford, VT, and a long list of other schools print the same layout: course title, section, date range, weekday, Type/Location, instructor, CRN.

Copy as text (Select All → Copy on the registrar page, or from a registration email). Screenshots are not supported.

If a paste is messy, you can still add or edit a class by hand before it goes on the calendar.

## Ways to import

| Action | What it accepts |
|---|---|
| **Paste schedule** | Clipboard text from the student portal or a registration email |
| **Text file** | `.txt`, `.csv`, `.rtf`, or a text PDF of that same paste |

## Calendar targets

| Choice in the app | What happens |
|---|---|
| **Apple** | Writes into a calendar on the iPhone via EventKit. Pick iCloud, a Google account already added in **Settings → Calendar**, or any other writable calendar. |
| **Google** | Shares a `.ics` file. Open it in the Google Calendar app (or import at [calendar.google.com](https://calendar.google.com)). |
| **Both** | Saves on the phone **and** shares the `.ics` for Google. |

No Google OAuth client is required — Google Calendar accepts the same ICS that Apple Calendar uses.

## Supported paste formats

1. **Student Schedule (common US portal)** — course title + section, date ranges, weekday, Type/Location, instructors, CRN. Lab + lecture under one CRN stay one class. Mini-calendar letters (`S M T W T F S`) are ignored.
2. **Tabular SIS course list** — 12-column table with modality / grade option / part of term (TBA rows shown but not imported)
3. **Weekly Mon–Sun grid** — column-aligned `CRN:` blocks
4. **Table-like rows** — `CRN DEPT #### Title time–time DAYS location`
5. **Loose syllabus / notes** — title + days + time on one or two lines (`MATH 2114 Linear Algebra MWF 9:00 AM - 9:50 AM Hall 100`)

Day codes: `MWF`, `MW`, `TR`, `Tu/Th`, `TTH`, `M/W/F`, plus letter scans. Times: `9:00 AM - 9:50 AM`, en-dashes, glued `9:00AM`, and 24-hour `12:30-13:45`.

## Run on a phone

1. Open `SemesterSchedule.xcodeproj` in Xcode
2. Select your Team (defaults to Hirsch Engineering `SPDTT4AL46`)
3. Plug in an iPhone → Run
4. Grant calendar access when prompted

## Tests

```bash
cd SemesterSchedule
xcodegen generate
xcodebuild test -scheme SemesterSchedule -destination 'platform=iOS Simulator,name=iPhone 16'
```

Paste goldens, a multi-school corpus, and `CalendarEventCreationTests` (blueprint + ICS RRULE) run before anything hits a real calendar.
