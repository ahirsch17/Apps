const fs = require('fs');
const path = require('path');
const { buildDashboard } = require('./dashboardBuilder');
const { buildEvents } = require('./eventsBuilder');

const SEED_PATH = path.join(__dirname, '../../Between/Resources/seed_data.json');
const MODE_MAP = {
  quiet: { status: 'busy', label: 'Quiet time' },
  hungry: { status: 'freeNow', label: 'Hungry' },
  study: { status: 'studying', label: 'Study' },
  gym: { status: 'onTheWay', label: 'Gym' },
  sports: { status: 'onTheWay', label: 'Sports' },
  social: { status: 'freeNow', label: 'Social' },
};

const MODE_DURATION = {
  quiet: 7200,
  hungry: 3600,
  study: 7200,
  gym: 5400,
  sports: 5400,
  social: 3600,
};

class DataStore {
  constructor() {
    this.reload();
  }

  reload() {
    const raw = fs.readFileSync(SEED_PATH, 'utf8');
    const db = JSON.parse(raw);
    this.generatedAt = db.generatedAt;
    this.universities = db.universities;
    this.sections = db.sections;
    this.students = db.students;
    this.enrollments = db.enrollments;
    this.friendships = [...db.friendships];
    this.friendRequests = [...db.friendRequests];
    this.presenceByStudentId = Object.fromEntries(db.presence.map((p) => [p.studentId, { ...p }]));
    this.plans = [...db.plans];
    this.interests = db.interests || [];
    this.studentProfiles = (db.studentProfiles || []).map((p) => ({ ...p }));
    this.campusEvents = db.campusEvents || [];
    this.eventParticipations = [...(db.eventParticipations || [])];
    this.partnerProfiles = [...(db.partnerProfiles || [])];
    this.activeModeByStudentId = {};
    this.consentByStudentId = {};
  }

  findStudentByEmail(email) {
    return this.students.find((s) => s.email.toLowerCase() === email.toLowerCase());
  }

  findStudentById(id) {
    return this.students.find((s) => s.id === id);
  }

  loginCandidates() {
    return this.students.slice(0, 12);
  }

  login(email, password) {
    const me = this.findStudentByEmail(email);
    if (!me) return { error: 'userNotFound' };
    if (password && password !== 'demo123') return { error: 'badPassword' };
    return { userId: me.id, email: me.email };
  }

  activate(email, code) {
    if (code !== '482910') return { error: 'badCode' };
    const me = this.findStudentByEmail(email);
    if (!me) return { error: 'userNotFound' };
    return { userId: me.id, email: me.email };
  }

  ssoLogin(email) {
    const me = this.findStudentByEmail(email);
    if (!me) return { error: 'userNotFound' };
    return { userId: me.id, email: me.email };
  }

  recordConsent(studentId, accepted) {
    this.consentByStudentId[studentId] = { accepted, at: new Date().toISOString() };
  }

  hasConsent(studentId) {
    return this.consentByStudentId[studentId]?.accepted === true;
  }

  dashboard(studentId) {
    const me = this.findStudentById(studentId);
    if (!me) return null;
    return buildDashboard({
      me,
      students: this.students,
      sections: this.sections,
      enrollments: this.enrollments,
      friendships: this.friendships,
      friendRequests: this.friendRequests,
      presenceByStudentId: this.presenceByStudentId,
      plans: this.plans,
      syncTime: new Date().toISOString(),
    });
  }

  events(studentId) {
    return buildEvents(
      {
        campusEvents: this.campusEvents,
        interests: this.interests,
        eventParticipations: this.eventParticipations,
        partnerProfiles: this.partnerProfiles,
        studentProfiles: this.studentProfiles,
        activeModeByStudentId: this.activeModeByStudentId,
        students: this.students,
      },
      studentId
    );
  }

  searchSections(query) {
    const q = query.trim().toLowerCase();
    if (!q) return [];
    return this.sections
      .filter(
        (s) =>
          s.courseCode.toLowerCase().includes(q) ||
          s.courseName.toLowerCase().includes(q) ||
          s.sectionId.toLowerCase().includes(q)
      )
      .sort((a, b) => a.courseCode.localeCompare(b.courseCode));
  }

  sendFriendRequest(fromId, toId) {
    if (fromId === toId) return;
    const exists = this.friendships.some(
      (f) =>
        (f.studentA === fromId && f.studentB === toId) || (f.studentA === toId && f.studentB === fromId)
    );
    if (exists) return;
    const pending = this.friendRequests.some(
      (r) =>
        r.status === 'pending' &&
        ((r.fromStudentId === fromId && r.toStudentId === toId) ||
          (r.fromStudentId === toId && r.toStudentId === fromId))
    );
    if (pending) return;
    this.friendRequests.push({
      id: `req-${Date.now()}`,
      fromStudentId: fromId,
      toStudentId: toId,
      status: 'pending',
      createdAt: new Date().toISOString(),
    });
  }

