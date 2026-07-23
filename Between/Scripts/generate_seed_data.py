#!/usr/bin/env python3
"""Generate demo seed data for Between (25 students, ~50 sections, curated overlaps)."""

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

# --- Curated cast (demo story) ---
CAST = [
    {
        "id": "stu-alex",
        "name": "Alex Hirsch",
        "email": "alex.hirsch@vt.edu",
        "year": "Senior",
        "major": "CS",
        "phone": "+15405551234",
        "suggestedVia": None,
    },
    {
        "id": "stu-john",
        "name": "John Martinez",
        "email": "john.martinez@vt.edu",
        "year": "Senior",
        "major": "CS",
        "phone": "+15405559876",
        "suggestedVia": "contacts",
    },
    {
        "id": "stu-rachel",
        "name": "Rachel Chen",
        "email": "rachel.chen@vt.edu",
        "year": "Junior",
        "major": "CS",
        "phone": "+15405552468",
        "suggestedVia": "contacts",
    },
    {
        "id": "stu-sarah",
        "name": "Sarah Kim",
        "email": "sarah.kim@vt.edu",
        "year": "Sophomore",
        "major": "BIT",
        "phone": None,
        "suggestedVia": None,
    },
    {
        "id": "stu-mia",
        "name": "Mia Johnson",
        "email": "mia.johnson@vt.edu",
        "year": "Junior",
        "major": "CMDA",
        "phone": "+15405553001",
        "suggestedVia": "contacts",
    },
]

EXTRA_NAMES = [
    ("Chris", "Brown", "CS"),
    ("Taylor", "Davis", "BIT"),
    ("Jordan", "Wilson", "MATH"),
    ("Morgan", "Moore", "ECON"),
    ("Casey", "Taylor", "CS"),
    ("Riley", "Anderson", "CMDA"),
    ("Avery", "Thomas", "CS"),
    ("Quinn", "Jackson", "BIT"),
    ("Logan", "White", "MATH"),
    ("Hayden", "Harris", "CS"),
    ("Skyler", "Martin", "ECON"),
    ("Rowan", "Thompson", "CS"),
    ("Reese", "Garcia", "BIT"),
    ("Emerson", "Clark", "CMDA"),
    ("Parker", "Lewis", "CS"),
    ("Drew", "Walker", "MATH"),
    ("Jamie", "Hall", "CS"),
    ("Blake", "Allen", "BIT"),
    ("Sydney", "Young", "ECON"),
    ("Cameron", "King", "CS"),
]

LOCATIONS = [
    "Newman Library",
    "McBryde Hall",
    "Squires",
    "War Memorial Gym",
    "Turner Place",
    "Drillfield",
    "Burruss Hall",
    "Goodwin Hall",
]


def section(section_id, canonical, code, name, label, days, start, end, location):
    return {
        "sectionId": section_id,
        "canonicalCourseId": canonical,
        "courseCode": code,
        "courseName": name,
        "sectionLabel": label,
        "meetingDays": days,
        "startTime": start,
        "endTime": end,
        "location": location,
    }


