import Foundation

public protocol PapyrusBehavior: Sendable {}

public struct PapyrusBehaviors: Sendable {
    private var storage: [ObjectIdentifier: any PapyrusBehavior] = [:]

    public init() {}

    public mutating func insert<B: PapyrusBehavior>(_ behavior: B) {
        storage[ObjectIdentifier(B.self)] = behavior
    }

    public func get<B: PapyrusBehavior>(_ type: B.Type) -> B? {
        storage[ObjectIdentifier(type)] as? B
    }

    public func contains<B: PapyrusBehavior>(_ type: B.Type) -> Bool {
        storage[ObjectIdentifier(type)] != nil
    }

    public mutating func remove<B: PapyrusBehavior>(_ type: B.Type) {
        storage.removeValue(forKey: ObjectIdentifier(type))
    }
}