  acceptFriendRequest(studentId, requestId) {
    const idx = this.friendRequests.findIndex(
      (r) => r.id === requestId && r.toStudentId === studentId && r.status === 'pending'
    );
    if (idx < 0) return false;
    const req = this.friendRequests[idx];
    this.friendRequests[idx].status = 'accepted';
    this.friendships.push({ studentA: req.fromStudentId, studentB: req.toStudentId, status: 'accepted' });
    return true;
  }

  setPresence(studentId, status, activity) {
    const p = this.presenceByStudentId[studentId];
    if (!p) return null;
    p.status = status;
    p.activity = activity;
    p.lastUpdated = new Date().toISOString();
    return p;
  }

  setActivityMode(studentId, mode) {
    const cfg = MODE_MAP[mode];
    if (!cfg) return null;
    const expiresAt = new Date(Date.now() + (MODE_DURATION[mode] || 3600) * 1000).toISOString();
    this.activeModeByStudentId[studentId] = { mode, expiresAt };
    return this.setPresence(studentId, cfg.status, cfg.label);
  }

  markEventInterested(studentId, eventId) {
    if (!this.campusEvents.some((e) => e.id === eventId)) return false;
    this.eventParticipations = this.eventParticipations.filter(
      (p) => !(p.eventId === eventId && p.studentId === studentId && p.kind === 'interested')
    );
    if (!this.eventParticipations.some((p) => p.eventId === eventId && p.studentId === studentId)) {
      this.eventParticipations.push({ eventId, studentId, kind: 'interested' });
    }
    return true;
  }

  markLookingForPartner(studentId, eventId, note, experience) {
    const me = this.findStudentById(studentId);
    if (!me || !this.campusEvents.some((e) => e.id === eventId)) return false;
    this.eventParticipations = this.eventParticipations.filter(
      (p) => !(p.eventId === eventId && p.studentId === studentId)
    );
    this.eventParticipations.push({ eventId, studentId, kind: 'lookingForPartner' });
    this.partnerProfiles = this.partnerProfiles.filter(
      (p) => !(p.eventId === eventId && p.studentId === studentId)
    );
    const firstName = me.name.split(' ')[0];
    this.partnerProfiles.push({
      studentId,
      eventId,
      displayName: firstName,
      year: me.year,
      experienceNote: experience,
      lookingNote: note,
      socialHandle: null,
    });
    return true;
  }

  updateInterests(studentId, interestIds) {
    const idx = this.studentProfiles.findIndex((p) => p.studentId === studentId);
    if (idx >= 0) {
      this.studentProfiles[idx].interestIds = interestIds;
      this.studentProfiles[idx].onboardingComplete = true;
    } else {
      this.studentProfiles.push({ studentId, interestIds, onboardingComplete: true });
    }
  }

  createPlan(studentId, type, title, location) {
    const plan = {
      id: `plan-${Date.now()}`,
      creatorId: studentId,
      type,
      title,
      location,
      startTime: new Date(Date.now() + 15 * 60000).toISOString(),
      visibility: 'friends',
    };
    this.plans.push(plan);
    return plan;
  }

  /** Match classmates by hashed course IDs — server never sees raw CRNs. */
  courseHashMatches(studentId, hashedCourseIds) {
    const me = this.findStudentById(studentId);
    if (!me) return [];
    const schoolId = me.schoolId;
    const sectionById = Object.fromEntries(this.sections.map((s) => [s.sectionId, s]));
    const crypto = require('crypto');

    const hashFor = (canonicalCourseId) =>
      crypto.createHash('sha256').update(`${schoolId}:${canonicalCourseId}`).digest('hex');

    const myHashes = new Set(hashedCourseIds);
    const counts = {};

    for (const enrollment of this.enrollments) {
      if (enrollment.studentId === studentId) continue;
      const peer = this.findStudentById(enrollment.studentId);
      if (!peer || peer.schoolId !== schoolId) continue;
      const section = sectionById[enrollment.sectionId];
      if (!section) continue;
      const h = hashFor(section.canonicalCourseId);
      if (!myHashes.has(h)) continue;
      counts[h] = (counts[h] || 0) + 1;
    }

    return Object.entries(counts).map(([hash, classmateCount]) => ({ hash, classmateCount }));
  }
}

module.exports = new DataStore();
