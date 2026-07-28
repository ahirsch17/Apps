#!/usr/bin/env python3
"""Generate demo seed data — Wednesday-focused schedules, 12+ friends, realistic overlaps."""

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Core cast + extended friend group (all connected to Alex)
CAST = [
    {"id": "stu-alex", "name": "Alex Hirsch", "email": "alex.hirsch@vt.edu", "year": "Senior", "major": "CS",
     "phone": "+15405551234", "suggestedVia": None},
    {"id": "stu-john", "name": "John Martinez", "email": "john.martinez@vt.edu", "year": "Senior", "major": "CS",
     "phone": "+15405559876", "suggestedVia": "contacts"},
    {"id": "stu-rachel", "name": "Rachel Chen", "email": "rachel.chen@vt.edu", "year": "Junior", "major": "CS",
     "phone": "+15405552468", "suggestedVia": "contacts"},
    {"id": "stu-sarah", "name": "Sarah Kim", "email": "sarah.kim@vt.edu", "year": "Sophomore", "major": "BIT",
     "phone": None, "suggestedVia": None},
    {"id": "stu-mia", "name": "Mia Johnson", "email": "mia.johnson@vt.edu", "year": "Junior", "major": "CMDA",
     "phone": "+15405553001", "suggestedVia": "contacts"},
    {"id": "stu-chris", "name": "Chris Brown", "email": "chris.brown@vt.edu", "year": "Senior", "major": "CS",
     "phone": None, "suggestedVia": None},
    {"id": "stu-taylor", "name": "Taylor Davis", "email": "taylor.davis@vt.edu", "year": "Junior", "major": "CS",
     "phone": None, "suggestedVia": "contacts"},
    {"id": "stu-jordan", "name": "Jordan Wilson", "email": "jordan.wilson@vt.edu", "year": "Sophomore", "major": "CS",
     "phone": None, "suggestedVia": None},
    {"id": "stu-casey", "name": "Casey Taylor", "email": "casey.taylor@vt.edu", "year": "Junior", "major": "BIT",
     "phone": None, "suggestedVia": None},
    {"id": "stu-avery", "name": "Avery Thomas", "email": "avery.thomas@vt.edu", "year": "Senior", "major": "CS",
     "phone": None, "suggestedVia": None},
    {"id": "stu-riley", "name": "Riley Anderson", "email": "riley.anderson@vt.edu", "year": "Sophomore", "major": "CMDA",
     "phone": None, "suggestedVia": None},
    {"id": "stu-quinn", "name": "Quinn Jackson", "email": "quinn.jackson@vt.edu", "year": "Junior", "major": "MATH",
     "phone": None, "suggestedVia": None},
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
        # Shared CS block — Alex, John, Sarah, Chris, Taylor (same section)
        section("CS2114-001", "CSE-1002", "CS 2114", "Software Design & Data Structures", "001",
                ["Mon", "Wed", "Fri"], "09:00", "09:50", "McBryde Hall"),
        section("CS2114-002", "CSE-1002", "CS 2114", "Software Design & Data Structures", "002",
                ["Mon", "Wed", "Fri"], "10:00", "10:50", "McBryde Hall"),
        # Systems — Alex 001, Rachel/Avery 002 (different section, same course)
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
            "phoneNumber": p["phone"], "suggestedVia": p["suggestedVia"],
        })
    for i, (first, last, major) in enumerate(SUGGESTIONS):
        students.append({
            "id": f"stu-sug-{i:02d}",
            "name": f"{first} {last}",
            "email": f"{first.lower()}.{last.lower()}@vt.edu",
            "schoolId": "vt",
            "year": ["Sophomore", "Junior", "Senior"][i % 3],
            "major": major,
            "privacy": {"shareSchedule": "freeBusy", "shareClassDetails": True},
            "phoneNumber": None,
            "suggestedVia": "contacts" if i % 2 == 0 else None,
        })
    return students


