import XCTest
@testable import Papyrus

final class APITests: XCTestCase {
    func testApiEndpointReturnsNilForOptionalReturnType_forNilBody() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .nil)))
        
        // Act
        let person = try await sut.getOptional()
        
        // Assert
        XCTAssertNil(person)
    }
    
    func testApiEndpointThrowsForNonOptionalReturnType_forNilBody() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .nil)))
        
        // Act
        let expectation = expectation(description: "The endpoint with the non-optional return type should throw an error for an invalid body.")
        do {
            let _ = try await sut.get()
        } catch {
            expectation.fulfill()
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    func testApiEndpointReturnsNilForOptionalReturnType_forEmptyBody() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .empty)))
        
        // Act
        let person = try await sut.getOptional()
        
        // Assert
        XCTAssertNil(person)
    }
    
    func testApiEndpointThrowsForNonOptionalReturnType_forEmptyBody() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .empty)))
        
        // Act
        let expectation = expectation(description: "The endpoint with the non-optional return type should throw an error for an invalid body.")
        do {
            let _ = try await sut.get()
        } catch {
            expectation.fulfill()
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    func testApiEndpointReturnsValidObjectForOptionalReturnType() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .person)))
        
        // Act
        let person = try await sut.getOptional()
        
        // Assert
        XCTAssertNotNil(person)
        XCTAssertEqual(person?.name, "Petru")
    }
    
    func testApiEndpointReturnsValidObjectForNonOptionalReturnType() async throws {
        // Arrange
        let sut = _PeopleAPI(provider: .init(baseURL: "", http: _HTTPServiceMock(responseType: .person)))

        // Act
        let person = try await sut.get()

        // Assert
        XCTAssertNotNil(person)
        XCTAssertEqual(person.name, "Petru")
    }

    func testBehaviorIsAttachedToAnnotatedRequest() async throws {
        nonisolated(unsafe) var capturedBehaviors: PapyrusBehaviors?
        let provider = Provider(baseURL: "", http: _HTTPServiceMock(responseType: .nil), interceptors: [_FooHandler()])
            .intercept { req, next in
                capturedBehaviors = req.behaviors
                return try await next(req)
            }
        try? await _BehaviorsServiceAPI(provider: provider).withBehavior()
        XCTAssertTrue(capturedBehaviors?.contains(_FooBehavior.self) == true)
    }

    func testBehaviorIsAbsentOnUnannotatedRequest() async throws {
        nonisolated(unsafe) var capturedBehaviors: PapyrusBehaviors?
        let provider = Provider(baseURL: "", http: _HTTPServiceMock(responseType: .nil), interceptors: [_FooHandler()])
            .intercept { req, next in
                capturedBehaviors = req.behaviors
                return try await next(req)
            }
        try? await _BehaviorsServiceAPI(provider: provider).withoutBehavior()
        XCTAssertFalse(capturedBehaviors?.contains(_FooBehavior.self) == true)
    }

    func testProtocolLevelBehaviorIsAttachedToAllRequests() async throws {
        nonisolated(unsafe) var capturedBehaviors: PapyrusBehaviors?
        let provider = Provider(baseURL: "", http: _HTTPServiceMock(responseType: .nil), interceptors: [_FooHandler()])
            .intercept { req, next in
                capturedBehaviors = req.behaviors
                return try await next(req)
            }
        try? await _ProtocolBehaviorsServiceAPI(provider: provider).endpoint()
        XCTAssertTrue(capturedBehaviors?.contains(_FooBehavior.self) == true)
    }

    func testBehaviorsArePassedBetweenInterceptors() async throws {
        nonisolated(unsafe) var downstreamSawBehavior = false
        let provider = Provider(baseURL: "", http: _HTTPServiceMock(responseType: .nil), interceptors: [_FooHandler()])
            .intercept { req, next in
                var req = req
                req.behaviors.insert(_BarBehavior())
                return try await next(req)
            }
            .intercept { req, next in
                downstreamSawBehavior = req.behaviors.contains(_BarBehavior.self)
                return try await next(req)
            }
        try? await _BehaviorsServiceAPI(provider: provider).withoutBehavior()
        XCTAssertTrue(downstreamSawBehavior)
    }

    func testInitThrowsWhenProviderMissingBehaviorHandler() {
        let provider = Provider(baseURL: "", http: _HTTPServiceMock(responseType: .nil))
        XCTAssertThrowsError(try _HandledBehaviorEndpointServiceAPI(provider: provider))
    }

    func testInitSucceedsWithInterceptorHandler() {
        let provider = Provider(baseURL: "", http: _HTTPServiceMock(responseType: .nil), interceptors: [_HandlerInterceptor()])
        XCTAssertNoThrow(try _HandledBehaviorEndpointServiceAPI(provider: provider))
    }

    func testInitSucceedsWithModifierHandler() {
        let provider = Provider(baseURL: "", http: _HTTPServiceMock(responseType: .nil), modifiers: [_HandlerModifier()])
        XCTAssertNoThrow(try _HandledBehaviorProtocolServiceAPI(provider: provider))
    }

    func testProtocolLevelHandledBehaviorAlsoValidated() {
        let provider = Provider(baseURL: "", http: _HTTPServiceMock(responseType: .nil))
        XCTAssertThrowsError(try _HandledBehaviorProtocolServiceAPI(provider: provider))
    }
}

