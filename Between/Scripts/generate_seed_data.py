#!/usr/bin/env python3
import json
import random
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

random.seed(42)

DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
WEEKEND_DAYS = ["Sat", "Sun"]
STATUSES = ["freeNow", "onTheWay", "studying", "busy"]
LOCATIONS = [
    "Newman Library",
    "McBryde Hall",
    "Squires",
    "War Memorial Gym",
    "Turner Place",
    "The Drillfield",
    "Burruss Hall",
    "Goodwin Hall"
]
FIRST_NAMES = [
    "Alex", "Sarah", "Mia", "Chris", "Jake", "Taylor", "Jordan", "Morgan", "Drew", "Parker",
    "Casey", "Riley", "Avery", "Quinn", "Logan", "Hayden", "Skyler", "Rowan", "Reese", "Emerson"
]
LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Wilson", "Moore", "Taylor"
]


def random_time(start_hour: int, end_hour: int):
    hour = random.randint(start_hour, end_hour)
    minute = random.choice([0, 15, 30, 45])
    return f"{hour:02d}:{minute:02d}"


def plus_minutes(time_str: str, minutes: int):
    hour, minute = map(int, time_str.split(":"))
    total = hour * 60 + minute + minutes
    return f"{(total // 60) % 24:02d}:{total % 60:02d}"


def make_sections(canonical_id: str, course_code: str, course_name: str, include_weekend=False):
    section_count = random.choice([2, 3])
    sections = []
    for idx in range(section_count):
        section_id = f"{canonical_id}-SEC-{idx + 1:03d}"
        if include_weekend and idx == 0:
            meeting_days = [random.choice(WEEKEND_DAYS)]
            start = random_time(9, 15)
        else:
            day_count = random.choice([2, 3])
            meeting_days = random.sample(DAYS[:5], day_count)
            start = random_time(8, 17)
        end = plus_minutes(start, random.choice([50, 75, 90]))
        sections.append({
            "sectionId": section_id,
            "canonicalCourseId": canonical_id,
            "courseCode": course_code,
            "courseName": course_name,
            "sectionLabel": f"{idx + 1:03d}",
            "meetingDays": sorted(meeting_days, key=lambda day: DAYS.index(day)),
            "startTime": start,
            "endTime": end,
            "location": random.choice(LOCATIONS)
        })
    return sections


def generate_data():
    university = {
        "id": "vt",
        "name": "Virginia Tech",
        "emailDomain": "vt.edu",
        "timezone": "America/New_York"
    }

    courses = [
        ("CSE-1001", "CS 1114", "Intro to Software Design"),
        ("CSE-1002", "CS 2114", "Software Design and Data Structures"),
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
        ("CSE-1020", "MUS 1104", "Music Appreciation")
    ]

    sections = []
    for idx, (canonical_id, code, name) in enumerate(courses):
        include_weekend = idx < 6  # ensure enough weekend classes for testing
        sections.extend(make_sections(canonical_id, code, name, include_weekend=include_weekend))

    students = []
    for i in range(70):
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        handle = f"{first.lower()}.{last.lower()}{i}"
        students.append({
            "id": f"stu-{i + 1:04d}",
            "name": f"{first} {last}",
            "email": f"{handle}@vt.edu",
            "schoolId": "vt",
            "year": random.choice(["Freshman", "Sophomore", "Junior", "Senior"]),
            "major": random.choice(["CS", "BIT", "CMDA", "MATH", "ECON"]),
            "privacy": {
                "shareSchedule": random.choice(["freeBusy", "full"]),
                "shareClassDetails": random.choice([True, False])
            }
        })

    # predictable login users
    students[0]["name"] = "Alex Hirsch"
    students[0]["email"] = "alex.hirsch@vt.edu"
    students[1]["name"] = "Sarah Kim"
    students[1]["email"] = "sarah.kim@vt.edu"

    enrollments = []
    for student in students:
        picks = random.sample(sections, random.randint(4, 6))
        for section in picks:
            enrollments.append({
                "studentId": student["id"],
                "sectionId": section["sectionId"]
            })

    # ensure Alex has weekend classes
    alex_id = students[0]["id"]
    weekend_sections = [s for s in sections if any(day in WEEKEND_DAYS for day in s["meetingDays"])]
    for section in random.sample(weekend_sections, 2):
        enrollments.append({"studentId": alex_id, "sectionId": section["sectionId"]})

    now = datetime.now(timezone.utc)
    presence = []
    for student in students:
        status = random.choice(STATUSES)
        presence.append({
            "studentId": student["id"],
            "status": status,
            "activity": random.choice(["Grabbing coffee", "Study sprint", "Headed to class", "Gym run", "Free to hang"]),
            "location": random.choice(LOCATIONS),
            "lastUpdated": (now - timedelta(minutes=random.randint(0, 20))).isoformat()
        })

    friendships = []
    friend_requests = []
    all_ids = [s["id"] for s in students]
    for source in all_ids[:35]:
        for target in random.sample(all_ids, random.randint(3, 8)):
            if source == target:
                continue
            pair = tuple(sorted([source, target]))
            if pair in friendships:
                continue
            if random.random() < 0.7:
                friendships.append(pair)
            else:
                friend_requests.append({
                    "id": f"req-{len(friend_requests)+1:04d}",
                    "fromStudentId": source,
                    "toStudentId": target,
                    "status": "pending",
                    "createdAt": (now - timedelta(days=random.randint(0, 8))).isoformat()
                })

    friendship_records = [
        {"studentA": a, "studentB": b, "status": "accepted"}
        for a, b in friendships
    ]

    plans = []
    for i in range(40):
        creator = random.choice(all_ids)
        start = now + timedelta(minutes=random.randint(-120, 240))
        plans.append({
            "id": f"plan-{i + 1:04d}",
            "creatorId": creator,
            "type": random.choice(["Food", "Gym", "Study", "Hangout"]),
            "title": random.choice(["Lunch run", "Study before class", "Quick lift", "Coffee break"]),
            "location": random.choice(LOCATIONS),
            "startTime": start.isoformat(),
            "visibility": "friends"
        })

    return {
        "generatedAt": now.isoformat(),
        "universities": [university],
        "sections": sections,
        "students": students,
        "enrollments": enrollments,
        "friendships": friendship_records,
        "friendRequests": friend_requests,
        "presence": presence,
        "plans": plans
    }


def main():
    output_path = Path(__file__).resolve().parents[1] / "Between" / "Resources" / "seed_data.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    payload = generate_data()
    output_path.write_text(json.dumps(payload, indent=2))
    print(f"Wrote seed data to {output_path}")
    print(f"students={len(payload['students'])}, sections={len(payload['sections'])}, enrollments={len(payload['enrollments'])}")


if __name__ == "__main__":
    main()
