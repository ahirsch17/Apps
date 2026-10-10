#!/usr/bin/env python3
"""Generate demo seed data - Wednesday-focused schedules, 12+ friends, realistic overlaps."""

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Core cast - phone numbers are directory/signup data only (not “in contacts” flags).
CAST = [
    {"id": "stu-alex", "name": "Alex Hirsch", "email": "alex.hirsch@vt.edu", "year": "Senior", "major": "CS",
     "phone": "+15405551234"},
    {"id": "stu-john", "name": "John Martinez", "email": "john.martinez@vt.edu", "year": "Senior", "major": "CS",
     "phone": "+15405559876"},
    {"id": "stu-rachel", "name": "Rachel Chen", "email": "rachel.chen@vt.edu", "year": "Junior", "major": "CS",
     "phone": "+15405552468"},
    {"id": "stu-sarah", "name": "Sarah Kim", "email": "sarah.kim@vt.edu", "year": "Sophomore", "major": "BIT",
     "phone": None},
    {"id": "stu-mia", "name": "Mia Johnson", "email": "mia.johnson@vt.edu", "year": "Junior", "major": "CMDA",
     "phone": "+15405553001"},
    {"id": "stu-chris", "name": "Chris Brown", "email": "chris.brown@vt.edu", "year": "Senior", "major": "CS",
     "phone": None},
    {"id": "stu-taylor", "name": "Taylor Davis", "email": "taylor.davis@vt.edu", "year": "Junior", "major": "CS",
     "phone": "+15405554002"},
    {"id": "stu-jordan", "name": "Jordan Wilson", "email": "jordan.wilson@vt.edu", "year": "Sophomore", "major": "CS",
     "phone": None},
    {"id": "stu-casey", "name": "Casey Taylor", "email": "casey.taylor@vt.edu", "year": "Junior", "major": "BIT",
     "phone": None},
    {"id": "stu-avery", "name": "Avery Thomas", "email": "avery.thomas@vt.edu", "year": "Senior", "major": "CS",
     "phone": None},
    {"id": "stu-riley", "name": "Riley Anderson", "email": "riley.anderson@vt.edu", "year": "Sophomore", "major": "CMDA",
     "phone": None},
    {"id": "stu-quinn", "name": "Quinn Jackson", "email": "quinn.jackson@vt.edu", "year": "Junior", "major": "MATH",
     "phone": None},
]

# Simulated address book for demo login (stu-alex). Separate from seed student records.
SIMULATED_DEVICE_CONTACTS = [
    ("John Martinez", "+15405559876"),
    ("Rachel Chen", "+15405552468"),
    ("Mia Johnson", "+15405553001"),
    ("Taylor Davis", "+15405554002"),
    ("Parker Lewis", "+15405554101"),
]

SUGGESTIONS = [
    ("Emerson", "Clark", "CMDA"),
    ("Parker", "Lewis", "CS"),
    ("Drew", "Walker", "MATH"),
    ("Jamie", "Hall", "CS"),
    ("Blake", "Allen", "BIT"),
    ("Sydney", "Young", "ECON"),
    ("Cameron", "King", "CS"),
    ("Morgan", "Moore", "ECON"),
]

LOCATIONS = [
    "McBryde Hall", "Newman Library", "Torgersen Hall", "Goodwin Hall",
    "Burruss Hall", "Derring Hall", "Pamplin Hall", "Turner Place",
]


def section(sid, canonical, code, name, label, days, start, end, loc):
    return {
        "sectionId": sid, "canonicalCourseId": canonical, "courseCode": code,
        "courseName": name, "sectionLabel": label, "meetingDays": days,
        "startTime": start, "endTime": end, "location": loc,
    }


