const { buildTodayPlan, serializeTodayPlan } = require('./scheduleEngine');

const AVATARS = ['🙂', '😎', '🤓', '🧠', '🏃', '☕', '📚', '🎧', '✨', '🌟', '🦉', '🔥'];
const WALKS = ['2 min walk', '5 min walk', '8 min walk', '12 min walk'];

function hash(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h << 5) - h + s.charCodeAt(i);
  return Math.abs(h);
}

function friendIds(studentId, friendships) {
  const ids = new Set();
  for (const f of friendships) {
    if (f.status !== 'accepted') continue;
    if (f.studentA === studentId) ids.add(f.studentB);
    if (f.studentB === studentId) ids.add(f.studentA);
  }
  return ids;
}

function friendSharesOverlap(friendId, viewerId, shareFreeTimeWithByStudentId) {
  if (!Object.prototype.hasOwnProperty.call(shareFreeTimeWithByStudentId, friendId)) {
    return true;
  }
  return shareFreeTimeWithByStudentId[friendId].includes(viewerId);
}

function buildDashboard(input) {
  const {
    me,
    students,
    sections,
    enrollments,
    friendships,
    friendRequests,
    presenceByStudentId,
    plans,
    syncTime,
    shareFreeTimeWithByStudentId = {},
    myShareFreeTimeWith = [],
  } = input;
  const fids = friendIds(me.id, friendships);
  const sectionById = Object.fromEntries(sections.map((s) => [s.sectionId, s]));

  const nearbyFriends = students
    .filter((s) => fids.has(s.id) && presenceByStudentId[s.id])
    .map((student) => {
      const p = presenceByStudentId[student.id];
      return {
        id: student.id,
        name: student.name,
        email: student.email,
        avatarEmoji: AVATARS[hash(student.id) % AVATARS.length],
        status: p.status,
        activity: p.activity,
        location: p.location,
        distanceLabel: WALKS[hash(student.id) % WALKS.length],
      };
    })
    .sort((a, b) => a.name.localeCompare(b.name));

  const mySectionIds = new Set(enrollments.filter((e) => e.studentId === me.id).map((e) => e.sectionId));
  const mySections = [...mySectionIds].map((id) => sectionById[id]).filter(Boolean);
  const myByCanonical = {};
  for (const s of mySections) {
    (myByCanonical[s.canonicalCourseId] ||= []).push(s);
  }

  const classConnections = nearbyFriends.flatMap((friend) => {
    const friendSectionIds = new Set(enrollments.filter((e) => e.studentId === friend.id).map((e) => e.sectionId));
    const overlaps = [...friendSectionIds]
      .map((id) => sectionById[id])
      .filter((s) => s && myByCanonical[s.canonicalCourseId]);
    if (!overlaps.length) return [];
    const matched = overlaps[0];
    const myMatch = myByCanonical[matched.canonicalCourseId]?.[0];
    const same = myMatch?.sectionId === matched.sectionId;
    return [
      {
        id: `${friend.id}-${matched.canonicalCourseId}`,
        courseCode: matched.courseCode,
        courseName: matched.courseName,
        friendName: friend.name,
        kind: same ? 'sameSection' : 'differentSection',
        sectionLabel: same
          ? `Section ${matched.sectionLabel}`
          : `Sec ${myMatch?.sectionLabel ?? '--'} vs ${matched.sectionLabel}`,
        meetingDays: matched.meetingDays,
      },
    ];
  });

  const incoming = friendRequests.filter((r) => r.toStudentId === me.id && r.status === 'pending');
  const outgoing = friendRequests.filter((r) => r.fromStudentId === me.id && r.status === 'pending');
  const pendingIncoming = incoming
    .map((r) => {
      const from = students.find((s) => s.id === r.fromStudentId);
      return from ? { requestId: r.id, from } : null;
    })
    .filter(Boolean);
  const pendingOutgoing = outgoing.map((r) => students.find((s) => s.id === r.toStudentId)).filter(Boolean);

  const blocked = new Set([...fids, me.id, ...pendingOutgoing.map((s) => s.id), ...pendingIncoming.map((r) => r.from.id)]);
  const suggestedStudents = students
    .filter((s) => !blocked.has(s.id))
    .sort((a, b) => {
      const ac = a.suggestedVia === 'contacts';
      const bc = b.suggestedVia === 'contacts';
      if (ac !== bc) return ac ? -1 : 1;
      return a.name.localeCompare(b.name);
    });

  const friendSectionsById = {};
  for (const fid of fids) {
    if (!friendSharesOverlap(fid, me.id, shareFreeTimeWithByStudentId)) continue;
    const ids = enrollments.filter((e) => e.studentId === fid).map((e) => e.sectionId);
    const secs = ids.map((id) => sectionById[id]).filter(Boolean);
    if (secs.length) friendSectionsById[fid] = secs;
  }
  const friendNamesById = Object.fromEntries(nearbyFriends.map((f) => [f.id, f.name]));
  const todayPlan = serializeTodayPlan(buildTodayPlan(mySections, friendSectionsById, friendNamesById));

  const visiblePlans = plans
    .filter((p) => p.creatorId === me.id || fids.has(p.creatorId))
    .sort((a, b) => new Date(a.startTime) - new Date(b.startTime));

  return {
    me,
    nearbyFriends,
    classConnections,
    mySections: mySections.sort((a, b) => a.courseCode.localeCompare(b.courseCode)),
    pendingIncoming,
    pendingOutgoing,
    suggestedStudents,
    plans: visiblePlans,
    todayPlan,
    syncTimestamp: syncTime,
    shareFreeTimeWith: myShareFreeTimeWith,
  };
}

module.exports = { buildDashboard, friendIds, friendSharesOverlap };
