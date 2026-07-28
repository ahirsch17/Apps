import Foundation

enum EventsBuilder {
    static func build(
        events: [CampusEvent],
        interests: [Interest],
        participations: [EventParticipation],
        partnerProfiles: [PartnerSeekingProfile],
        students: [Student],
        viewerId: String,
        myInterestIds: [String],
        activeMode: ActivityMode?,
        modeExpiresAt: Date?,
        onboardingComplete: Bool
    ) -> EventsData {
        let interestById = Dictionary(uniqueKeysWithValues: interests.map { ($0.id, $0) })
        let namesById = Dictionary(uniqueKeysWithValues: students.map { ($0.id, $0.name) })

        let viewerParticipations = participations.filter { $0.studentId == viewerId }
        let viewerPartnerEventIds = Set(viewerParticipations.filter { $0.kind == .lookingForPartner }.map(\.eventId))

        let cards: [CampusEventCard] = events
            .sorted { $0.startTime < $1.startTime }
            .map { event in
                let eventParts = participations.filter { $0.eventId == event.id }
                let realInterested = Set(eventParts.map(\.studentId)).count
                let realPartners = eventParts.filter { $0.kind == .lookingForPartner }.count
                let interestedCount = realInterested + event.promotedInterestedCount
                let partnerCount = realPartners + event.promotedPartnerCount
                let isInterested = eventParts.contains { $0.studentId == viewerId }
                let isLooking = viewerPartnerEventIds.contains(event.id)
                let canView = isLooking && event.matchingKind != .none

                let profiles: [PartnerSeekingProfile] = canView
                    ? partnerProfiles.filter { $0.eventId == event.id && $0.studentId != viewerId }
                    : []

                let interest = interestById[event.interestId]
                let end = event.endTime ?? event.startTime.addingTimeInterval(3600)
                let timeLabel = ScheduleEngine.formatRange(
                    start: minutes(from: event.startTime),
                    end: minutes(from: end)
                )

                return CampusEventCard(
                    id: event.id,
                    title: event.title,
                    description: event.description,
                    location: event.location,
                    timeLabel: timeLabel,
                    interestName: interest?.name ?? "Campus",
                    interestIcon: interest?.icon ?? "calendar",
                    interestedCount: interestedCount,
                    partnerSeekingCount: partnerCount,
                    matchingKind: event.matchingKind,
                    recurrenceLabel: event.recurrenceLabel,
                    isInterested: isInterested,
                    isLookingForPartner: isLooking,
                    canViewPartners: canView,
                    partnerProfiles: profiles
                )
            }

        let sorted = cards.sorted { lhs, rhs in
            let lhsMatch = myInterestIds.contains(events.first(where: { $0.id == lhs.id })?.interestId ?? "")
            let rhsMatch = myInterestIds.contains(events.first(where: { $0.id == rhs.id })?.interestId ?? "")
            if lhsMatch != rhsMatch { return lhsMatch }
            return lhs.interestedCount > rhs.interestedCount
        }

        return EventsData(
            events: sorted,
            interests: interests,
            myInterestIds: myInterestIds,
            onboardingComplete: onboardingComplete,
            activeMode: activeMode,
            modeExpiresAt: modeExpiresAt
        )
    }

    private static func minutes(from date: Date) -> Int {
        let cal = Calendar.current
        return cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
    }
}