def build_sections():
    """Sections tuned for a realistic Wednesday on campus."""
    return [
        # Shared CS block - Alex, John, Sarah, Chris, Taylor (same section)
        section("CS2114-001", "CSE-1002", "CS 2114", "Software Design & Data Structures", "001",
                ["Mon", "Wed", "Fri"], "09:00", "09:50", "McBryde Hall"),
        section("CS2114-002", "CSE-1002", "CS 2114", "Software Design & Data Structures", "002",
                ["Mon", "Wed", "Fri"], "10:00", "10:50", "McBryde Hall"),
        # Systems - Alex 001, Rachel/Avery 002 (different section, same course)
        section("CS3214-001", "CSE-1004", "CS 3214", "Computer Systems", "001",
                ["Mon", "Wed"], "14:00", "15:15", "Torgersen Hall"),
        section("CS3214-002", "CSE-1004", "CS 3214", "Computer Systems", "002",
                ["Mon", "Wed"], "15:30", "16:45", "Torgersen Hall"),
        # Mid-morning
        section("MATH2204-001", "CSE-1006", "MATH 2204", "Linear Algebra", "001",
                ["Mon", "Wed", "Fri"], "11:00", "11:50", "Derring Hall"),
        section("MATH2204-002", "CSE-1006", "MATH 2204", "Linear Algebra", "002",
                ["Tue", "Thu"], "11:00", "11:50", "Derring Hall"),
        # Wed-only blocks that create a lunch window
        section("ECON2005-001", "CSE-1009", "ECON 2005", "Microeconomic Principles", "001",
                ["Wed", "Fri"], "11:00", "11:50", "Pamplin Hall"),
        section("CMDA2005-001", "CSE-1015", "CMDA 2005", "Data and Decisions", "001",
                ["Wed"], "10:00", "10:50", "Newman Library"),
        section("STAT3005-001", "CSE-1008", "STAT 3005", "Statistics for Engineers", "001",
                ["Tue", "Thu"], "09:30", "10:45", "Hutcheson Hall"),
        section("STAT3005-002", "CSE-1008", "STAT 3005", "Statistics for Engineers", "002",
                ["Mon", "Wed"], "13:00", "13:50", "Hutcheson Hall"),
        # Afternoon fillers
        section("BIT2405-001", "CSE-1014", "BIT 2405", "Intro to Business Analytics", "001",
                ["Mon", "Wed"], "15:30", "16:20", "Pamplin Hall"),
        section("PHYS2305-001", "CSE-1011", "PHYS 2305", "Foundations of Physics I", "001",
                ["Mon", "Wed", "Fri"], "08:00", "08:50", "Goodwin Hall"),
        section("ENGL1106-001", "CSE-1017", "ENGL 1106", "Writing and Research", "001",
                ["Tue", "Thu"], "14:00", "15:15", "Shanks Hall"),
        section("COMM2004-001", "CSE-1019", "COMM 2004", "Public Speaking", "001",
                ["Wed"], "16:00", "16:50", "Newman Library"),
        # Extra catalog for course lookup
        section("CS1114-001", "CSE-1001", "CS 1114", "Intro to Software Design", "001",
                ["Mon", "Wed", "Fri"], "13:00", "13:50", "McBryde Hall"),
        section("CS2505-001", "CSE-1003", "CS 2505", "Computer Organization I", "001",
                ["Tue", "Thu"], "11:00", "12:15", "McBryde Hall"),
    ]


def build_students():
    students = []
    for p in CAST:
        students.append({
            "id": p["id"], "name": p["name"], "email": p["email"], "schoolId": "vt",
            "year": p["year"], "major": p["major"],
            "privacy": {"shareSchedule": "full", "shareClassDetails": True},
            "phoneNumber": p["phone"],
        })
    suggestion_phones = ["+15405554101", None, "+15405554103", None, "+15405554105", None, "+15405554107", None]
    for i, (first, last, major) in enumerate(SUGGESTIONS):
        students.append({
            "id": f"stu-sug-{i:02d}",
            "name": f"{first} {last}",
            "email": f"{first.lower()}.{last.lower()}@vt.edu",
            "schoolId": "vt",
            "year": ["Sophomore", "Junior", "Senior"][i % 3],
            "major": major,
            "privacy": {"shareSchedule": "freeBusy", "shareClassDetails": True},
            "phoneNumber": suggestion_phones[i] if i < len(suggestion_phones) else None,
        })
    return students


