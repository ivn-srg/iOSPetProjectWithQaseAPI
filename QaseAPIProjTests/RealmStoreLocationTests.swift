import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

/// Перенос базы из `Documents` (попадала в бэкап) в `Application Support/QaseCache` (APP-041).
@Suite(.timeLimit(.minutes(1))) @MainActor
struct RealmStoreLocationTests {
    // Ловит: новая установка остаётся в `Documents` или каталог не исключён из бэкапа.
    @Test func freshInstallUsesExcludedApplicationSupportDirectory() throws {
        let dirs = try TemporaryContainer()
        defer { dirs.remove() }
        let url = RealmManager.storeURL(documents: dirs.documents, applicationSupport: dirs.support)
        #expect(url == dirs.target)
        #expect(try dirs.isExcludedFromBackup(dirs.directory))
        #expect(!FileManager.default.fileExists(atPath: dirs.legacy.path))
    }

    // Ловит: копирование вместо переноса (старая база остаётся в бэкапе), потеря `legacy-backup`
    // или истории, служебные файлы Realm остаются в `Documents`, файл базы не исключён из бэкапа.
    @Test func existingStoreIsMovedWithHistoryAndBackup() throws {
        let dirs = try TemporaryContainer()
        defer { dirs.remove() }
        let session = SessionContext(ownerID: "owner")
        try Self.writeRecentCase(at: dirs.legacy, session: session)
        try Data("backup".utf8).write(to: dirs.legacyBackup)
        #expect(FileManager.default.fileExists(atPath: dirs.legacy.path + ".lock"))
        let fileNumber = try dirs.fileNumber(dirs.legacy)

        let url = RealmManager.storeURL(documents: dirs.documents, applicationSupport: dirs.support)

        #expect(url == dirs.target)
        // Атомарный перенос сохраняет файл; копирование создаёт новый (и при обрыве — частичную копию).
        #expect(try dirs.fileNumber(dirs.target) == fileNumber)
        for suffix in ["", ".lock", ".note", ".management", ".legacy-backup"] {
            #expect(!FileManager.default.fileExists(atPath: dirs.legacy.path + suffix), "\(suffix)")
        }
        #expect(try Data(contentsOf: dirs.targetBackup) == Data("backup".utf8))
        #expect(try dirs.isExcludedFromBackup(dirs.target))
        let moved = RealmManager(configuration: RealmManager.migratedConfiguration(
            Realm.Configuration(fileURL: url)
        ), session: session)
        #expect(moved.getRecentCases(projectCode: "A").map(\.reference.caseID) == [42])
    }

    // Ловит: при наличии базы в новом месте берётся старая; брошенная после отката база
    // остаётся в `Documents` (в бэкапе).
    @Test func storeInApplicationSupportWinsAndRollbackLeftoverIsRemoved() throws {
        let dirs = try TemporaryContainer()
        defer { dirs.remove() }
        try FileManager.default.createDirectory(at: dirs.directory, withIntermediateDirectories: true)
        try Data("current".utf8).write(to: dirs.target)
        try Data("rollback".utf8).write(to: dirs.legacy)
        let url = RealmManager.storeURL(documents: dirs.documents, applicationSupport: dirs.support)
        #expect(url == dirs.target)
        #expect(try Data(contentsOf: dirs.target) == Data("current".utf8))
        #expect(!FileManager.default.fileExists(atPath: dirs.legacy.path))
    }

    // Ловит: `legacy-backup`, оставшийся в `Documents` после частичного переноса, остаётся там навсегда.
    @Test func leftoverLegacyBackupIsMovedOnNextLaunch() throws {
        let dirs = try TemporaryContainer()
        defer { dirs.remove() }
        try FileManager.default.createDirectory(at: dirs.directory, withIntermediateDirectories: true)
        try Data("current".utf8).write(to: dirs.target)
        try Data("backup".utf8).write(to: dirs.legacyBackup)
        _ = RealmManager.storeURL(documents: dirs.documents, applicationSupport: dirs.support)
        #expect(!FileManager.default.fileExists(atPath: dirs.legacyBackup.path))
        #expect(try Data(contentsOf: dirs.targetBackup) == Data("backup".utf8))
    }

    // Ловит: при сбое переноса — новый пустой файл (потеря истории) вместо прежней базы;
    // бэкап переносится раньше основного файла; перенос не повторяется на следующем запуске.
    @Test func failedMoveKeepsUsingTheOldStoreAndRetriesNextLaunch() throws {
        let dirs = try TemporaryContainer()
        defer { dirs.remove() }
        try Data("old".utf8).write(to: dirs.legacy)
        try Data("backup".utf8).write(to: dirs.legacyBackup)
        let url = RealmManager.storeURL(
            documents: dirs.documents,
            applicationSupport: dirs.support,
            fileManager: FailingMoveFileManager()
        )
        #expect(url == dirs.legacy)
        #expect(try Data(contentsOf: dirs.legacy) == Data("old".utf8))
        #expect(FileManager.default.fileExists(atPath: dirs.legacyBackup.path))
        #expect(!FileManager.default.fileExists(atPath: dirs.target.path))
        let retried = RealmManager.storeURL(documents: dirs.documents, applicationSupport: dirs.support)
        #expect(retried == dirs.target)
        #expect(try Data(contentsOf: dirs.target) == Data("old".utf8))
        #expect(try Data(contentsOf: dirs.targetBackup) == Data("backup".utf8))
    }

