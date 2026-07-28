#!/usr/bin/env python3
"""Validate seed_data.json — run after generate_seed_data.py or in CI."""

import json
import sys
from pathlib import Path

# Reuse validation from generator
sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_seed_data import validate_seed  # noqa: E402

SEED = Path(__file__).resolve().parents[1] / "Between" / "Resources" / "seed_data.json"


def main():
    payload = json.loads(SEED.read_text(encoding="utf-8"))
    validate_seed(payload)
    parts = payload["eventParticipations"]
    enrolled = {e["studentId"] for e in payload["enrollments"]}
    for p in parts:
        assert p["studentId"] in enrolled, p["studentId"]
    print(f"OK: {len(parts)} event participations, all enrolled students")
    for eid in ("evt-vb-im", "evt-soccer-pickup", "evt-study-lib"):
        n = len({p["studentId"] for p in parts if p["eventId"] == eid})
        print(f"  {eid}: {n} real students")


if __name__ == "__main__":
    main()
