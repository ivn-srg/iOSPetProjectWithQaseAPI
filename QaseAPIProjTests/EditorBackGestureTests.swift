import Foundation
@testable import QaseAPIProj
import Testing
import UIKit

/// Обвязка жеста «назад» редактора кейса: перехват и возврат делегата `interactivePopGestureRecognizer`,
/// проброс в прежний делегат и подтверждение ухода с изменённым черновиком.
@Suite(.timeLimit(.minutes(1))) @MainActor
struct EditorBackGestureTests {
    /// Ловит: редактор не перехватывает делегат жеста при появлении (`viewWillAppear`)
    /// или не возвращает прежний при исчезновении (`viewWillDisappear`).
    @Test func editorTakesTheGestureDelegateOnAppearAndGivesItBackOnDisappear() throws {
        let fixture = try EditorBackFixture(stackDepth: 2)
        #expect(fixture.gesture.delegate === fixture.stub)
        fixture.editor.viewWillAppear(false)
        #expect(fixture.gesture.delegate === fixture.editor)
        fixture.editor.viewWillDisappear(false)
        #expect(fixture.gesture.delegate === fixture.stub)
    }

    /// Ловит: чистый черновик не пробрасывает решение прежнему делегату жеста
    /// (всегда `true` или всегда `false`).
    @Test func cleanDraftForwardsTheDecisionToThePreviousGestureDelegate() throws {
        let fixture = try EditorBackFixture(stackDepth: 2)
        fixture.model.testCase = .empty
        fixture.model.changedTestCase = .empty
        fixture.editor.viewWillAppear(false)
        fixture.stub.answer = false
        #expect(!fixture.editor.gestureRecognizerShouldBegin(fixture.gesture))
        fixture.stub.answer = true
        #expect(fixture.editor.gestureRecognizerShouldBegin(fixture.gesture))
    }

    /// Ловит: удалена проверка глубины стека — жест начинается на единственном экране навигации
    /// (возврат некуда); жест остаётся включённым при одном экране.
    @Test func gestureDoesNotBeginAndIsDisabledWhenTheEditorIsTheOnlyScreen() throws {
        let fixture = try EditorBackFixture(stackDepth: 1)
        fixture.model.testCase = .empty
        fixture.model.changedTestCase = .empty
        fixture.stub.answer = true
        fixture.editor.viewWillAppear(false)
        #expect(!fixture.gesture.isEnabled)
        #expect(!fixture.editor.gestureRecognizerShouldBegin(fixture.gesture))
    }

    /// Ловит: удалена ветка `hasUnsavedChanges` (жест уходит без подтверждения: прежний делегат
    /// отвечает `true`) или она возвращает `false` без `goBack()` (алерт не появляется).
    @Test func changedDraftBlocksTheGestureAndAsksToDiscardChanges() async throws {
        let fixture = try EditorBackFixture(stackDepth: 2, inWindow: true)
        defer { fixture.tearDown() }
        await waitForCondition { fixture.editor.view.window != nil }
        fixture.stub.answer = true
        fixture.editor.viewWillAppear(false)
        var original = TestCaseEntity.empty
        original.title = "Original"
        var edited = original
        edited.title = "Edited"
        // Между записью черновика и вызовом жеста нет `await`: загрузка кейса не успевает вмешаться.
        fixture.model.testCase = original
        fixture.model.changedTestCase = edited
        let began = fixture.editor.gestureRecognizerShouldBegin(fixture.gesture)
        #expect(!began)
        // Текст через `.localized`: тест не зависит от языка симулятора. Алерт остаётся открытым,
        // задача `goBack()` ждёт ответа до освобождения окна — на результат это не влияет.
        await waitForCondition { fixture.presentedAlert?.title == "Discard changes?".localized }
        #expect(fixture.model.hasUnsavedChanges)
    }
}

/// Редактор кейса в навигации `[root, editor]` (или только `[editor]`) с заглушкой прежнего
/// делегата жеста; окно — только когда нужен реальный показ алерта.
@MainActor
private final class EditorBackFixture {
    let navigation: UINavigationController
    let model: TestCaseEditorViewModel
    let editor: TestCaseViewController
    let stub: GestureDelegateStub
    let gesture: UIGestureRecognizer
    private var window: UIWindow?

    init(stackDepth: Int, inWindow: Bool = false) throws {
        let session = SessionContext(ownerID: "owner")
        let model = TestDependencies.detail(
            reference: .init(projectCode: "DEMO", caseID: 1),
            network: OfflineEditorNetwork(),
            session: session
        )
        let editor = TestCaseViewController(
            viewModel: model,
            form: GeneralDetailCaseViewController(vm: model),
            session: session
        )
        let navigation = UINavigationController()
        let stub = GestureDelegateStub()
        navigation.loadViewIfNeeded()
        // Допущение плана: без окна жест у навигации уже создан после загрузки её view.
        let gesture = try #require(navigation.interactivePopGestureRecognizer)
        gesture.delegate = stub
        self.model = model
        self.editor = editor
        self.navigation = navigation
        self.stub = stub
        self.gesture = gesture
        if inWindow {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
            window.rootViewController = navigation
            window.makeKeyAndVisible()
            self.window = window
        }
        navigation.setViewControllers(
            stackDepth > 1 ? [UIViewController(), editor] : [editor],
            animated: false
        )
        editor.loadViewIfNeeded()
        // Окно без сцены не проходит layout само: без него навигация не вставит view редактора,
        // и показывать алерт будет некуда.
        window?.layoutIfNeeded()
    }

    /// Алерт подтверждения ухода: первый `UIAlertController` в модальной цепочке окна.
    var presentedAlert: UIAlertController? {
        var next = window?.rootViewController
        while let controller = next {
            if let alert = controller as? UIAlertController { return alert }
            next = controller.presentedViewController
        }
        return nil
    }

    func tearDown() { window?.isHidden = true }
}

/// Прежний делегат жеста с настраиваемым ответом.
@MainActor
private final class GestureDelegateStub: NSObject, UIGestureRecognizerDelegate {
    var answer = true

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool { answer }
}

/// Сеть без данных: загрузка кейса в `viewDidLoad` завершается ошибкой и не меняет черновик.
private final class OfflineEditorNetwork: NetworkManager {
    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .noInternetConnection }

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidRequest("No multipart fixture") }

    func auth(by token: String) async throws -> Bool { true }
}
