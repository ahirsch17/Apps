import Foundation

/// Matches address-book phone numbers to registered students in the database.
enum ContactSuggestionMatcher {
    /// Student IDs whose directory phone appears on the user's device contacts.
    static func matchedStudentIds(students: [Student], deviceContacts: [DeviceContactEntry]) -> Set<String> {
        let contactPhones = Set(deviceContacts.compactMap { normalizePhone($0.phoneNumber) })
        guard !contactPhones.isEmpty else { return [] }

        var matched: Set<String> = []
        for student in students {
            guard let phone = student.phoneNumber, let normalized = normalizePhone(phone) else { continue }
            if contactPhones.contains(normalized) {
                matched.insert(student.id)
            }
        }
        return matched
    }

    /// E.164-ish normalization for demo matching (digits only, US 10-digit → leading 1).
    static func normalizePhone(_ raw: String) -> String? {
        let digits = raw.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        if digits.count == 10 { return "1" + digits }
        return digits
    }

    static func applyingContactSuggestions(to students: [Student], contactMatchedIds: Set<String>) -> [Student] {
        students.map { student in
            let via: String? = contactMatchedIds.contains(student.id) ? "contacts" : nil
            return student.withSuggestedVia(via)
        }
    }
}