def build_enrollments():
    """Wednesday-shaped schedules. Lunch overlap ~12:00-1:30 for core friends."""
    return [
        # Alex - Wed: Phys 8, CS 9, Math 11, lunch free, Systems 2, done ~3:15
        {"studentId": "stu-alex", "sectionId": "PHYS2305-001"},
        {"studentId": "stu-alex", "sectionId": "CS2114-001"},
        {"studentId": "stu-alex", "sectionId": "MATH2204-001"},
        {"studentId": "stu-alex", "sectionId": "CS3214-001"},
        # John - same CS section, Econ 11, long lunch overlap with Alex
        {"studentId": "stu-john", "sectionId": "CS2114-001"},
        {"studentId": "stu-john", "sectionId": "ECON2005-001"},
        {"studentId": "stu-john", "sectionId": "CS3214-002"},
        # Rachel - CMDA 10, Systems diff section 3:30, lunch partial overlap
        {"studentId": "stu-rachel", "sectionId": "CMDA2005-001"},
        {"studentId": "stu-rachel", "sectionId": "CS3214-002"},
        {"studentId": "stu-rachel", "sectionId": "MATH2204-002"},
        # Sarah - same CS as Alex
        {"studentId": "stu-sarah", "sectionId": "CS2114-001"},
        {"studentId": "stu-sarah", "sectionId": "STAT3005-002"},
        {"studentId": "stu-sarah", "sectionId": "BIT2405-001"},
        # Mia
        {"studentId": "stu-mia", "sectionId": "CS2114-001"},
        {"studentId": "stu-mia", "sectionId": "CMDA2005-001"},
        {"studentId": "stu-mia", "sectionId": "COMM2004-001"},
        # Chris, Taylor - CS 2114 same section
        {"studentId": "stu-chris", "sectionId": "CS2114-001"},
        {"studentId": "stu-chris", "sectionId": "CS3214-001"},
        {"studentId": "stu-taylor", "sectionId": "CS2114-001"},
        {"studentId": "stu-taylor", "sectionId": "MATH2204-001"},
        # Jordan - CS 2114 sec 002 (different section, same course)
        {"studentId": "stu-jordan", "sectionId": "CS2114-002"},
        {"studentId": "stu-jordan", "sectionId": "STAT3005-002"},
        # Casey - lunch overlap window
        {"studentId": "stu-casey", "sectionId": "CS2114-002"},
        {"studentId": "stu-casey", "sectionId": "ECON2005-001"},
        # Avery - Systems with Rachel
        {"studentId": "stu-avery", "sectionId": "CS3214-002"},
        {"studentId": "stu-avery", "sectionId": "CS2114-002"},
        # Riley
        {"studentId": "stu-riley", "sectionId": "CS2114-001"},
        {"studentId": "stu-riley", "sectionId": "BIT2405-001"},
        # Quinn
        {"studentId": "stu-quinn", "sectionId": "MATH2204-001"},
        {"studentId": "stu-quinn", "sectionId": "PHYS2305-001"},
    ]


def build_friendships():
    alex_friends = [
        "stu-john", "stu-rachel", "stu-sarah", "stu-mia", "stu-chris", "stu-taylor",
        "stu-jordan", "stu-casey", "stu-avery", "stu-riley", "stu-quinn",
    ]
    pairs = [( "stu-alex", f) for f in alex_friends]
    pairs += [
        ("stu-john", "stu-rachel"), ("stu-john", "stu-chris"),
        ("stu-rachel", "stu-avery"), ("stu-sarah", "stu-mia"),
    ]
    return [{"studentA": a, "studentB": b, "status": "accepted"} for a, b in pairs]


def build_friend_requests():
    now = datetime.now(timezone.utc)
    return [
        {"id": "req-0001", "fromStudentId": "stu-sug-00", "toStudentId": "stu-alex",
         "status": "pending", "createdAt": (now - timedelta(hours=5)).isoformat()},
        {"id": "req-0002", "fromStudentId": "stu-sug-01", "toStudentId": "stu-alex",
         "status": "pending", "createdAt": (now - timedelta(days=1)).isoformat()},
        {"id": "req-0003", "fromStudentId": "stu-sug-02", "toStudentId": "stu-alex",
         "status": "pending", "createdAt": (now - timedelta(days=2)).isoformat()},
    ]


def build_presence(students):
    now = datetime.now(timezone.utc)
    status_map = {
        "stu-john": ("freeNow", "Free", "Turner Place"),
        "stu-rachel": ("freeNow", "Coffee", "Newman Library"),
        "stu-sarah": ("studying", "Library", "Newman Library"),
        "stu-mia": ("onTheWay", "Headed to McBryde", "Drillfield"),
        "stu-chris": ("freeNow", "Free", "Squires"),
    }
    records = []
    for i, s in enumerate(students):
        if s["id"] in status_map:
            st, act, loc = status_map[s["id"]]
        else:
            st, act, loc = "busy", "In class", LOCATIONS[i % len(LOCATIONS)]
        records.append({
            "studentId": s["id"], "status": st, "activity": act, "location": loc,
            "lastUpdated": (now - timedelta(minutes=(i * 3) % 25)).isoformat(),
        })
    return records


