# Schedule (SemesterSchedule)

Paste a class schedule from the student portal, review the meetings, then add them as weekly calendar events for the term.

Copy the schedule as text (Select All → Copy on the registrar page, or from a registration email). Screenshots and photos are not supported yet.

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

1. **Student portal / Banner vertical schedule** — course title + section, date ranges, weekday, Type/Location line, instructors, CRN. Lab + lecture under one CRN stay one class. Calendar widget letters (`S M T W T F S`) are ignored.
2. **Virginia Tech–style tabular SIS** — 12-column table (TBA/async rows shown but not imported)
3. **Weekly Mon–Sun grid** — column-aligned `CRN:` blocks
4. **Table-like rows** — `CRN DEPT #### Title time–time DAYS location`

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
