//
//  PapyrusHeaders.swift
//  papyrus
//
//  Created by Fabian Mücke on 29.04.26.
//

import Foundation

/// Case insensitive `String` dictionary.
public struct PapyrusHeaders: Sendable {
    private var storage: [CaseInsensitiveKey: String] = [:]
}

// MARK: - Core interface

public extension PapyrusHeaders {
    subscript(key: String) -> String? {
        get { storage[CaseInsensitiveKey(key)] }
        set { storage[CaseInsensitiveKey(key)] = newValue }
    }

    var count: Int { storage.count }
    var isEmpty: Bool { storage.isEmpty }
    var keys: [String] { storage.keys.map(\.original) }
    var values: [String] { Array(storage.values) }

    init(uniqueKeysWithValues pairs: some Sequence<(key: String, value: String)>) {
        for (k, v) in pairs {
            storage[CaseInsensitiveKey(k)] = v
        }
    }

    @discardableResult
    mutating func updateValue(_ value: String, forKey key: String) -> String? {
        storage.updateValue(value, forKey: CaseInsensitiveKey(key))
    }

    @discardableResult
    mutating func removeValue(forKey key: String) -> String? {
        storage.removeValue(forKey: CaseInsensitiveKey(key))
    }

    mutating func merge(_ other: some Sequence<(String, String)>, uniquingKeysWith combine: (String, String) throws -> String) rethrows {
        for (k, v) in other {
            let key = CaseInsensitiveKey(k)
            storage[key] = try storage[key].map { try combine($0, v) } ?? v
        }
    }

    func merging(
        _ other: some Sequence<(String, String)>,
        uniquingKeysWith combine: (String, String) throws -> String
    ) rethrows -> PapyrusHeaders {
        var copy = self
        try copy.merge(other, uniquingKeysWith: combine)
        return copy
    }
}

// MARK: - Protocol conformances

extension PapyrusHeaders: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(uniqueKeysWithValues: elements)
    }
}

extension PapyrusHeaders: Sequence {
    public typealias Element = (key: String, value: String)

    public func makeIterator() -> AnyIterator<Element> {
        var base = storage.makeIterator()
        return AnyIterator { base.next().map { (key: $0.key.original, value: $0.value) } }
    }
}

extension PapyrusHeaders: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.storage == rhs.storage }
}

extension PapyrusHeaders: Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(storage) }
}

extension PapyrusHeaders: CustomStringConvertible {
    public var description: String {
        "\(storage)"
    }
}

extension PapyrusHeaders: Codable {
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(Dictionary(uniqueKeysWithValues: map { ($0.key, $0.value) }))
    }

    public init(from decoder: any Decoder) throws {
        let dict = try decoder.singleValueContainer().decode([String: String].self)
        self.init(uniqueKeysWithValues: dict)
    }
}

extension PapyrusHeaders: Collection {
    public typealias Index = Dictionary<CaseInsensitiveKey, String>.Index

    public var startIndex: Index { storage.startIndex }
    public var endIndex: Index { storage.endIndex }

    public func index(after i: Index) -> Index { storage.index(after: i) }

    public subscript(position: Index) -> Element {
        let (k, v) = storage[position]
        return (key: k.original, value: v)
    }
}

public struct CaseInsensitiveKey: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let original: String
    private let lowercased: String

    public init(_ s: String) { self.original = s
        self.lowercased = s.lowercased()
    }

    public init(stringLiteral s: StringLiteralType) { self.init(s) }

    public static func == (l: Self, r: Self) -> Bool { l.lowercased == r.lowercased }
    public func hash(into h: inout Hasher) { h.combine(lowercased) }
    public var description: String { original }
}

extension CaseInsensitiveKey: Encodable {
    public func encode(to encoder: any Encoder) throws {
        try original.encode(to: encoder)
    }
}

extension CaseInsensitiveKey: Decodable {
    public init(from decoder: any Decoder) throws {
        try self.init(String(from: decoder))
    }
}
