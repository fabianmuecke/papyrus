import XCTest
@testable import Papyrus

final class PapyrusHeadersTests: XCTestCase {

    // MARK: - Subscript

    func testSubscriptGet_returnsValue() {
        var h = PapyrusHeaders()
        h["Content-Type"] = "application/json"
        XCTAssertEqual(h["Content-Type"], "application/json")
    }

    func testSubscriptGet_caseInsensitive() {
        var h = PapyrusHeaders()
        h["content-type"] = "application/json"
        XCTAssertEqual(h["Content-Type"], "application/json")
        XCTAssertEqual(h["CONTENT-TYPE"], "application/json")
    }

    func testSubscriptSet_overwritesCaseInsensitive() {
        var h = PapyrusHeaders()
        h["Content-Type"] = "text/plain"
        h["content-type"] = "application/json"
        XCTAssertEqual(h.count, 1)
        XCTAssertEqual(h["Content-Type"], "application/json")
    }

    func testSubscriptSet_nil_removesKey() {
        var h = PapyrusHeaders()
        h["Accept"] = "application/json"
        h["Accept"] = nil
        XCTAssertNil(h["Accept"])
        XCTAssertTrue(h.isEmpty)
    }

    // MARK: - count / isEmpty

    func testIsEmpty_whenEmpty() {
        XCTAssertTrue(PapyrusHeaders().isEmpty)
    }

    func testIsEmpty_whenNotEmpty() {
        let h: PapyrusHeaders = ["key": "value"]
        XCTAssertFalse(h.isEmpty)
    }

    func testCount() {
        let h: PapyrusHeaders = ["a": "1", "b": "2", "c": "3"]
        XCTAssertEqual(h.count, 3)
    }

    func testCount_caseInsensitiveDeduplicated() {
        var h = PapyrusHeaders()
        h["X-Foo"] = "a"
        h["x-foo"] = "b"
        XCTAssertEqual(h.count, 1)
    }

    // MARK: - keys / values

    func testKeys() {
        let h: PapyrusHeaders = ["Content-Type": "application/json", "Accept": "*/*"]
        XCTAssertEqual(Set(h.keys), ["Content-Type", "Accept"])
    }

    func testValues() {
        let h: PapyrusHeaders = ["Content-Type": "application/json", "Accept": "*/*"]
        XCTAssertEqual(Set(h.values), ["application/json", "*/*"])
    }

    // MARK: - init(uniqueKeysWithValues:)

    func testInitUniqueKeysWithValues_labeled() {
        let pairs: [(key: String, value: String)] = [("A", "1"), ("B", "2")]
        let h = PapyrusHeaders(uniqueKeysWithValues: pairs)
        XCTAssertEqual(h["A"], "1")
        XCTAssertEqual(h["B"], "2")
    }

    func testInitUniqueKeysWithValues_fromDictionary() {
        let dict = ["X-Token": "abc", "Accept": "text/html"]
        let h = PapyrusHeaders(uniqueKeysWithValues: dict)
        XCTAssertEqual(h["X-Token"], "abc")
        XCTAssertEqual(h["Accept"], "text/html")
    }

    // MARK: - updateValue

    func testUpdateValue_returnsOldValue() {
        var h: PapyrusHeaders = ["key": "old"]
        let old = h.updateValue("new", forKey: "key")
        XCTAssertEqual(old, "old")
        XCTAssertEqual(h["key"], "new")
    }

    func testUpdateValue_returnsNilForNewKey() {
        var h = PapyrusHeaders()
        let old = h.updateValue("value", forKey: "key")
        XCTAssertNil(old)
        XCTAssertEqual(h["key"], "value")
    }

    func testUpdateValue_caseInsensitive() {
        var h: PapyrusHeaders = ["Content-Type": "text/plain"]
        h.updateValue("application/json", forKey: "content-type")
        XCTAssertEqual(h.count, 1)
        XCTAssertEqual(h["Content-Type"], "application/json")
    }

    // MARK: - removeValue

    func testRemoveValue_returnsRemovedValue() {
        var h: PapyrusHeaders = ["Accept": "*/*"]
        let removed = h.removeValue(forKey: "Accept")
        XCTAssertEqual(removed, "*/*")
        XCTAssertTrue(h.isEmpty)
    }

    func testRemoveValue_returnsNilForMissingKey() {
        var h = PapyrusHeaders()
        XCTAssertNil(h.removeValue(forKey: "Missing"))
    }

    func testRemoveValue_caseInsensitive() {
        var h: PapyrusHeaders = ["Content-Type": "application/json"]
        h.removeValue(forKey: "content-type")
        XCTAssertTrue(h.isEmpty)
    }

    // MARK: - merge

    func testMerge_addsNewKeys() {
        var h: PapyrusHeaders = ["A": "1"]
        h.merge([("B", "2")]) { _, new in new }
        XCTAssertEqual(h["A"], "1")
        XCTAssertEqual(h["B"], "2")
    }

    func testMerge_combinesExistingKey() {
        var h: PapyrusHeaders = ["A": "old"]
        h.merge([("A", "new")]) { old, new in old + "+" + new }
        XCTAssertEqual(h["A"], "old+new")
    }

    func testMerge_caseInsensitiveKey() {
        var h: PapyrusHeaders = ["Content-Type": "text/plain"]
        h.merge([("content-type", "application/json")]) { _, new in new }
        XCTAssertEqual(h.count, 1)
        XCTAssertEqual(h["Content-Type"], "application/json")
    }