def build_plans():
    now = datetime.now(timezone.utc)
    return [
        {"id": "plan-0001", "creatorId": "stu-john", "type": "food", "title": "Lunch at Turner",
         "location": "Turner Place", "startTime": (now + timedelta(minutes=90)).isoformat(),
         "visibility": "friends"},
    ]


def build_interests():
    return [
        {"id": "int-athletics", "schoolId": "vt", "name": "VT Athletics", "icon": "sportscourt.fill"},
        {"id": "int-im", "schoolId": "vt", "name": "IM leagues", "icon": "figure.run"},
        {"id": "int-pickup", "schoolId": "vt", "name": "Pickup sports", "icon": "sportscourt"},
        {"id": "int-volleyball", "schoolId": "vt", "name": "Volleyball", "icon": "figure.volleyball"},
        {"id": "int-soccer", "schoolId": "vt", "name": "Soccer", "icon": "soccerball"},
        {"id": "int-basketball", "schoolId": "vt", "name": "Basketball", "icon": "basketball.fill"},
        {"id": "int-clubs", "schoolId": "vt", "name": "Clubs", "icon": "person.3.fill"},
        {"id": "int-wellness", "schoolId": "vt", "name": "Wellness", "icon": "heart.fill"},
        {"id": "int-boardgames", "schoolId": "vt", "name": "Board games", "icon": "dice.fill"},
        {"id": "int-campus", "schoolId": "vt", "name": "Campus hangouts", "icon": "building.2.fill"},
    ]


def _event(
    eid, interest_id, category, title, description, location,
    start, end, matching="none", recurring=False, recurrence=None, cover=None
):
    """Seed-only helper. App logic never hardcodes these titles."""
    return {
        "id": eid,
        "schoolId": "vt",
        "interestId": interest_id,
        "category": category,
        "title": title,
        "description": description,
        "location": location,
        "startTime": start.isoformat() if hasattr(start, "isoformat") else start,
        "endTime": end.isoformat() if hasattr(end, "isoformat") else end,
        "matchingKind": matching,
        "isRecurring": recurring,
        "recurrenceLabel": recurrence,
        "coverImageName": cover,
    }