def build_sections():
    """~50 sections across 20 courses (2-3 sections each)."""
    courses = [
        ("CSE-1001", "CS 1114", "Intro to Software Design"),
        ("CSE-1002", "CS 2114", "Software Design & Data Structures"),
        ("CSE-1003", "CS 2505", "Computer Organization I"),
        ("CSE-1004", "CS 3214", "Computer Systems"),
        ("CSE-1005", "MATH 1226", "Calculus of a Single Variable"),
        ("CSE-1006", "MATH 2204", "Linear Algebra"),
        ("CSE-1007", "MATH 3134", "Applied Combinatorics"),
        ("CSE-1008", "STAT 3005", "Statistics for Engineers"),
        ("CSE-1009", "ECON 2005", "Microeconomic Principles"),
        ("CSE-1010", "ECON 2006", "Macroeconomic Principles"),
        ("CSE-1011", "PHYS 2305", "Foundations of Physics I"),
        ("CSE-1012", "PHYS 2306", "Foundations of Physics II"),
        ("CSE-1013", "ENGE 1215", "Foundations of Engineering"),
        ("CSE-1014", "BIT 2405", "Intro to Business Analytics"),
        ("CSE-1015", "CMDA 2005", "Data and Decisions"),
        ("CSE-1016", "PSCI 1014", "US Government"),
        ("CSE-1017", "ENGL 1106", "Writing and Research"),
        ("CSE-1018", "HIST 1214", "World History"),
        ("CSE-1019", "COMM 2004", "Public Speaking"),
        ("CSE-1020", "MUS 1104", "Music Appreciation"),
    ]

    sections = []

    # Curated anchors — same/different section + Wed overlap for Alex/John/Rachel
    sections.extend([
        # Same section: Alex + John, Wed 9:00
        section("CS2114-001", "CSE-1002", "CS 2114", "Software Design & Data Structures", "001",
                ["Mon", "Wed", "Fri"], "09:00", "09:50", "McBryde Hall"),
        section("CS2114-002", "CSE-1002", "CS 2114", "Software Design & Data Structures", "002",
                ["Tue", "Thu"], "11:00", "11:50", "Goodwin Hall"),
        # Different section same course: Alex 001 vs John 002 on CS 3214
        section("CS3214-001", "CSE-1004", "CS 3214", "Computer Systems", "001",
                ["Mon", "Wed"], "14:00", "15:15", "Burruss Hall"),
        section("CS3214-002", "CSE-1004", "CS 3214", "Computer Systems", "002",
                ["Mon", "Wed"], "14:00", "15:15", "Burruss Hall"),
        # Alex Wed: MATH block before lunch free window
        section("MATH2204-001", "CSE-1006", "MATH 2204", "Linear Algebra", "001",
                ["Mon", "Wed", "Fri"], "11:00", "11:50", "Derring Hall"),
        # John Wed: ECON during Alex math, then long free block
        section("ECON2005-001", "CSE-1009", "ECON 2005", "Microeconomic Principles", "001",
                ["Wed", "Fri"], "11:00", "11:50", "Pamplin Hall"),
        # Rachel: partial overlap with Alex lunch free (12:30-14:00)
        section("STAT3005-001", "CSE-1008", "STAT 3005", "Statistics for Engineers", "001",
                ["Tue", "Thu"], "09:30", "10:45", "Hutcheson Hall"),
        section("CMDA2005-001", "CSE-1015", "CMDA 2005", "Data and Decisions", "001",
                ["Wed"], "10:00", "10:50", "Newman Library"),
    ])

    templates = [
        (["Mon", "Wed"], "10:00", "10:50"),
        (["Tue", "Thu"], "13:00", "13:50"),
        (["Mon", "Wed", "Fri"], "15:30", "16:20"),
        (["Tue"], "14:00", "15:15"),
        (["Thu"], "09:00", "09:50"),
    ]

    for idx, (canonical, code, name) in enumerate(courses):
        if canonical in {"CSE-1002", "CSE-1004", "CSE-1006", "CSE-1008", "CSE-1009", "CSE-1015"}:
            continue
        for sec_idx in range(2):
            tpl = templates[(idx + sec_idx) % len(templates)]
            sections.append(
                section(
                    f"{canonical}-SEC-{sec_idx + 1:03d}",
                    canonical,
                    code,
                    name,
                    f"{sec_idx + 1:03d}",
                    tpl[0],
                    tpl[1],
                    tpl[2],
                    LOCATIONS[(idx + sec_idx) % len(LOCATIONS)],
                )
            )

    return sections


def build_students():
    students = []
    for person in CAST:
        students.append({
            "id": person["id"],
            "name": person["name"],
            "email": person["email"],
            "schoolId": "vt",
            "year": person["year"],
            "major": person["major"],
            "privacy": {"shareSchedule": "full", "shareClassDetails": True},
            "phoneNumber": person["phone"],
            "suggestedVia": person["suggestedVia"],
        })

    for i, (first, last, major) in enumerate(EXTRA_NAMES):
        handle = f"{first.lower()}.{last.lower()}"
        students.append({
            "id": f"stu-{i + 100:03d}",
            "name": f"{first} {last}",
            "email": f"{handle}@vt.edu",
            "schoolId": "vt",
            "year": ["Freshman", "Sophomore", "Junior", "Senior"][i % 4],
            "major": major,
            "privacy": {
                "shareSchedule": "freeBusy" if i % 3 == 0 else "full",
                "shareClassDetails": i % 2 == 0,
            },
            "phoneNumber": None,
            "suggestedVia": None,
        })
    return students