def build_enrollments():
    """Wednesday-shaped schedules. Lunch overlap ~12:00–1:30 for core friends."""
    return [
        # Alex — Wed: Phys 8, CS 9, Math 11, lunch free, Systems 2, done ~3:15
        {"studentId": "stu-alex", "sectionId": "PHYS2305-001"},
        {"studentId": "stu-alex", "sectionId": "CS2114-001"},
        {"studentId": "stu-alex", "sectionId": "MATH2204-001"},
        {"studentId": "stu-alex", "sectionId": "CS3214-001"},
        # John — same CS section, Econ 11, long lunch overlap with Alex
        {"studentId": "stu-john", "sectionId": "CS2114-001"},
        {"studentId": "stu-john", "sectionId": "ECON2005-001"},
        {"studentId": "stu-john", "sectionId": "CS3214-002"},
        # Rachel — CMDA 10, Systems diff section 3:30, lunch partial overlap
        {"studentId": "stu-rachel", "sectionId": "CMDA2005-001"},
        {"studentId": "stu-rachel", "sectionId": "CS3214-002"},
        {"studentId": "stu-rachel", "sectionId": "MATH2204-002"},
        # Sarah — same CS as Alex
        {"studentId": "stu-sarah", "sectionId": "CS2114-001"},
        {"studentId": "stu-sarah", "sectionId": "STAT3005-002"},
        {"studentId": "stu-sarah", "sectionId": "BIT2405-001"},
        # Mia
        {"studentId": "stu-mia", "sectionId": "CS2114-001"},
        {"studentId": "stu-mia", "sectionId": "CMDA2005-001"},
        {"studentId": "stu-mia", "sectionId": "COMM2004-001"},
        # Chris, Taylor — CS 2114 same section
        {"studentId": "stu-chris", "sectionId": "CS2114-001"},
        {"studentId": "stu-chris", "sectionId": "CS3214-001"},
        {"studentId": "stu-taylor", "sectionId": "CS2114-001"},
        {"studentId": "stu-taylor", "sectionId": "MATH2204-001"},
        # Jordan — CS 2114 sec 002 (different section, same course)
        {"studentId": "stu-jordan", "sectionId": "CS2114-002"},
        {"studentId": "stu-jordan", "sectionId": "STAT3005-002"},
        # Casey — lunch overlap window
        {"studentId": "stu-casey", "sectionId": "CS2114-002"},
        {"studentId": "stu-casey", "sectionId": "ECON2005-001"},
        # Avery — Systems with Rachel
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
        {"id": "int-volleyball", "schoolId": "vt", "name": "Volleyball", "icon": "sportscourt.fill"},
        {"id": "int-soccer", "schoolId": "vt", "name": "Soccer", "icon": "soccerball"},
        {"id": "int-basketball", "schoolId": "vt", "name": "Basketball", "icon": "basketball.fill"},
        {"id": "int-study", "schoolId": "vt", "name": "Study groups", "icon": "book.fill"},
        {"id": "int-intramurals", "schoolId": "vt", "name": "Intramurals", "icon": "figure.run"},
    ]


def build_campus_events():
    now = datetime.now(timezone.utc)
    tomorrow_eve = now + timedelta(days=1)
    # promoted* = campus-wide padding; real CAST students fill eventParticipations
    return [
        {"id": "evt-vb-im", "schoolId": "vt", "interestId": "int-volleyball",
         "title": "IM Volleyball — Open Gym",
         "description": "Drop-in at War Memorial. All skill levels. Bring a friend or find a partner here.",
         "location": "War Memorial Gym",
         "startTime": tomorrow_eve.replace(hour=18, minute=0, second=0, microsecond=0).isoformat(),
         "endTime": tomorrow_eve.replace(hour=20, minute=0, second=0, microsecond=0).isoformat(),
         "promotedInterestedCount": 37, "promotedPartnerCount": 6,
         "matchingKind": "partner", "isRecurring": True, "recurrenceLabel": "Every Wednesday"},
        {"id": "evt-soccer-pickup", "schoolId": "vt", "interestId": "int-soccer",
         "title": "Saturday Night Pickup Soccer",
         "description": "Casual game on the Drillfield. New? Opt in to meet others who don't know anyone either.",
         "location": "Drillfield",
         "startTime": (now + timedelta(days=2, hours=17)).isoformat(),
         "endTime": (now + timedelta(days=2, hours=19)).isoformat(),
         "promotedInterestedCount": 23, "promotedPartnerCount": 5,
         "matchingKind": "newcomer", "isRecurring": True, "recurrenceLabel": "Every Saturday night"},
        {"id": "evt-study-lib", "schoolId": "vt", "interestId": "int-study",
         "title": "CS 2114 Study Session",
         "description": "Newman Library 2nd floor. Work problems together.",
         "location": "Newman Library",
         "startTime": (now + timedelta(days=1, hours=14)).isoformat(),
         "endTime": (now + timedelta(days=1, hours=16)).isoformat(),
         "promotedInterestedCount": 14, "promotedPartnerCount": 0,
         "matchingKind": "none", "isRecurring": False, "recurrenceLabel": None},
    ]