def build_campus_events():
    """Demo catalog only - swap for live posts from VT, clubs, and students later.

    Categories (data-driven Discover filters):
      official  - VT Athletics + university-sponsored (Gobblerfest, career fair, dining, etc.)
      im        - IMLeagues roster fill / registration windows
      pickup    - Informal recurring games students stumble into
      clubs     - Student org programming
      campus    - Soft hangouts (library, yoga) not tied to a course
      popups    - Student-created one-offs (empty in seed; users populate later)
      local     - Town/bar/local (empty in seed for now)
    """
    now = datetime.now(timezone.utc)
    sat = now + timedelta(days=(5 - now.weekday()) % 7)  # upcoming Saturday-ish
    if sat <= now:
        sat = sat + timedelta(days=7)
    sat_eve = sat.replace(hour=23, minute=30, second=0, microsecond=0)  # ~7:30pm ET
    fri = sat - timedelta(days=1)
    next_week = now + timedelta(days=7)

    return [
        # --- Official: VT Athletics (example opponents; replace with live schedule feed) ---
        _event(
            "evt-fb-uva", "int-athletics", "official",
            "Football · Virginia Tech vs UVA",
            "Saturday night Commonwealth Cup vibe. Keep me posted for kickoff reminders and watch-party pop-ups nearby.",
            "Lane Stadium",
            sat_eve,
            sat_eve + timedelta(hours=3),
            matching="newcomer", cover="event-soccer",
        ),
        _event(
            "evt-mbb-duke", "int-athletics", "official",
            "Men's Basketball · VT vs Duke",
            "Cassell Coliseum. Student section energy. Track the tip and optional ride/watch-group posts from friends.",
            "Cassell Coliseum",
            (next_week + timedelta(days=2)).replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(hours=1),
            (next_week + timedelta(days=2)).replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(hours=3),
            matching="newcomer", cover="event-volleyball",
        ),
        _event(
            "evt-wbb-unc", "int-athletics", "official",
            "Women's Basketball · VT vs UNC",
            "Hokie women's basketball at Cassell. Free/cheap for students depending on the carding policy that week.",
            "Cassell Coliseum",
            (next_week + timedelta(days=4)).replace(hour=23, minute=0, second=0, microsecond=0),
            (next_week + timedelta(days=4)).replace(hour=23, minute=0, second=0, microsecond=0) + timedelta(hours=2),
            matching="none", cover="event-volleyball",
        ),
        _event(
            "evt-baseball-clemson", "int-athletics", "official",
            "Baseball · VT vs Clemson",
            "English Field. Afternoon conference series feel. Good low-pressure way to be around campus sports.",
            "English Field",
            (now + timedelta(days=6)).replace(hour=18, minute=0, second=0, microsecond=0),
            (now + timedelta(days=6)).replace(hour=18, minute=0, second=0, microsecond=0) + timedelta(hours=3),
            matching="none", cover="event-soccer",
        ),
        _event(
            "evt-softball-nd", "int-athletics", "official",
            "Softball · VT vs Notre Dame",
            "Tech Softball Park. Weekend series. Bring friends without needing a full plan.",
            "Tech Softball Park",
            (now + timedelta(days=8)).replace(hour=17, minute=0, second=0, microsecond=0),
            (now + timedelta(days=8)).replace(hour=17, minute=0, second=0, microsecond=0) + timedelta(hours=2),
            matching="none", cover="event-volleyball",
        ),

        # --- Official: university life (Student Affairs / campus ops style) ---
        _event(
            "evt-gobblerfest", "int-campus", "official",
            "Gobblerfest",
            "Org fair on the Drillfield. Hundreds of clubs in one walk. Track it so you remember to go during the window.",
            "Drillfield",
            fri.replace(hour=16, minute=0, second=0, microsecond=0),
            fri.replace(hour=20, minute=0, second=0, microsecond=0),
            matching="newcomer", cover="event-board-games",
        ),
        _event(
            "evt-career-fair", "int-campus", "official",
            "Fall Career Fair",
            "University-sponsored recruiting fair. Bring resumes. Keep me posted for time/location updates.",
            "Cassell Coliseum / Squires (check posting)",
            (now + timedelta(days=10)).replace(hour=14, minute=0, second=0, microsecond=0),
            (now + timedelta(days=10)).replace(hour=14, minute=0, second=0, microsecond=0) + timedelta(hours=5),
            matching="none", cover="event-study",
        ),
        _event(
            "evt-dining-grilled-cheese", "int-campus", "official",
            "Dining special · Grilled cheese night",
            "Example of dining ops promotions students miss in email. Track for the night it's on.",
            "D2 / Owens (demo)",
            (now + timedelta(days=2)).replace(hour=22, minute=0, second=0, microsecond=0),
            (now + timedelta(days=2)).replace(hour=22, minute=0, second=0, microsecond=0) + timedelta(hours=2),
            matching="none", recurring=True, recurrence="Promo nights", cover="event-board-games",
        ),
        _event(
            "evt-library-finals", "int-campus", "official",
            "Library finals week late night",
            "Newman extended hours / snack events during finals. University service programming, not a class group.",
            "Newman Library",
            (now + timedelta(days=20)).replace(hour=1, minute=0, second=0, microsecond=0),
            (now + timedelta(days=20)).replace(hour=1, minute=0, second=0, microsecond=0) + timedelta(hours=4),
            matching="none", cover="event-study",
        ),

        # --- IM leagues ---
        _event(
            "evt-vb-im", "int-im", "im",
            "Need players · CoRec 6v6 IM Volleyball",
            "Fall Block 2 style league (6v6 CoRec, gender max 3 on a full roster). Looking for a few more for a recreational team before registration closes. Not open gym - IMLeagues team fill.",
            "War Memorial Hall courts",
            (now + timedelta(days=1)).replace(hour=22, minute=0, second=0, microsecond=0),
            (now + timedelta(days=1)).replace(hour=22, minute=0, second=0, microsecond=0) + timedelta(hours=2),
            matching="partner", recurrence="Fall Block · roster fill", cover="event-volleyball",
        ),
        _event(
            "evt-flag-im", "int-im", "im",
            "Looking for a team · 7v7 Flag Football",
            "Fall Block 1 IM flag football. Men's / Women's / CoRec divisions. Keep me posted if you want a spot or have open roster seats.",
            "IM fields (Rec Sports)",
            (now + timedelta(days=3, hours=17)),
            (now + timedelta(days=3, hours=19)),
            matching="partner", recurrence="Fall Block · registration window", cover="event-soccer",
        ),
        _event(
            "evt-bball-im", "int-im", "im",
            "Open seats · CoRec 5v5 IM Basketball",
            "Spring Block staple: 5v5 with Competitive and Recreational divisions. Need 1-2 more for a rec CoRec squad.",
            "War Memorial / Rec courts (IM schedule)",
            (now + timedelta(days=4, hours=19)),
            (now + timedelta(days=4, hours=21)),
            matching="partner", recurrence="Spring Block · roster fill", cover="event-volleyball",
        ),

        # --- Pickup ---
        _event(
            "evt-soccer-pickup", "int-pickup", "pickup",
            "Pickup soccer · Rec fields",
            "Casual games at the Rec Sports fields. Not an IM league - whoever shows. Great if you want to play without joining a team.",
            "Rec Sports fields",
            (now + timedelta(days=2, hours=17)),
            (now + timedelta(days=2, hours=19)),
            matching="newcomer", recurring=True, recurrence="Most weekends · when people show", cover="event-soccer",
        ),
        _event(
            "evt-bball-pritchard", "int-pickup", "pickup",
            "Pickup basketball · Pritchard courts",
            "Outdoor courts by Pritchard. Runs come and go - Keep me posted when someone's heading over or needs +1.",
            "Courts by Pritchard Hall",
            (now + timedelta(days=1)).replace(hour=21, minute=30, second=0, microsecond=0),
            (now + timedelta(days=1)).replace(hour=21, minute=30, second=0, microsecond=0) + timedelta(hours=2),
            matching="newcomer", recurring=True, recurrence="Evenings · weather permitting", cover="event-volleyball",
        ),
        _event(
            "evt-bball-alight", "int-pickup", "pickup",
            "Pickup basketball · Alight courts",
            "Alight apartment courts - common pickup spot. Post when you're going so people who don't live there can still find a game.",
            "Alight courts",
            (now + timedelta(days=1, hours=18)),
            (now + timedelta(days=1, hours=20)),
            matching="newcomer", recurring=True, recurrence="Recurring pickup", cover="event-volleyball",
        ),
        _event(
            "evt-sand-vb-pickup", "int-pickup", "pickup",
            "Pickup sand volleyball",
            "Sand courts on campus. Not the same as IM 4v4 sand volleyball league - drop-in when people gather.",
            "Campus sand volleyball courts",
            (now + timedelta(days=2, hours=16)),
            (now + timedelta(days=2, hours=18)),
            matching="newcomer", recurring=True, recurrence="Afternoons / weekends", cover="event-volleyball",
        ),

        # --- Campus hangouts / clubs ---
        _event(
            "evt-yoga-sunset", "int-wellness", "campus",
            "Sunset Yoga",
            "Outdoor flow on the Drillfield. Mats provided. Drop in anytime - no commitment.",
            "Drillfield",
            (now + timedelta(days=1)).replace(hour=22, minute=0, second=0, microsecond=0),
            (now + timedelta(days=1)).replace(hour=22, minute=0, second=0, microsecond=0) + timedelta(hours=1),
            matching="newcomer", recurring=True, recurrence="Every Thursday", cover="event-yoga-sunset",
        ),
        _event(
            "evt-study-lib", "int-campus", "campus",
            "Quiet study hang · Newman",
            "Open study company at Newman - not tied to a specific class. Course-specific groups should be student pop-ups where the poster names the course.",
            "Newman Library",
            (now + timedelta(days=1, hours=14)),
            (now + timedelta(days=1, hours=16)),
            matching="none", recurring=True, recurrence="Weeknights", cover="event-study",
        ),
        _event(
            "evt-board-games", "int-boardgames", "clubs",
            "Board Game Night",
            "Squires Student Center lounge. Drop in solo or bring friends.",
            "Squires Student Center",
            (now + timedelta(days=1, hours=19)),
            (now + timedelta(days=1, hours=21)),
            matching="newcomer", recurring=True, recurrence="Every Friday", cover="event-board-games",
        ),
    ]


