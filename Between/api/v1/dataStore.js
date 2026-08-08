const fs = require('fs');
const path = require('path');
const { buildDashboard } = require('./dashboardBuilder');
const { buildEvents } = require('./eventsBuilder');
const { assertValidSeed } = require('./seedValidator');

const SEED_PATH = path.join(__dirname, '../../Between/Resources/seed_data.json');
const SIMULATED_CONTACTS_PATH = path.join(__dirname, '../../Between/Resources/simulated_device_contacts.json');
const { matchedStudentIds } = require('./contactMatcher');
const { loadDemoConfig } = require('./localDemoConfig');
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
    assertValidSeed(db);
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
    this.shareFreeTimeWithByStudentId = {};
    this.simulatedDeviceContacts = JSON.parse(fs.readFileSync(SIMULATED_CONTACTS_PATH, 'utf8'));
    this.demoConfig = loadDemoConfig();
  }

  findStudentByEmail(email) {
    return this.students.find((s) => s.email.toLowerCase() === email.toLowerCase());
  }

  findStudentById(id) {
    return this.students.find((s) => s.id === id);
  }

  studentHasEnrollment(studentId) {
    return this.enrollments.some((e) => e.studentId === studentId);
  }

  findEventById(eventId) {
    return this.campusEvents.find((e) => e.id === eventId);
  }

  loginCandidates() {
    const limit = this.demoConfig.loginCandidateLimit ?? 12;
    return this.students.slice(0, limit);
  }

  login(email, password) {
    const me = this.findStudentByEmail(email);
    if (!me) return { error: 'userNotFound' };
    if (password && password !== this.demoConfig.demoPassword) return { error: 'badPassword' };
    return { userId: me.id, email: me.email };
  }

  activate(email, code) {
    if (code !== this.demoConfig.activationCode) return { error: 'badCode' };
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
    const fids = require('./dashboardBuilder').friendIds(studentId, this.friendships);
    const deviceContacts =
      this.simulatedDeviceContacts.ownerStudentId === studentId
        ? this.simulatedDeviceContacts.contacts
        : [];
    const contactMatchedStudentIds = matchedStudentIds(this.students, deviceContacts);
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
      shareFreeTimeWithByStudentId: this.shareFreeTimeWithByStudentId,
      myShareFreeTimeWith: this.getShareFreeTimeWith(studentId, fids),
      contactMatchedStudentIds,
      walkDistanceLabels: this.demoConfig.walkDistanceLabels || ['Nearby'],
    });
  }

  getShareFreeTimeWith(studentId, friendIds) {
    if (Object.prototype.hasOwnProperty.call(this.shareFreeTimeWithByStudentId, studentId)) {
      return this.shareFreeTimeWithByStudentId[studentId];
    }
    return [...friendIds];
  }

  setShareFreeTime(studentId, friendId, allowed) {
    const fids = require('./dashboardBuilder').friendIds(studentId, this.friendships);
    const current = new Set(this.getShareFreeTimeWith(studentId, fids));
    if (allowed) current.add(friendId);
    else current.delete(friendId);
    this.shareFreeTimeWithByStudentId[studentId] = [...current];
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
    if (!this.findStudentById(studentId) || !this.studentHasEnrollment(studentId)) return false;
    if (!this.findEventById(eventId)) return false;
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
    const event = this.findEventById(eventId);
    if (!me || !event || !this.studentHasEnrollment(studentId)) return false;
    if (event.matchingKind === 'none') return false;
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
    const { friendIds } = require('./dashboardBuilder');

    const hashFor = (canonicalCourseId) =>
      crypto.createHash('sha256').update(`${schoolId}:${canonicalCourseId}`).digest('hex');

    const fids = friendIds(studentId, this.friendships);
    const mySectionIds = new Set(this.enrollments.filter((e) => e.studentId === studentId).map((e) => e.sectionId));
    const mySections = [...mySectionIds].map((id) => sectionById[id]).filter(Boolean);
    const myByCanonical = {};
    for (const s of mySections) {
      (myByCanonical[s.canonicalCourseId] ||= []).push(s);
    }

    const hashSet = new Set(hashedCourseIds);
    const results = [];

    for (const section of mySections) {
      const hash = hashFor(section.canonicalCourseId);
      if (!hashSet.has(hash)) continue;

      let classmateCount = 0;
      const friendConnections = [];
      const seenFriends = new Set();

      for (const enrollment of this.enrollments) {
        if (enrollment.studentId === studentId) continue;
        const peerSection = sectionById[enrollment.sectionId];
        if (!peerSection || peerSection.canonicalCourseId !== section.canonicalCourseId) continue;
        const peer = this.findStudentById(enrollment.studentId);
        if (!peer || peer.schoolId !== schoolId) continue;

        classmateCount += 1;

        if (!fids.has(enrollment.studentId) || seenFriends.has(enrollment.studentId)) continue;
        seenFriends.add(enrollment.studentId);

        const myMatch = myByCanonical[section.canonicalCourseId]?.[0];
        const same = myMatch?.sectionId === peerSection.sectionId;
        friendConnections.push({
          id: `${enrollment.studentId}-${section.canonicalCourseId}`,
          courseCode: peerSection.courseCode,
          courseName: peerSection.courseName,
          friendName: peer.name,
          kind: same ? 'sameSection' : 'differentSection',
          sectionLabel: same
            ? `Section ${peerSection.sectionLabel}`
            : `Sec ${myMatch?.sectionLabel ?? '--'} vs ${peerSection.sectionLabel}`,
          meetingDays: peerSection.meetingDays,
        });
      }

      if (classmateCount > 0) {
        results.push({ hash, classmateCount, friendConnections });
      }
    }

    return results;
  }
}

module.exports = new DataStore();
module.exports.DataStore = DataStore;
module.exports.createFreshStore = () => new DataStore();
