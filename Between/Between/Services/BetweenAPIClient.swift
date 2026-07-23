import Foundation

/// HTTP transport for the deployed Between API. Endpoints mirror what the local service simulates.
enum APIRoute {
    case loginCandidates
    case login
    case dashboard
    case friendRequest
    case acceptFriendRequest(String)
    case presence
    case plans
    case nudge
    case presenceStream

    func path(baseURL: URL) -> URL {
        switch self {
        case .loginCandidates:
            return baseURL.appending(path: "/v1/auth/demo-candidates")
        case .login:
            return baseURL.appending(path: "/v1/auth/login")
        case .dashboard:
            return baseURL.appending(path: "/v1/me/dashboard")
        case .friendRequest:
            return baseURL.appending(path: "/v1/friends/requests")
        case .acceptFriendRequest(let id):
            return baseURL.appending(path: "/v1/friends/requests/\(id)/accept")
        case .presence:
            return baseURL.appending(path: "/v1/me/presence")
        case .plans:
            return baseURL.appending(path: "/v1/plans")
        case .nudge:
            return baseURL.appending(path: "/v1/nudges")
        case .presenceStream:
            return baseURL.appending(path: "/v1/me/presence/stream")
        }
    }
}

struct BetweenAPIClient {
    let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func get<T: Decodable>(_ route: APIRoute, token: String? = nil) async throws -> T {
        var request = URLRequest(url: route.path(baseURL: baseURL))
        request.httpMethod = "GET"
        applyAuth(&request, token: token)
        return try await perform(request)
    }

    func post<Body: Encodable, Response: Decodable>(
        _ route: APIRoute,
        body: Body,
        token: String? = nil
    ) async throws -> Response {
        var request = URLRequest(url: route.path(baseURL: baseURL))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        applyAuth(&request, token: token)
        return try await perform(request)
    }

    func patch<Body: Encodable, Response: Decodable>(
        _ route: APIRoute,
        body: Body,
        token: String
    ) async throws -> Response {
        var request = URLRequest(url: route.path(baseURL: baseURL))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        applyAuth(&request, token: token)
        return try await perform(request)
    }

    private func applyAuth(_ request: inout URLRequest, token: String?) {
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw BackendError.server(message: "Invalid response")
            }
            switch http.statusCode {
            case 200...299:
                return try decoder.decode(T.self, from: data)
            case 401:
                throw BackendError.unauthorized
            default:
                let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                throw BackendError.server(message: message)
            }
        } catch let error as BackendError {
            throw error
        } catch {
            throw BackendError.network(underlying: error)
        }
    }
}

// MARK: - Request / response DTOs (API wire format)

struct LoginRequestBody: Encodable {
    let email: String
    let password: String?
}

struct LoginResponseBody: Decodable {
    let session: AuthSession
    let dashboard: DashboardDTO
}

struct DashboardDTO: Decodable {
    let me: Student
    let nearbyFriends: [FriendCardDTO]
    let classConnections: [ClassConnectionDTO]
    let mySections: [CourseSection]
    let pendingIncoming: [IncomingFriendRequestDTO]
    let pendingOutgoing: [Student]
    let suggestedStudents: [Student]
    let plans: [Plan]
    let todayPlan: [TodayPlanItemDTO]
    let syncTimestamp: Date
}

struct FriendCardDTO: Decodable {
    let id: String
    let name: String
    let email: String
    let avatarEmoji: String
    let status: String
    let activity: String
    let location: String
    let distanceLabel: String

    func asModel() -> FriendCard {
        FriendCard(
            id: id,
            name: name,
            email: email,
            avatarEmoji: avatarEmoji,
            status: PresenceStatus(rawValue: status) ?? .busy,
            activity: activity,
            location: location,
            distanceLabel: distanceLabel
        )
    }
}

struct ClassConnectionDTO: Decodable {
    let id: String
    let courseCode: String
    let courseName: String
    let friendName: String
    let kind: String
    let sectionLabel: String
    let meetingDays: [String]

    func asModel() -> ClassConnection {
        ClassConnection(
            id: id,
            courseCode: courseCode,
            courseName: courseName,
            friendName: friendName,
            kind: ClassConnection.Kind(rawValue: kind) ?? .differentSection,
            sectionLabel: sectionLabel,
            meetingDays: meetingDays
        )
    }
}

struct IncomingFriendRequestDTO: Decodable {
    let requestId: String
    let from: Student
}

struct TodayPlanItemDTO: Decodable {
    let id: String
    let kind: String
    let startMinutes: Int
    let endMinutes: Int
    let section: CourseSection?
    let friendOverlaps: [FriendOverlapDTO]
}

struct FriendOverlapDTO: Decodable {
    let id: String
    let friendId: String
    let friendName: String
    let intervals: [[Int]]
    let totalMinutes: Int
}

extension DashboardDTO {
    func asDashboardData() -> DashboardData {
        DashboardData(
            me: me,
            nearbyFriends: nearbyFriends.map { $0.asModel() },
            classConnections: classConnections.map { $0.asModel() },
            mySections: mySections,
            pendingIncoming: pendingIncoming.map {
                IncomingFriendRequest(requestId: $0.requestId, from: $0.from)
            },
            pendingOutgoing: pendingOutgoing,
            suggestedStudents: suggestedStudents,
            plans: plans,
            todayPlan: todayPlan.map { $0.asModel() },
            syncTimestamp: syncTimestamp
        )
    }
}

extension TodayPlanItemDTO {
    func asModel() -> TodayPlanItem {
        TodayPlanItem(
            id: id,
            kind: kind == "classBlock" ? .classBlock : .freeBlock,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            section: section,
            friendOverlaps: friendOverlaps.map { dto in
                FriendOverlap(
                    id: dto.id,
                    friendId: dto.friendId,
                    friendName: dto.friendName,
                    intervals: dto.intervals.compactMap { pair in
                        guard pair.count == 2 else { return nil }
                        return (pair[0], pair[1])
                    },
                    totalMinutes: dto.totalMinutes
                )
            }
        )
    }
}