# CAST members with enrollments - used for realistic event rosters
ENROLLED_CAST = [
    "stu-alex", "stu-john", "stu-rachel", "stu-sarah", "stu-mia", "stu-chris",
    "stu-taylor", "stu-jordan", "stu-casey", "stu-avery", "stu-riley", "stu-quinn",
]


def build_event_participations():
    """
    Every participant is a real enrolled student. Displayed counts = len(unique studentIds).
    Alex (stu-alex) is left off events so the demo can join and bump the count live.
    """
    parts = []

    def add(event_id, interested, partners=None):
        for sid in interested:
            parts.append({"eventId": event_id, "studentId": sid, "kind": "interested"})
        for sid in partners or []:
            parts.append({"eventId": event_id, "studentId": sid, "kind": "lookingForPartner"})

    # Official athletics / university - high awareness counts, Alex excluded for demo join
    add("evt-fb-uva",
        ["stu-john", "stu-chris", "stu-taylor", "stu-jordan", "stu-casey", "stu-riley", "stu-quinn"],
        ["stu-sarah", "stu-mia"])
    add("evt-mbb-duke",
        ["stu-john", "stu-chris", "stu-taylor", "stu-avery", "stu-riley"])
    add("evt-wbb-unc", ["stu-rachel", "stu-sarah", "stu-mia", "stu-avery"])
    add("evt-baseball-clemson", ["stu-john", "stu-jordan", "stu-casey"])
    add("evt-softball-nd", ["stu-rachel", "stu-sarah", "stu-quinn"])
    add("evt-gobblerfest",
        ["stu-john", "stu-rachel", "stu-sarah", "stu-mia", "stu-chris", "stu-taylor", "stu-jordan"],
        ["stu-casey"])
    add("evt-career-fair", ["stu-rachel", "stu-avery", "stu-riley", "stu-quinn"])
    add("evt-dining-grilled-cheese", ["stu-john", "stu-chris", "stu-taylor", "stu-jordan", "stu-casey"])
    add("evt-library-finals", ["stu-rachel", "stu-sarah", "stu-avery"])

    # CoRec 6v6 IM Volleyball roster fill
    add("evt-vb-im",
        ["stu-sarah", "stu-chris", "stu-taylor", "stu-jordan", "stu-casey",
         "stu-avery", "stu-riley", "stu-quinn"],
        ["stu-john", "stu-rachel", "stu-mia"])
    add("evt-flag-im", ["stu-chris", "stu-taylor", "stu-jordan", "stu-casey"], ["stu-john"])
    add("evt-bball-im", ["stu-rachel", "stu-sarah", "stu-mia", "stu-avery"], ["stu-riley"])

    add("evt-soccer-pickup",
        ["stu-john", "stu-taylor", "stu-jordan", "stu-casey", "stu-riley",
         "stu-chris", "stu-rachel", "stu-avery"],
        ["stu-sarah", "stu-mia", "stu-quinn"])
    add("evt-bball-pritchard", ["stu-john", "stu-chris", "stu-taylor", "stu-jordan"], ["stu-casey"])
    add("evt-bball-alight", ["stu-mia", "stu-quinn", "stu-riley"])
    add("evt-sand-vb-pickup", ["stu-sarah", "stu-rachel", "stu-avery"], ["stu-mia"])

    add("evt-study-lib", [sid for sid in ENROLLED_CAST if sid != "stu-alex"])
    add("evt-yoga-sunset", ["stu-rachel", "stu-sarah", "stu-mia"], ["stu-taylor"])
    add("evt-board-games", ["stu-jordan", "stu-casey", "stu-avery"], ["stu-chris"])

    return parts