@API()
fileprivate protocol _People {

    @GET("")
    func getOptional() async throws -> _Person?

    @GET("")
    func get() async throws -> _Person
}

fileprivate struct _Person: Decodable {
    let name: String
}

fileprivate final class _HTTPServiceMock: HTTPService {
    
    enum ResponseType {
        case `nil`
        case empty
        case person
        
        var value: String? {
            switch self {
            case .nil:
                nil
            case .empty:
                ""
            case .person:
                "{\"name\": \"Petru\"}"
            }
        }
    }
    
    private let _responseType: ResponseType
    
    init(responseType: ResponseType) {
        _responseType = responseType
    }
    
    func build(from builder: RequestBuilder) throws -> PapyrusRequest {
        try _Request(url: builder.fullURL(), method: builder.method, headers: builder.headers, behaviors: builder.behaviors)
    }
    
    func request(_ req: PapyrusRequest) async -> PapyrusResponse {
        _Response(body: _responseType.value?.data(using: .utf8), statusCode: 200)
    }
    
    func request(_ req: PapyrusRequest, completionHandler: @escaping (PapyrusResponse) -> Void) {
        completionHandler(_Response(body: "".data(using: .utf8)))
    }
}

fileprivate struct _Request: PapyrusRequest {
    var url: URL
    var method: String
    var headers: PapyrusHeaders
    var body: Data?
    var behaviors: PapyrusBehaviors = PapyrusBehaviors()
}

fileprivate struct _Response: PapyrusResponse {
    var request: PapyrusRequest?
    var body: Data?
    var headers: PapyrusHeaders?
    var statusCode: Int?
    var error: Error?
}

fileprivate struct _FooBehavior: PapyrusBehavior {}
fileprivate struct _BarBehavior: PapyrusBehavior {}

fileprivate struct _FooHandler: Interceptor {
    typealias Behavior = _FooBehavior
    func intercept(req: PapyrusRequest, next: Interceptor.Next) async throws -> PapyrusResponse {
        try await next(req)
    }
}

@API()
fileprivate protocol _BehaviorsService {
    @GET("/with")
    @Behaviors(_FooBehavior())
    func withBehavior() async throws

    @GET("/without")
    func withoutBehavior() async throws
}

@API()
@Behaviors(_FooBehavior())
fileprivate protocol _ProtocolBehaviorsService {
    @GET("/endpoint")
    func endpoint() async throws
}

fileprivate struct _HandledByInterceptorBehavior: PapyrusBehavior {}

fileprivate struct _HandlerInterceptor: Interceptor {
    typealias Behavior = _HandledByInterceptorBehavior
    func intercept(req: PapyrusRequest, next: Interceptor.Next) async throws -> PapyrusResponse {
        try await next(req)
    }
}

fileprivate struct _HandlerModifier: RequestModifier {
    typealias Behavior = _HandledByModifierBehavior
    func modify(req: inout RequestBuilder) throws {}
}

fileprivate struct _HandledByModifierBehavior: PapyrusBehavior {}

@API()
fileprivate protocol _HandledBehaviorEndpointService {
    @GET("/endpoint")
    @Behaviors(_HandledByInterceptorBehavior())
    func endpoint() async throws
}

@API()
@Behaviors(_HandledByModifierBehavior())
fileprivate protocol _HandledBehaviorProtocolService {
    @GET("/endpoint")
    func endpoint() async throws
}
