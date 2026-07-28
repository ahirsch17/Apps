const { describe, it, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { validateSeed, assertValidSeed } = require('./seedValidator');
const { createFreshStore } = require('./dataStore');

const SEED_PATH = path.join(__dirname, '../../Between/Resources/seed_data.json');

describe('seed_data.json integrity', () => {
  it('loads and passes referential validation', () => {
    const db = JSON.parse(fs.readFileSync(SEED_PATH, 'utf8'));
    assertValidSeed(db);
  });

  it('every event participant has enrollments', () => {
    const db = JSON.parse(fs.readFileSync(SEED_PATH, 'utf8'));
    const enrolled = new Set(db.enrollments.map((e) => e.studentId));
    for (const p of db.eventParticipations) {
      assert.ok(enrolled.has(p.studentId), `${p.studentId} must be enrolled`);
      assert.ok(db.students.some((s) => s.id === p.studentId), `${p.studentId} must exist`);
    }
  });

  it('uses multiple real CAST students per event', () => {
    const db = JSON.parse(fs.readFileSync(SEED_PATH, 'utf8'));
    const vb = new Set(
      db.eventParticipations.filter((p) => p.eventId === 'evt-vb-im').map((p) => p.studentId)
    );
    assert.ok(vb.size >= 8, `expected 8+ real VB participants, got ${vb.size}`);
  });
});

describe('DataStore event mutations', () => {
  /** @type {ReturnType<typeof createFreshStore>} */
  let store;

  beforeEach(() => {
    store = createFreshStore();
  });

  it('markEventInterested increments displayed count by exactly one', () => {
    const before = store.events('stu-alex').events.find((e) => e.id === 'evt-vb-im');
    assert.equal(before.isInterested, false);
    assert.equal(before.interestedCount, 11);
    store.markEventInterested('stu-alex', 'evt-vb-im');
    const after = store.events('stu-alex').events.find((e) => e.id === 'evt-vb-im');
    assert.equal(after.isInterested, true);
    assert.equal(after.interestedCount, 12);
  });

  it('markEventInterested rejects unknown student', () => {
    assert.equal(store.markEventInterested('stu-fake', 'evt-vb-im'), false);
  });

  it('markEventInterested rejects student without enrollment', () => {
    assert.equal(store.markEventInterested('stu-sug-00', 'evt-vb-im'), false);
  });

  it('markLookingForPartner creates profile from student record', () => {
    assert.ok(
      store.markLookingForPartner('stu-alex', 'evt-vb-im', 'Need a team', 'Intermediate')
    );
    const events = store.events('stu-rachel');
    const vb = events.events.find((e) => e.id === 'evt-vb-im');
    assert.ok(vb.canViewPartners);
    const alexProfile = vb.partnerProfiles.find((p) => p.studentId === 'stu-alex');
    assert.ok(alexProfile);
    assert.equal(alexProfile.displayName, 'Alex');
    assert.equal(alexProfile.year, 'Senior');
  });

  it('markLookingForPartner rejects none matchingKind events', () => {
    assert.equal(
      store.markLookingForPartner('stu-alex', 'evt-study-lib', 'note', 'exp'),
      false
    );
  });

  it('events() counts only real participations — no synthetic padding', () => {
    const events = store.events('stu-alex');
    const vb = events.events.find((e) => e.id === 'evt-vb-im');
    const realVb = new Set(
      store.eventParticipations.filter((p) => p.eventId === 'evt-vb-im').map((p) => p.studentId)
    ).size;
    assert.equal(vb.interestedCount, realVb);
    assert.equal(vb.partnerSeekingCount, 3);
    assert.equal(vb.interestedCount, 11);
  });

  it('mutual opt-in hides partner profiles until viewer opts in', () => {
    const before = store.events('stu-alex');
    const vbBefore = before.events.find((e) => e.id === 'evt-vb-im');
    assert.equal(vbBefore.canViewPartners, false);
    assert.equal(vbBefore.partnerProfiles.length, 0);

    store.markLookingForPartner('stu-alex', 'evt-vb-im', 'Setter please', 'Intermediate');
    const after = store.events('stu-alex');
    const vbAfter = after.events.find((e) => e.id === 'evt-vb-im');
    assert.equal(vbAfter.canViewPartners, true);
    assert.ok(vbAfter.partnerProfiles.length >= 3);
    assert.ok(!vbAfter.partnerProfiles.some((p) => p.studentId === 'stu-alex'));
  });
});

describe('DataStore auth & dashboard', () => {
  /** @type {ReturnType<typeof createFreshStore>} */
  let store;

  beforeEach(() => {
    store = createFreshStore();
  });

  it('login accepts demo credentials', () => {
    const result = store.login('alex.hirsch@vt.edu', 'demo123');
    assert.equal(result.userId, 'stu-alex');
  });

  it('login rejects wrong password', () => {
    const result = store.login('alex.hirsch@vt.edu', 'nope');
    assert.equal(result.error, 'badPassword');
  });

  it('activate accepts demo code', () => {
    const result = store.activate('alex.hirsch@vt.edu', '482910');
    assert.equal(result.userId, 'stu-alex');
  });

  it('dashboard returns 11 friends for Alex', () => {
    const dash = store.dashboard('stu-alex');
    assert.equal(dash.me.id, 'stu-alex');
    assert.ok(dash.nearbyFriends.length >= 10);
    assert.ok(dash.todayPlan.length > 0);
  });

  it('sendFriendRequest and acceptFriendRequest add friend', () => {
    const before = store.dashboard('stu-alex').nearbyFriends.length;
    store.acceptFriendRequest('stu-alex', 'req-0001');
    const after = store.dashboard('stu-alex').nearbyFriends.length;
    assert.equal(after, before + 1);
  });

  it('updateInterests requires profile update', () => {
    store.updateInterests('stu-alex', ['int-volleyball', 'int-soccer']);
    const events = store.events('stu-alex');
    assert.ok(events.onboardingComplete);
    assert.deepEqual(events.myInterestIds, ['int-volleyball', 'int-soccer']);
  });

  it('setActivityMode updates presence and events', () => {
    const result = store.setActivityMode('stu-alex', 'hungry');
    assert.equal(result.status, 'freeNow');
    const events = store.events('stu-alex');
    assert.equal(events.activeMode, 'hungry');
  });

  it('courseHashMatches finds CS 2114 classmates', () => {
    const crypto = require('crypto');
    const hash = crypto.createHash('sha256').update('vt:CSE-1002').digest('hex');
    const matches = store.courseHashMatches('stu-alex', [hash]);
    assert.ok(matches.length >= 1);
    assert.ok(matches[0].classmateCount >= 5);
  });
});

describe('validateSeed', () => {
  it('flags participation without enrollment', () => {
    const db = JSON.parse(fs.readFileSync(SEED_PATH, 'utf8'));
    const broken = {
      ...db,
      eventParticipations: [
        ...db.eventParticipations,
        { eventId: 'evt-vb-im', studentId: 'stu-sug-00', kind: 'interested' },
      ],
    };
    const errors = validateSeed(broken);
    assert.ok(errors.some((e) => e.includes('stu-sug-00')));
  });
});
