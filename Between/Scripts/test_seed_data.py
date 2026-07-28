#!/usr/bin/env python3
"""Unit tests for seed data integrity and generator output."""

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_seed_data import generate_data, validate_seed  # noqa: E402

SEED = Path(__file__).resolve().parents[1] / "Between" / "Resources" / "seed_data.json"


class SeedDataTests(unittest.TestCase):
    def test_committed_seed_validates(self):
        payload = json.loads(SEED.read_text(encoding="utf-8"))
        validate_seed(payload)

    def test_generator_output_validates(self):
        validate_seed(generate_data())

    def test_event_counts_are_real_students_only(self):
        payload = json.loads(SEED.read_text(encoding="utf-8"))
        enrolled = {e["studentId"] for e in payload["enrollments"]}
        student_ids = {s["id"] for s in payload["students"]}

        for p in payload["eventParticipations"]:
            self.assertIn(p["studentId"], student_ids)
            self.assertIn(p["studentId"], enrolled)

        for ev in payload["campusEvents"]:
            real = {p["studentId"] for p in payload["eventParticipations"] if p["eventId"] == ev["id"]}
            self.assertGreater(len(real), 0, ev["id"])

    def test_vb_has_eleven_real_participants(self):
        payload = json.loads(SEED.read_text(encoding="utf-8"))
        vb = {p["studentId"] for p in payload["eventParticipations"] if p["eventId"] == "evt-vb-im"}
        self.assertEqual(len(vb), 11)

    def test_partner_profiles_match_participations(self):
        payload = json.loads(SEED.read_text(encoding="utf-8"))
        seeking = {
            (p["eventId"], p["studentId"])
            for p in payload["eventParticipations"]
            if p["kind"] == "lookingForPartner"
        }
        for pp in payload["partnerProfiles"]:
            self.assertIn((pp["eventId"], pp["studentId"]), seeking)

    def test_alex_has_enrollments(self):
        payload = json.loads(SEED.read_text(encoding="utf-8"))
        alex_sections = [e for e in payload["enrollments"] if e["studentId"] == "stu-alex"]
        self.assertGreaterEqual(len(alex_sections), 3)


if __name__ == "__main__":
    unittest.main(verbosity=2)