def build_partner_profiles(students):
    """Profiles derived from real student records - one per lookingForPartner row."""
    by_id = {s["id"]: s for s in students}
    specs = [
        ("stu-sarah", "evt-fb-uva", "First big game", "Don't know anyone going - want a crew"),
        ("stu-mia", "evt-fb-uva", "Out-of-state", "Looking for people to walk over with"),
        ("stu-casey", "evt-gobblerfest", "Transfer", "Want someone to walk clubs with"),
        ("stu-john", "evt-vb-im", "Intermediate", "Need a setter for CoRec 6v6"),
        ("stu-rachel", "evt-vb-im", "Played in high school", "Looking for CoRec teammates"),
        ("stu-mia", "evt-vb-im", "Beginner friendly", "New to IM leagues, want a squad"),
        ("stu-john", "evt-flag-im", "Played HS football", "Have a few people - need more for 7v7"),
        ("stu-riley", "evt-bball-im", "Rec level", "Open seat on spring CoRec 5v5"),
        ("stu-sarah", "evt-soccer-pickup", "Never played pickup at VT", "Don't know anyone who goes to Rec fields"),
        ("stu-mia", "evt-soccer-pickup", "Casual", "First time joining Rec-field pickup"),
        ("stu-quinn", "evt-soccer-pickup", "Casual player", "Just want to run - don't know the regulars"),
        ("stu-casey", "evt-bball-pritchard", "Pickup only", "Heading to Pritchard courts tonight"),
        ("stu-mia", "evt-sand-vb-pickup", "Casual", "Want to start a sand game if 3-4 more show"),
    ]
    out = []
    for sid, eid, exp, note in specs:
        s = by_id[sid]
        out.append({
            "studentId": sid, "eventId": eid,
            "displayName": s["name"].split()[0],
            "year": s["year"],
            "experienceNote": exp,
            "lookingNote": note,
            "socialHandle": None,
        })
    return out


