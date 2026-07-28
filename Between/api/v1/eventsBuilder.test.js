const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { buildEvents } = require('./eventsBuilder');

const SEED_PATH = path.join(__dirname, '../../Between/Resources/seed_data.json');

function loadState() {
  const db = JSON.parse(fs.readFileSync(SEED_PATH, 'utf8'));
  return {
    campusEvents: db.campusEvents,
    interests: db.interests,
    eventParticipations: db.eventParticipations,
    partnerProfiles: db.partnerProfiles,
    studentProfiles: db.studentProfiles,
    activeModeByStudentId: {},
    students: db.students,
  };
}

describe('eventsBuilder', () => {
  it('interestedCount equals unique real students only', () => {
    const state = loadState();
    const data = buildEvents(state, 'stu-alex');
    const vb = data.events.find((e) => e.id === 'evt-vb-im');
    const real = new Set(
      state.eventParticipations.filter((p) => p.eventId === 'evt-vb-im').map((p) => p.studentId)
    ).size;
    assert.equal(vb.interestedCount, real);
    assert.equal(vb.interestedCount, 11);
  });

  it('hides partner profiles until viewer opts in', () => {
    const state = loadState();
    const before = buildEvents(state, 'stu-alex');
    const vbBefore = before.events.find((e) => e.id === 'evt-vb-im');
    assert.equal(vbBefore.canViewPartners, false);
    assert.equal(vbBefore.partnerProfiles.length, 0);

    state.eventParticipations.push({
      eventId: 'evt-vb-im',
      studentId: 'stu-alex',
      kind: 'lookingForPartner',
    });
    const after = buildEvents(state, 'stu-alex');
    const vbAfter = after.events.find((e) => e.id === 'evt-vb-im');
    assert.equal(vbAfter.canViewPartners, true);
    assert.ok(vbAfter.partnerProfiles.length >= 3);
  });

  it('study event with matchingKind none has zero partner seekers', () => {
    const state = loadState();
    const data = buildEvents(state, 'stu-alex');
    const study = data.events.find((e) => e.id === 'evt-study-lib');
    assert.equal(study.matchingKind, 'none');
    assert.equal(study.partnerSeekingCount, 0);
  });
});