def build_enrollments(sections, students):
    enrollments = []
    section_ids = [s["sectionId"] for s in sections]
    by_id = {s["sectionId"]: s for s in sections}

    curated = {
        "stu-alex": ["CS2114-001", "MATH2204-001", "CS3214-001", "STAT3005-001", "CSE-1017-SEC-001"],
        "stu-john": ["CS2114-001", "ECON2005-001", "CS3214-002", "CSE-1001-SEC-001", "CSE-1013-SEC-001"],
        "stu-rachel": ["CS3214-002", "CMDA2005-001", "CSE-1006-SEC-001", "CSE-1014-SEC-001", "CSE-1019-SEC-001"],
        "stu-sarah": ["CS2114-001", "CSE-1005-SEC-001", "CSE-1010-SEC-001", "CSE-1016-SEC-001"],
        "stu-mia": ["CSE-1015-SEC-001", "CSE-1008-SEC-001", "CSE-1003-SEC-001", "CSE-1018-SEC-001"],
    }

    import random
    random.seed(42)

    for student in students:
        sid = student["id"]
        if sid in curated:
            picks = curated[sid]
        else:
            picks = [s["sectionId"] for s in random.sample(sections, random.randint(4, 5))]
        for sec in picks:
            if sec in by_id:
                enrollments.append({"studentId": sid, "sectionId": sec})

    return enrollments


def build_friendships(students):
    friendships = [
        ("stu-alex", "stu-john"),
        ("stu-alex", "stu-rachel"),
        ("stu-alex", "stu-sarah"),
        ("stu-john", "stu-rachel"),
        ("stu-alex", "stu-mia"),
        ("stu-john", "stu-100"),
        ("stu-rachel", "stu-101"),
    ]
    return [
        {"studentA": a, "studentB": b, "status": "accepted"}
        for a, b in friendships
    ]


def build_friend_requests(students):
    now = datetime.now(timezone.utc)
    return [
        {
            "id": "req-0001",
            "fromStudentId": "stu-102",
            "toStudentId": "stu-alex",
            "status": "pending",
            "createdAt": (now - timedelta(days=1)).isoformat(),
        },
        {
            "id": "req-0002",
            "fromStudentId": "stu-103",
            "toStudentId": "stu-alex",
            "status": "pending",
            "createdAt": (now - timedelta(days=2)).isoformat(),
        },
    ]


def build_presence(students):
    now = datetime.now(timezone.utc)
    statuses = ["freeNow", "onTheWay", "studying", "busy"]
    activities = ["Free", "Coffee", "Study sprint", "Headed to class", "Gym"]
    records = []
    for i, student in enumerate(students):
        status = "freeNow" if student["id"] in {"stu-john", "stu-rachel"} else statuses[i % len(statuses)]
        records.append({
            "studentId": student["id"],
            "status": status,
            "activity": activities[i % len(activities)],
            "location": LOCATIONS[i % len(LOCATIONS)],
            "lastUpdated": (now - timedelta(minutes=i % 20)).isoformat(),
        })
    return records


def build_plans(students):
    now = datetime.now(timezone.utc)
    return [
        {
            "id": "plan-0001",
            "creatorId": "stu-john",
            "type": "Food",
            "title": "Turner lunch",
            "location": "Turner Place",
            "startTime": (now + timedelta(minutes=45)).isoformat(),
            "visibility": "friends",
        },
        {
            "id": "plan-0002",
            "creatorId": "stu-rachel",
            "type": "Study",
            "title": "Library sprint",
            "location": "Newman Library",
            "startTime": (now + timedelta(minutes=120)).isoformat(),
            "visibility": "friends",
        },
    ]


def generate_data():
    sections = build_sections()
    students = build_students()
    now = datetime.now(timezone.utc)
    return {
        "generatedAt": now.isoformat(),
        "universities": [{
            "id": "vt",
            "name": "Virginia Tech",
            "emailDomain": "vt.edu",
            "timezone": "America/New_York",
        }],
        "sections": sections,
        "students": students,
        "enrollments": build_enrollments(sections, students),
        "friendships": build_friendships(students),
        "friendRequests": build_friend_requests(students),
        "presence": build_presence(students),
        "plans": build_plans(students),
    }


def main():
    output_path = Path(__file__).resolve().parents[1] / "Between" / "Resources" / "seed_data.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    payload = generate_data()
    output_path.write_text(json.dumps(payload, indent=2))
    print(f"Wrote {output_path}")
    print(
        f"students={len(payload['students'])}, "
        f"sections={len(payload['sections'])}, "
        f"enrollments={len(payload['enrollments'])}"
    )


if __name__ == "__main__":
    main()
