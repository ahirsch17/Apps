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
    }


def main():
    output = Path(__file__).resolve().parents[1] / "Between" / "Resources" / "seed_data.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = generate_data()
    output.write_text(json.dumps(payload, indent=2))
    alex_friends = sum(1 for f in payload["friendships"] if "stu-alex" in (f["studentA"], f["studentB"]))
    print(f"Wrote {output}")
    print(f"students={len(payload['students'])}, sections={len(payload['sections'])}, alex_friendships={alex_friends}")


if __name__ == "__main__":
    main()
