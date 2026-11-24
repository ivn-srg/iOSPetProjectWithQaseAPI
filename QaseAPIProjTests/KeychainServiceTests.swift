import Foundation
@testable import QaseAPIProj
import Security
import Testing

/// Класс доступности токена в Keychain и перевод элементов прежних версий на месте (APP-044).
/// Тесты работают с настоящим Keychain симулятора под уникальным ключом и не трогают `authToken`.
@Suite(.serialized, .timeLimit(.minutes(1)))
struct KeychainServiceTests {
    private static let deviceOnly = kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
    private static let legacyClass = kSecAttrAccessibleWhenUnlocked as String

    // Ловит: новый элемент создаётся без `ThisDeviceOnly` и уходит в бэкап.
    @Test func newCredentialIsStoredForThisDeviceOnly() throws {
        let fixture = try KeychainFixture()
        defer { fixture.cleanUp() }
        try fixture.service.saveCredential(AuthCredential(token: "token", ownerID: "owner"))
        #expect(try fixture.item().accessibility == Self.deviceOnly)
        #expect(fixture.service.getCredential() == AuthCredential(token: "token", ownerID: "owner"))
    }

    // Ловит: атрибут добавлен в query (элемент прежней версии не найдётся → выход),
    // нет перевода при чтении, перевод через удаление и создание (новая persistent ref).
    @Test func legacyItemIsMovedToDeviceOnlyClassInPlaceOnRead() throws {
        let fixture = try KeychainFixture()
        defer { fixture.cleanUp() }
        let record = AuthCredential(token: "token", ownerID: "owner")
        try fixture.addLegacyItem(JSONEncoder().encode(record))
        let before = try fixture.item()
        #expect(before.accessibility == Self.legacyClass)
        #expect(fixture.service.getCredential() == record)
        let after = try fixture.item()
        #expect(after.accessibility == Self.deviceOnly)
        #expect(after.reference == before.reference)
    }

    // Ловит: `kSecAttrAccessible` только в `SecItemAdd` — замена токена у элемента прежней версии
    // оставляет его в старом классе.
    @Test func replacingTokenOfLegacyItemMovesItToDeviceOnlyClass() throws {
        let fixture = try KeychainFixture()
        defer { fixture.cleanUp() }
        try fixture.addLegacyItem(JSONEncoder().encode(AuthCredential(token: "old", ownerID: "owner")))
        try fixture.service.saveCredential(AuthCredential(token: "new", ownerID: "owner"))
        #expect(try fixture.item().accessibility == Self.deviceOnly)
        #expect(fixture.service.getCredential()?.token == "new")
    }

    // Ловит: сбой перевода класса скрывает токен (пользователь разлогинен после обновления)
    // или перевод не повторяется при следующем чтении.
    @Test func failedClassChangeKeepsCredentialAndRetriesOnNextRead() throws {
        let fixture = try KeychainFixture()
        defer { fixture.cleanUp() }
        let record = AuthCredential(token: "token", ownerID: "owner")
        try fixture.addLegacyItem(JSONEncoder().encode(record))
        let failing = KeychainService(key: fixture.key) { _, _ in errSecInteractionNotAllowed }
        #expect(failing.getCredential() == record)
        #expect(try fixture.item().accessibility == Self.legacyClass)
        #expect(fixture.service.getCredential() == record)
        #expect(try fixture.item().accessibility == Self.deviceOnly)
    }

    // Ловит: legacy UTF8 переписывается без смены класса или пересозданием элемента.
    @Test func legacyUTF8ItemIsRewrittenWithDeviceOnlyClassInPlace() throws {
        let fixture = try KeychainFixture()
        defer { fixture.cleanUp() }
        try fixture.addLegacyItem(Data("token".utf8))
        let before = try fixture.item()
        let first = try #require(fixture.service.getCredential())
        #expect(first.token == "token")
        let after = try fixture.item()
        #expect(after.accessibility == Self.deviceOnly)
        #expect(after.reference == before.reference)
        #expect(fixture.service.getCredential() == first)
    }
}

/// Сервис Keychain под уникальным ключом; прямой доступ к элементу для проверки атрибутов.
private struct KeychainFixture {
    let key = "tests.authToken." + UUID().uuidString
    let service: KeychainService

    init() throws {
        // Тестовый ключ не должен совпасть с рабочим: иначе тест удалит токен разработчика.
        try #require(KeychainService.defaultKey == "authToken")
        try #require(key != KeychainService.defaultKey)
        service = KeychainService(key: key)
    }

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrLabel as String: key
        ]
    }

    /// Элемент как у прежних версий: без `kSecAttrAccessible`.
    func addLegacyItem(_ data: Data) throws {
        var insertion = query
        insertion[kSecValueData as String] = data
        let status = SecItemAdd(insertion as CFDictionary, nil)
        try #require(status == errSecSuccess, "SecItemAdd: \(status)")
    }

    func item() throws -> (accessibility: String?, reference: Data?) {
        var read = query
        read[kSecReturnAttributes as String] = true
        read[kSecReturnPersistentRef as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(read as CFDictionary, &result)
        try #require(status == errSecSuccess, "SecItemCopyMatching: \(status)")
        let attributes = try #require(result as? [String: Any])
        return (
            attributes[kSecAttrAccessible as String] as? String,
            attributes[kSecValuePersistentRef as String] as? Data
        )
    }

    func cleanUp() { SecItemDelete(query as CFDictionary) }
}
