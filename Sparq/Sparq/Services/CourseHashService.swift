import CryptoKit
import Foundation

// Client-side course hashing: server never sees raw CRNs/titles
// Only SHA-256 hashes leave device for classmate matching
enum CourseHashService {
    /// Salt is per-school; in production delivered via SSO consent payload.
    static func hash(canonicalCourseId: String, schoolId: String) -> String {
        let material = "\(schoolId):\(canonicalCourseId)"
        let digest = SHA256.hash(data: Data(material.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func hashSections(_ sections: [CourseSection], schoolId: String) -> [String] {
        Array(Set(sections.map { hash(canonicalCourseId: $0.canonicalCourseId, schoolId: schoolId) }))
    }

    static func hashEnrollment(canonicalCourseIds: [String], schoolId: String) -> [String] {
        Array(Set(canonicalCourseIds.map { hash(canonicalCourseId: $0, schoolId: schoolId) }))
    }
}