def build_student_profiles(students):
    return [
        {"studentId": "stu-alex", "interestIds": ["int-athletics", "int-im", "int-pickup"], "onboardingComplete": True},
        {"studentId": "stu-john", "interestIds": ["int-athletics", "int-soccer", "int-im"], "onboardingComplete": True},
        {"studentId": "stu-rachel", "interestIds": ["int-volleyball", "int-im", "int-campus"], "onboardingComplete": True},
    ] + [
        {"studentId": s["id"], "interestIds": [], "onboardingComplete": False}
        for s in students if s["id"] not in ("stu-alex", "stu-john", "stu-rachel")
    ]


def validate_seed(payload):
    """Ensure participations reference enrolled students only."""
    student_ids = {s["id"] for s in payload["students"]}
    event_ids = {e["id"] for e in payload["campusEvents"]}
    section_ids = {s["sectionId"] for s in payload["sections"]}
    enrolled = {e["studentId"] for e in payload["enrollments"]}
    errors = []

    for e in payload["enrollments"]:
        if e["studentId"] not in student_ids:
            errors.append(f"enrollment unknown student {e['studentId']}")
        if e["sectionId"] not in section_ids:
            errors.append(f"enrollment unknown section {e['sectionId']}")

    for p in payload["eventParticipations"]:
        if p["studentId"] not in student_ids:
            errors.append(f"participation unknown student {p['studentId']}")
        elif p["studentId"] not in enrolled:
            errors.append(f"participation {p['studentId']} has no enrollment")
        if p["eventId"] not in event_ids:
            errors.append(f"participation unknown event {p['eventId']}")

    seeking = {(p["eventId"], p["studentId"]) for p in payload["eventParticipations"]
               if p["kind"] == "lookingForPartner"}
    for pp in payload["partnerProfiles"]:
        if (pp["eventId"], pp["studentId"]) not in seeking:
            errors.append(f"partner profile missing participation for {pp['studentId']}")

    if errors:
        raise ValueError("Seed validation failed:\n" + "\n".join(f"  - {x}" for x in errors))


def generate_data():
    students = build_students()
    now = datetime.now(timezone.utc)
    return {
        "generatedAt": now.isoformat(),
        "universities": [{"id": "vt", "name": "Virginia Tech", "emailDomain": "vt.edu",
                          "timezone": "America/New_York"}],
        "sections": build_sections(),
        "students": students,
        "enrollments": build_enrollments(),
        "friendships": build_friendships(),
        "friendRequests": build_friend_requests(),
        "presence": build_presence(students),
        "plans": build_plans(),
        "interests": build_interests(),
        "studentProfiles": build_student_profiles(students),
        "campusEvents": build_campus_events(),
        "eventParticipations": build_event_participations(),
        "partnerProfiles": build_partner_profiles(students),
    }


def build_simulated_device_contacts():
    return {
        "ownerStudentId": "stu-alex",
        "contacts": [
            {"displayName": name, "phoneNumber": phone}
            for name, phone in SIMULATED_DEVICE_CONTACTS
        ],
    }


def main():
    output = Path(__file__).resolve().parents[1] / "Sparq" / "Resources" / "seed_data.json"
    contacts_output = output.parent / "simulated_device_contacts.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = generate_data()
    validate_seed(payload)
    output.write_text(json.dumps(payload, indent=2))
    contacts_output.write_text(json.dumps(build_simulated_device_contacts(), indent=2))
    vb_real = len({p["studentId"] for p in payload["eventParticipations"] if p["eventId"] == "evt-vb-im"})
    print(f"Wrote {output}")
    print(f"Wrote {contacts_output}")
    print(f"students={len(payload['students'])}, sections={len(payload['sections'])}, "
          f"event_participations={len(payload['eventParticipations'])}, vb_real={vb_real}")


if __name__ == "__main__":
    main()