# CAST members with enrollments — used for realistic event rosters
ENROLLED_CAST = [
    "stu-alex", "stu-john", "stu-rachel", "stu-sarah", "stu-mia", "stu-chris",
    "stu-taylor", "stu-jordan", "stu-casey", "stu-avery", "stu-riley", "stu-quinn",
]


def build_event_participations():
    """
    Every participant is a real student from the VT seed roster with enrollments.
    promoted* counts on events pad to campus-scale totals for social proof.
    """
    parts = []
    # IM Volleyball — partner matching (11 enrolled friends interested/seeking)
    vb_interested = ["stu-sarah", "stu-chris", "stu-taylor", "stu-jordan", "stu-casey",
                     "stu-avery", "stu-riley", "stu-quinn"]
    vb_partner = ["stu-john", "stu-rachel", "stu-mia"]
    for sid in vb_interested:
        parts.append({"eventId": "evt-vb-im", "studentId": sid, "kind": "interested"})
    for sid in vb_partner:
        parts.append({"eventId": "evt-vb-im", "studentId": sid, "kind": "lookingForPartner"})

    # Pickup soccer — newcomer matching
    soccer_interested = ["stu-john", "stu-taylor", "stu-jordan", "stu-casey", "stu-riley", "stu-chris"]
    soccer_newcomer = ["stu-sarah", "stu-mia", "stu-quinn"]
    for sid in soccer_interested:
        parts.append({"eventId": "evt-soccer-pickup", "studentId": sid, "kind": "interested"})
    for sid in soccer_newcomer:
        parts.append({"eventId": "evt-soccer-pickup", "studentId": sid, "kind": "lookingForPartner"})

    # CS 2114 study — same-section classmates (matchingKind none)
    cs2114_students = ["stu-alex", "stu-john", "stu-sarah", "stu-mia", "stu-chris",
                       "stu-taylor", "stu-riley"]
    for sid in cs2114_students:
        parts.append({"eventId": "evt-study-lib", "studentId": sid, "kind": "interested"})
    parts.append({"eventId": "evt-study-lib", "studentId": "stu-rachel", "kind": "interested"})

    return parts


def build_partner_profiles(students):
    """Profiles derived from real student records — one per lookingForPartner row."""
    by_id = {s["id"]: s for s in students}
    specs = [
        ("stu-john", "evt-vb-im", "Intermediate", "Need a setter for IM team"),
        ("stu-rachel", "evt-vb-im", "Played in high school", "Looking for a co-ed pair"),
        ("stu-mia", "evt-vb-im", "Beginner friendly", "New to IM — want a buddy"),
        ("stu-sarah", "evt-soccer-pickup", "Never played pickup at VT", "Out-of-state — don't know anyone who plays"),
        ("stu-mia", "evt-soccer-pickup", "Played intramural in high school", "First time at Drillfield pickup"),
        ("stu-quinn", "evt-soccer-pickup", "Casual player", "Don't know anyone on the field yet"),
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


def build_student_profiles(students):
    return [
        {"studentId": "stu-alex", "interestIds": ["int-volleyball", "int-study"], "onboardingComplete": True},
        {"studentId": "stu-john", "interestIds": ["int-soccer", "int-intramurals"], "onboardingComplete": True},
        {"studentId": "stu-rachel", "interestIds": ["int-volleyball", "int-study"], "onboardingComplete": True},
    ] + [
        {"studentId": s["id"], "interestIds": [], "onboardingComplete": False}
        for s in students if s["id"] not in ("stu-alex", "stu-john", "stu-rachel")
    ]


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


def main():
    output = Path(__file__).resolve().parents[1] / "Between" / "Resources" / "seed_data.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = generate_data()
    validate_seed(payload)
    output.write_text(json.dumps(payload, indent=2))
    vb_real = len({p["studentId"] for p in payload["eventParticipations"] if p["eventId"] == "evt-vb-im"})
    print(f"Wrote {output}")
    print(f"students={len(payload['students'])}, sections={len(payload['sections'])}, "
          f"event_participations={len(payload['eventParticipations'])}, vb_real={vb_real}")


if __name__ == "__main__":
    main()
