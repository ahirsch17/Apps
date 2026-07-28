const { formatRange } = require('./scheduleEngine');

function buildEvents(state, viewerId) {
  const profile = state.studentProfiles.find((p) => p.studentId === viewerId);
  const modeEntry = state.activeModeByStudentId[viewerId];
  const student = state.students.find((s) => s.id === viewerId);
  const schoolId = student?.schoolId || 'vt';

  const events = state.campusEvents.filter((e) => e.schoolId === schoolId);
  const interests = state.interests.filter((i) => i.schoolId === schoolId);
  const myInterestIds = profile?.interestIds || [];

  const viewerPartnerEvents = new Set(
    state.eventParticipations
      .filter((p) => p.studentId === viewerId && p.kind === 'lookingForPartner')
      .map((p) => p.eventId)
  );

  const cards = events.map((event) => {
    const parts = state.eventParticipations.filter((p) => p.eventId === event.id);
    const realInterested = new Set(parts.map((p) => p.studentId)).size;
    const realPartners = parts.filter((p) => p.kind === 'lookingForPartner').length;
    const interestedCount = realInterested + (event.promotedInterestedCount || 0);
    const partnerSeekingCount = realPartners + (event.promotedPartnerCount || 0);
    const isInterested = parts.some((p) => p.studentId === viewerId);
    const isLooking = viewerPartnerEvents.has(event.id);
    const matchingKind = event.matchingKind || 'partner';
    const canView = isLooking && matchingKind !== 'none';

    const interest = interests.find((i) => i.id === event.interestId);
    const end = event.endTime ? new Date(event.endTime) : new Date(new Date(event.startTime).getTime() + 3600000);
    const startM = minutesFromDate(new Date(event.startTime));
    const endM = minutesFromDate(end);

    const partnerProfiles = canView
      ? state.partnerProfiles.filter((p) => p.eventId === event.id && p.studentId !== viewerId)
      : [];

    return {
      id: event.id,
      title: event.title,
      description: event.description,
      location: event.location,
      timeLabel: formatRange(startM, endM),
      interestName: interest?.name || 'Campus',
      interestIcon: interest?.icon || 'calendar',
      interestedCount,
      partnerSeekingCount,
      matchingKind,
      recurrenceLabel: event.recurrenceLabel || null,
      isInterested,
      isLookingForPartner: isLooking,
      canViewPartners: canView,
      partnerProfiles,
    };
  });

  cards.sort((a, b) => {
    const aMatch = interestMatch(a, events, myInterestIds);
    const bMatch = interestMatch(b, events, myInterestIds);
    if (aMatch !== bMatch) return aMatch ? -1 : 1;
    return b.interestedCount - a.interestedCount;
  });

  return {
    events: cards,
    interests,
    myInterestIds,
    onboardingComplete: profile?.onboardingComplete ?? false,
    activeMode: modeEntry?.mode || null,
    modeExpiresAt: modeEntry?.expiresAt || null,
  };
}

function interestMatch(card, events, myInterestIds) {
  const ev = events.find((e) => e.id === card.id);
  return ev ? myInterestIds.includes(ev.interestId) : false;
}

function minutesFromDate(d) {
  return d.getHours() * 60 + d.getMinutes();
}

module.exports = { buildEvents };
