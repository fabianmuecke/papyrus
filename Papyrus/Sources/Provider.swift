import Foundation

/// Makes URL requests.
public struct Provider: Sendable {
    public let baseURL: String
    public let http: HTTPService
    public var interceptors: [any Interceptor]
    public var modifiers: [any RequestModifier]

    public init(baseURL: String, http: HTTPService, modifiers: [any RequestModifier] = [], interceptors: [any Interceptor] = []) {
        self.baseURL = baseURL
        self.http = http
        self.interceptors = interceptors
        self.modifiers = modifiers
    }

    public func newBuilder(method: String, path: String) -> RequestBuilder {
        RequestBuilder(baseURL: baseURL, method: method, path: path)
    }

    public func modifyRequests(action: @escaping @Sendable (inout RequestBuilder) throws -> Void) -> Self {
        struct AnonymousModifier: RequestModifier {
            let action: @Sendable (inout RequestBuilder) throws -> Void

            func modify(req: inout RequestBuilder) throws {
                try action(&req)
            }
        }
        var result = self
        result.modifiers.append(AnonymousModifier(action: action))
        return result
    }

    @discardableResult
    public func intercept(action: @escaping @Sendable (PapyrusRequest, (PapyrusRequest) async throws -> PapyrusResponse) async throws
        -> PapyrusResponse
    ) -> Self {
        struct AnonymousInterceptor: Interceptor {
            let action: @Sendable (PapyrusRequest, Interceptor.Next) async throws -> PapyrusResponse

            func intercept(req: PapyrusRequest, next: Interceptor.Next) async throws -> PapyrusResponse {
                try await action(req, next)
            }
        }

        var result = self
        result.interceptors.append(AnonymousInterceptor(action: action))
        return result
    }

    public func requireBehaviorHandler(for behavior: any PapyrusBehavior) throws {
        try _checkBehaviorHandler(behavior)
    }

    private func _checkBehaviorHandler<B: PapyrusBehavior>(_ behavior: B) throws {
        let required = ObjectIdentifier(B.self)
        let hasHandler = interceptors.contains { _interceptorBehaviorID($0) == required }
                      || modifiers.contains   { _modifierBehaviorID($0) == required }
        guard hasHandler else {
            throw PapyrusError("Provider missing behavior handler for \(B.self).")
        }
    }

    @discardableResult
    public func request(_ builder: inout RequestBuilder) async throws -> PapyrusResponse {
        let request = try createRequest(&builder)
        var next: (PapyrusRequest) async throws -> PapyrusResponse = http.request
        for interceptor in interceptors.reversed() {
            let _next = next
            next = { try await interceptor.intercept(req: $0, next: _next) }
        }

        return try await next(request)
    }

    private func createRequest(_ builder: inout RequestBuilder) throws -> PapyrusRequest {
        for modifier in modifiers {
            try modifier.modify(req: &builder)
        }

        return try http.build(from: builder)
    }
}

private func _interceptorBehaviorID<I: Interceptor>(_ i: I) -> ObjectIdentifier {
    ObjectIdentifier(I.Behavior.self)
}

private func _modifierBehaviorID<M: RequestModifier>(_ m: M) -> ObjectIdentifier {
    ObjectIdentifier(M.Behavior.self)
}

public protocol Interceptor<Behavior>: Sendable {
    associatedtype Behavior: PapyrusBehavior = Never
    typealias Next = (PapyrusRequest) async throws -> PapyrusResponse
    func intercept(req: PapyrusRequest, next: Next) async throws -> PapyrusResponse
}

public protocol RequestModifier<Behavior>: Sendable {
    associatedtype Behavior: PapyrusBehavior = Never
    func modify(req: inout RequestBuilder) throws
}
