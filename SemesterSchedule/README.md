# Schedule (SemesterSchedule)

Paste a school registrar schedule → review meetings → add them as weekly recurring calendar events for the semester.

## Calendar targets

| Choice in the app | What happens |
|---|---|
| **Apple** | Writes into a calendar on the iPhone via EventKit. Pick iCloud, a Google account already added in **Settings → Calendar**, or any other writable calendar. |
| **Google** | Shares a `.ics` file. Open it in the Google Calendar app (or import at [calendar.google.com](https://calendar.google.com)). |
| **Both** | Saves on the phone **and** shares the `.ics` for Google. |

No Google OAuth client is required — Google Calendar accepts the same ICS that Apple Calendar uses.

## Supported paste formats

1. **Banner / vertical enrollment** — `Registered`, date ranges, weekday rows, lab/lecture splits, CRNs  
2. **Virginia Tech–style tabular SIS** — 12-column table (TBA/async rows shown but not imported)  
3. **Weekly Mon–Sun grid** — column-aligned `CRN:` blocks  
4. **Table-like rows** — `CRN DEPT #### Title time–time DAYS location`

Day codes: `MWF`, `MW`, `TR`, `Tu/Th`, `TTH`, `M/W/F`, plus letter scans. Times: `9:00 AM - 9:50 AM`, en-dashes, and 24-hour `12:30-13:45`.

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

Parse goldens plus `CalendarEventCreationTests` (blueprint + ICS RRULE) are run to verify events are built correctly before anything hits a real calendar.