    // Ловит: каталог назначения недоступен — база открывается в несуществующем каталоге (кеш недоступен).
    @Test func unavailableStoreDirectoryKeepsTheOldLocation() throws {
        let dirs = try TemporaryContainer()
        defer { dirs.remove() }
        // Путь каталога занят файлом: создать каталог нельзя.
        try Data().write(to: dirs.directory)
        let empty = RealmManager.storeURL(documents: dirs.documents, applicationSupport: dirs.support)
        #expect(empty == dirs.legacy)
        try Data("old".utf8).write(to: dirs.legacy)
        let existing = RealmManager.storeURL(documents: dirs.documents, applicationSupport: dirs.support)
        #expect(existing == dirs.legacy)
        #expect(try Data(contentsOf: dirs.legacy) == Data("old".utf8))
    }

    // Ловит: бэкап из `Documents` перезаписывает уже перенесённый (NG-3: бэкапы не удаляются).
    @Test func existingBackupInNewLocationIsNotOverwritten() throws {
        let dirs = try TemporaryContainer()
        defer { dirs.remove() }
        try FileManager.default.createDirectory(at: dirs.directory, withIntermediateDirectories: true)
        try Data("current".utf8).write(to: dirs.target)
        try Data("moved".utf8).write(to: dirs.targetBackup)
        try Data("stale".utf8).write(to: dirs.legacyBackup)
        _ = RealmManager.storeURL(documents: dirs.documents, applicationSupport: dirs.support)
        #expect(try Data(contentsOf: dirs.targetBackup) == Data("moved".utf8))
        #expect(try Data(contentsOf: dirs.legacyBackup) == Data("stale".utf8))
    }

    // Ловит: повторный запуск снова переносит или теряет исключение из бэкапа.
    @Test func repeatedLaunchKeepsLocationAndBackupExclusion() throws {
        let dirs = try TemporaryContainer()
        defer { dirs.remove() }
        try Data("old".utf8).write(to: dirs.legacy)
        let first = RealmManager.storeURL(documents: dirs.documents, applicationSupport: dirs.support)
        let second = RealmManager.storeURL(documents: dirs.documents, applicationSupport: dirs.support)
        #expect(first == dirs.target && second == dirs.target)
        #expect(try Data(contentsOf: dirs.target) == Data("old".utf8))
        #expect(try dirs.isExcludedFromBackup(dirs.directory))
        #expect(try dirs.isExcludedFromBackup(dirs.target))
    }

    /// Настоящая база прежнего расположения с одной записью истории; Realm закрывается до переноса.
    private static func writeRecentCase(at url: URL, session: SessionContext) throws {
        try autoreleasepool {
            let cache = RealmManager(
                configuration: RealmManager.migratedConfiguration(Realm.Configuration(fileURL: url)),
                session: session
            )
            let item = RecentCaseItem(
                reference: TestCaseReference(projectCode: "A", caseID: 42),
                title: "Case",
                description: nil,
                priority: nil,
                automation: nil,
                viewedAt: Date(timeIntervalSince1970: 1)
            )
            try #require(cache.recordRecentCase(item, stamp: session.capture()))
        }
    }
}

/// Временные «Documents» и «Application Support» контейнера приложения.
private struct TemporaryContainer {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    var documents: URL { root.appendingPathComponent("Documents") }
    var support: URL { root.appendingPathComponent("Application Support") }
    var directory: URL { support.appendingPathComponent(RealmManager.storeDirectoryName) }
    var legacy: URL { documents.appendingPathComponent("default.realm") }
    var legacyBackup: URL { legacy.appendingPathExtension("legacy-backup") }
    var target: URL { directory.appendingPathComponent("default.realm") }
    var targetBackup: URL { target.appendingPathExtension("legacy-backup") }

    init() throws {
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
    }

    func fileNumber(_ url: URL) throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return try #require(attributes[.systemFileNumber] as? Int)
    }

    func isExcludedFromBackup(_ url: URL) throws -> Bool {
        try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true
    }

    func remove() { try? FileManager.default.removeItem(at: root) }
}

/// Перенос файла всегда завершается ошибкой; остальные операции — как у системного `FileManager`.
private final class FailingMoveFileManager: FileManager {
    override func moveItem(at srcURL: URL, to dstURL: URL) throws {
        throw CocoaError(.fileWriteUnknown)
    }
}