    // MARK: - merging

    func testMerging_doesNotMutateOriginal() {
        let h: PapyrusHeaders = ["A": "1"]
        let merged = h.merging([("B", "2")]) { _, new in new }
        XCTAssertNil(h["B"])
        XCTAssertEqual(merged["A"], "1")
        XCTAssertEqual(merged["B"], "2")
    }

    // MARK: - ExpressibleByDictionaryLiteral

    func testDictionaryLiteral() {
        let h: PapyrusHeaders = ["Authorization": "Bearer token", "Accept": "application/json"]
        XCTAssertEqual(h["Authorization"], "Bearer token")
        XCTAssertEqual(h["Accept"], "application/json")
    }

    func testEmptyDictionaryLiteral() {
        let h: PapyrusHeaders = [:]
        XCTAssertTrue(h.isEmpty)
    }

    // MARK: - Sequence

    func testSequence_iteratesAllElements() {
        let h: PapyrusHeaders = ["A": "1", "B": "2"]
        let collected = Dictionary(uniqueKeysWithValues: h.map { ($0.key, $0.value) })
        XCTAssertEqual(collected, ["A": "1", "B": "2"])
    }

    // MARK: - Equatable

    func testEquality_equalHeaders() {
        let h1: PapyrusHeaders = ["Content-Type": "application/json"]
        let h2: PapyrusHeaders = ["Content-Type": "application/json"]
        XCTAssertEqual(h1, h2)
    }

    func testEquality_differentValues() {
        let h1: PapyrusHeaders = ["Content-Type": "application/json"]
        let h2: PapyrusHeaders = ["Content-Type": "text/plain"]
        XCTAssertNotEqual(h1, h2)
    }

    func testEquality_caseInsensitiveKeysAreEqual() {
        var h1 = PapyrusHeaders()
        h1["content-type"] = "application/json"
        var h2 = PapyrusHeaders()
        h2["Content-Type"] = "application/json"
        XCTAssertEqual(h1, h2)
    }

    func testEquality_emptyHeaders() {
        XCTAssertEqual(PapyrusHeaders(), PapyrusHeaders())
    }

    // MARK: - Hashable

    func testHashable_equalHeadersHaveSameHash() {
        let h1: PapyrusHeaders = ["X-Key": "value"]
        let h2: PapyrusHeaders = ["X-Key": "value"]
        XCTAssertEqual(h1.hashValue, h2.hashValue)
    }

    func testHashable_usableAsSetElement() {
        let h1: PapyrusHeaders = ["A": "1"]
        let h2: PapyrusHeaders = ["A": "1"]
        let h3: PapyrusHeaders = ["B": "2"]
        let set: Set<PapyrusHeaders> = [h1, h2, h3]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Codable

    func testCodable_roundtrip() throws {
        let h: PapyrusHeaders = ["Content-Type": "application/json", "Accept": "*/*"]
        let data = try JSONEncoder().encode(h)
        let decoded = try JSONDecoder().decode(PapyrusHeaders.self, from: data)
        XCTAssertEqual(decoded, h)
    }

    func testCodable_encodesAsFlatDictionary() throws {
        let h: PapyrusHeaders = ["X-Key": "value"]
        let data = try JSONEncoder().encode(h)
        let dict = try JSONDecoder().decode([String: String].self, from: data)
        XCTAssertEqual(dict["X-Key"], "value")
    }

    // MARK: - Collection

    func testCollection_indices() {
        let h: PapyrusHeaders = ["A": "1", "B": "2"]
        let elements = h[h.startIndex..<h.endIndex].map { $0.key }
        XCTAssertEqual(Set(elements), ["A", "B"])
    }

    func testCollection_subscriptByIndex() {
        let h: PapyrusHeaders = ["Only": "one"]
        let element = h[h.startIndex]
        XCTAssertEqual(element.key, "Only")
        XCTAssertEqual(element.value, "one")
    }
}

// MARK: - CaseInsensitiveKey

final class CaseInsensitiveKeyTests: XCTestCase {

    func testEquality_differentCase() {
        XCTAssertEqual(CaseInsensitiveKey("Content-Type"), CaseInsensitiveKey("content-type"))
        XCTAssertEqual(CaseInsensitiveKey("ACCEPT"), CaseInsensitiveKey("accept"))
    }

    func testEquality_sameCase() {
        XCTAssertEqual(CaseInsensitiveKey("X-Token"), CaseInsensitiveKey("X-Token"))
    }

    func testHashConsistency() {
        let k1 = CaseInsensitiveKey("Authorization")
        let k2 = CaseInsensitiveKey("authorization")
        XCTAssertEqual(k1.hashValue, k2.hashValue)
    }

    func testOriginalPreserved() {
        let k = CaseInsensitiveKey("Content-Type")
        XCTAssertEqual(k.original, "Content-Type")
    }

    func testDescription() {
        let k = CaseInsensitiveKey("X-Custom-Header")
        XCTAssertEqual(k.description, "X-Custom-Header")
    }

    func testExpressibleByStringLiteral() {
        let k: CaseInsensitiveKey = "content-type"
        XCTAssertEqual(k.original, "content-type")
    }

    func testCodable_roundtrip() throws {
        let k = CaseInsensitiveKey("X-Header")
        let data = try JSONEncoder().encode(k)
        let decoded = try JSONDecoder().decode(CaseInsensitiveKey.self, from: data)
        XCTAssertEqual(decoded, k)
        XCTAssertEqual(decoded.original, "X-Header")
    }
}
