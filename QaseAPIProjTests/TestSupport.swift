import Foundation
@testable import QaseAPIProj
import Testing
import UIKit

/// Общее ожидание условия: каждая итерация отдаёт управление следующему обороту run loop.
/// Имя отличается от `waitUntil`: в `AuthScreenTests.swift` есть одноимённый private-хелпер.
@MainActor
func waitForCondition(_ condition: () -> Bool) async {
    // Ограниченное ожидание: зависший тест не должен блокировать MainActor для всего прогона.
    for _ in 0..<200 where !condition() && !Task.isCancelled {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
    #expect(condition())
}

/// Фейк списка проектов: готовый ответ, ответ после `release()` или ошибка сети.
@MainActor
final class ProjectsSource: ProjectsReading {
    enum Mode {
        case projects([ProjectSummary])
        case suspended([ProjectSummary])
        case failure
    }

    var mode: Mode
    private var gate: CheckedContinuation<Void, Never>?
    private var isReleased = false
    private(set) var requests = 0

    init(_ mode: Mode) { self.mode = mode }

    func release() {
        isReleased = true
        gate?.resume()
        gate = nil
    }

    func listProjects(offset: Int) async throws -> QaseAPIListResult<ProjectSummary> {
        requests += 1
        switch mode {
        case .failure:
            throw API.NetError.noInternetConnection
        case .projects(let projects):
            return page(projects)
        case .suspended(let projects):
            if !isReleased { await withCheckedContinuation { gate = $0 } }
            return page(projects)
        }
    }

    private func page(_ projects: [ProjectSummary]) -> QaseAPIListResult<ProjectSummary> {
        QaseAPIListResult(total: projects.count, filtered: nil, count: projects.count, entities: projects)
    }
}

/// Заглушка экрана с черновиком; уход можно приостановить и ответить на него вручную.
@MainActor
final class DraftScreen: UIViewController, FormDepartureParticipant {
    var hasUnsavedChanges = true
    var canSaveDraft = true
    var isSavingDraft = false
    var suspendsDeparture = false
    private(set) var departureRequests = 0
    private(set) var finishEditingCalls = 0
    private var pending: CheckedContinuation<Bool, Never>?

    func finishEditing() { finishEditingCalls += 1 }

    func requestDeparture() async -> Bool {
        departureRequests += 1
        guard suspendsDeparture else { return true }
        return await withCheckedContinuation { pending = $0 }
    }

    func answer(_ value: Bool) {
        pending?.resume(returning: value)
        pending = nil
    }

    func saveDraft() async throws {}
    func discardDraft() { hasUnsavedChanges = false }
}
