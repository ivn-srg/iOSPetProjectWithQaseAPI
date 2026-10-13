import Foundation
@testable import QaseAPIProj
import Testing
import UIKit

@Suite(.serialized) @MainActor
struct AuthScreenTests {
    @Test func emptyAndWhitespaceCannotStartLogin() throws {
        let fixture = AuthScreenFixture()
        let field: UITextField = try fixture.control(.inputTextField)
        let login: UIButton = try fixture.control(.authButton)
        #expect(field.isSecureTextEntry && !login.isEnabled)
        field.text = " \n "
        field.sendActions(for: .editingChanged)
        login.sendActions(for: .touchUpInside)
        _ = field.delegate?.textFieldShouldReturn?(field)
        #expect(!login.isEnabled && fixture.service.tokens.isEmpty)
    }
    
    @Test(.timeLimit(.minutes(1))) func trimmedTokenAndAllRepeatedActionsSendOnlyOnce() async throws {
        let fixture = AuthScreenFixture()
        defer { fixture.service.finish() }
        let field: UITextField = try fixture.control(.inputTextField)
        let login: UIButton = try fixture.control(.authButton)
        let demo: UIButton = try fixture.control(.authDemo)
        let visibility: UIButton = try fixture.control(.authTokenVisibility)
        field.text = " candidate "
        field.sendActions(for: .editingChanged)
        await fixture.service.waitForStart { login.sendActions(for: .touchUpInside) }
        login.sendActions(for: .touchUpInside)
        demo.sendActions(for: .touchUpInside)
        _ = field.delegate?.textFieldShouldReturn?(field)
        #expect(fixture.service.tokens == ["candidate"])
        #expect(!field.isEnabled && !login.isEnabled && !demo.isEnabled && !visibility.isEnabled)
        #expect(login.accessibilityLabel == "Checking…".localized)
        fixture.service.finish()
        await waitUntil { login.isEnabled }
        #expect(field.text == " candidate " && demo.isEnabled && visibility.isEnabled)
    }
    
    @Test(.timeLimit(.minutes(1))) func demoRetainsInputAndUsesItsOwnLoadingState() async throws {
        let fixture = AuthScreenFixture()
        defer { fixture.service.finish() }
        let field: UITextField = try fixture.control(.inputTextField)
        let demo: UIButton = try fixture.control(.authDemo)
        field.text = "my-draft"
        field.sendActions(for: .editingChanged)
        await fixture.service.waitForStart { demo.sendActions(for: .touchUpInside) }
        #expect(fixture.service.tokens == ["QASE_DEMO"])
        #expect(field.text == "my-draft")
        #expect(demo.accessibilityLabel == "Opening demo…".localized && !demo.isEnabled)
        fixture.service.finish(error: API.NetError.invalidCredantials)
        await waitUntil { demo.isEnabled }
        let message: UIView = try fixture.control(.authMessage)
        #expect(message.accessibilityLabel == "Could not open demo. Try again.".localized)
        #expect(field.layer.borderColor != AppTheme.Palette.danger.resolvedColor(with: field.traitCollection)
            .cgColor)
    }
    
    @Test(.timeLimit(.minutes(1))) func cancelledResponseDoesNotShowAnError() async throws {
        let fixture = AuthScreenFixture()
        defer { fixture.service.finish() }
        let field: UITextField = try fixture.control(.inputTextField)
        let login: UIButton = try fixture.control(.authButton)
        let message: UIView = try fixture.control(.authMessage)
        field.text = "candidate"
        field.sendActions(for: .editingChanged)
        await fixture.service.waitForStart { login.sendActions(for: .touchUpInside) }
        fixture.service.finish(error: URLError(.cancelled))
        await waitUntil { login.isEnabled }
        #expect(message.isHidden && field.text == "candidate")
    }
    
    @Test(.timeLimit(.minutes(1)), arguments: AuthScreenErrorCase.allCases)
    func failuresPreserveInputAndUseFixedCopy(_ scenario: AuthScreenErrorCase) async throws {
        let fixture = AuthScreenFixture()
        defer { fixture.service.finish() }
        let field: UITextField = try fixture.control(.inputTextField)
        let login: UIButton = try fixture.control(.authButton)
        let message: UIView = try fixture.control(.authMessage)
        field.text = "candidate"
        field.sendActions(for: .editingChanged)
        await fixture.service.waitForStart { login.sendActions(for: .touchUpInside) }
        fixture.service.finish(error: scenario.error)
        await waitUntil { login.isEnabled }
        #expect(field.text == "candidate" && !message.isHidden)
        #expect(message.accessibilityLabel == scenario.message.localized)
        #expect(message.accessibilityLabel?.contains("server-echo") == false)
        #expect(field.layer.borderColor == (scenario.invalid
                                            ? AppTheme.Palette.danger : AppTheme.Palette.strongBorder)
            .resolvedColor(with: field.traitCollection).cgColor)
        #expect(fixture.controller.presentedViewController == nil)
        field.text = "edited"
        field.sendActions(for: .editingChanged)
        #expect(message.isHidden)
    }
    
    @Test(.timeLimit(.minutes(1))) func invalidBorderSurvivesFocusAndAppearanceChanges() async throws {
        let fixture = AuthScreenFixture()
        defer { fixture.service.finish() }
        let field: UITextField = try fixture.control(.inputTextField)
        let login: UIButton = try fixture.control(.authButton)
        field.text = "candidate"
        field.sendActions(for: .editingChanged)
        await fixture.service.waitForStart { login.sendActions(for: .touchUpInside) }
        fixture.service.finish(error: API.NetError.invalidCredantials)
        await waitUntil { login.isEnabled }
        _ = field.becomeFirstResponder()
        field.resignFirstResponder()
        fixture.controller.overrideUserInterfaceStyle = .dark
        fixture.window.layoutIfNeeded()
        await waitUntil { field.traitCollection.userInterfaceStyle == .dark }
        #expect(field.layer.borderColor == AppTheme.Palette.danger.resolvedColor(with: field.traitCollection)
            .cgColor)
        field.sendActions(for: .editingChanged)
        #expect(field.layer.borderColor == AppTheme.Palette.strongBorder
            .resolvedColor(with: field.traitCollection).cgColor)
    }
    
    @Test func visibilityPreservesSelectionFocusAndNextInsertion() throws {
        let fixture = AuthScreenFixture()
        let field: UITextField = try fixture.control(.inputTextField)
        let visibility: UIButton = try fixture.control(.authTokenVisibility)
        field.text = "abcdef"
        _ = field.becomeFirstResponder()
        let start = try #require(field.position(from: field.beginningOfDocument, offset: 2))
        let end = try #require(field.position(from: field.beginningOfDocument, offset: 4))
        field.selectedTextRange = field.textRange(from: start, to: end)
        visibility.sendActions(for: .touchUpInside)
        #expect(!field.isSecureTextEntry && field.isFirstResponder && field.text == "abcdef")
        var selection = try #require(field.selectedTextRange)
        #expect(field.offset(from: field.beginningOfDocument, to: selection.start) == 2)
        #expect(field.offset(from: field.beginningOfDocument, to: selection.end) == 4)
        visibility.sendActions(for: .touchUpInside)
        #expect(field.isSecureTextEntry && field.isFirstResponder && field.text == "abcdef")
        selection = try #require(field.selectedTextRange)
        #expect(field.offset(from: field.beginningOfDocument, to: selection.start) == 2)
        #expect(field.offset(from: field.beginningOfDocument, to: selection.end) == 4)
        field.insertText("X")
        #expect(field.text == "abXef")
        #expect(field.accessibilityIdentifier == AccessibilityID.inputTextField.identifier)
    }
    
    @Test(.timeLimit(.minutes(1))) func removingControllerCancelsAndReleasesBeforeResponse() async throws {
        let service = AuthScreenService()
        defer { service.finish() }
        let parent = UIViewController()
        var controller: AuthViewController? = AuthViewController(auth: service)
        weak var released = controller
        parent.addChild(try #require(controller))
        parent.view.addSubview(try #require(controller).view)
        controller?.didMove(toParent: parent)
        let field: UITextField = try requireControl(try #require(controller).view, .inputTextField)
        let login: UIButton = try requireControl(try #require(controller).view, .authButton)
        let message: UIView = try requireControl(try #require(controller).view, .authMessage)
        field.text = "candidate"
        field.sendActions(for: .editingChanged)
        await service.waitForStart { login.sendActions(for: .touchUpInside) }
        controller?.willMove(toParent: nil)
        controller?.view.removeFromSuperview()
        controller?.removeFromParent()
        controller = nil
        await waitUntil { service.cancelled }
        #expect(released == nil)
        service.finish(error: API.NetError.invalidCredantials)
        #expect(message.isHidden)
    }
    
    @Test(arguments: [CGFloat(320), CGFloat(402)])
    func tokenFieldRegionsStaySeparateAcrossWidthsAndTextSizes(_ width: CGFloat) throws {
        for category in [UIContentSizeCategory.large, .accessibilityExtraExtraExtraLarge] {
            let fixture = AuthScreenFixture(size: CGSize(width: width, height: 874))
            fixture.parent.traitOverrides.preferredContentSizeCategory = category
            fixture.window.layoutIfNeeded()
            fixture.controller.view.setNeedsLayout()
            fixture.controller.view.layoutIfNeeded()
            let field: UITextField = try fixture.control(.inputTextField)
            let visibility: UIButton = try fixture.control(.authTokenVisibility)
            #expect(field.attributedPlaceholder?.string == "Enter API token".localized)
            try assertTokenFieldGeometry(field)
            field.text = "candidate"
            field.sendActions(for: .editingChanged)
            for _ in 0 ..< 2 {
                visibility.sendActions(for: .touchUpInside)
                fixture.controller.view.layoutIfNeeded()
                field.layoutIfNeeded()
                try assertTokenFieldGeometry(field)
                #expect(field.text == "candidate")
            }
        }
    }
    
    @Test func tokenTextRegionsNeverHaveNegativeSizes() throws {
        let fixture = AuthScreenFixture()
        let field: UITextField = try fixture.control(.inputTextField)
        for bounds in [CGRect.zero, CGRect(x: 7, y: 3, width: 10, height: 10)] {
            let rect = field.textRect(forBounds: bounds)
            #expect(rect.width >= 0 && rect.height >= 0)
            #expect(field.editingRect(forBounds: bounds) == rect)
            #expect(field.placeholderRect(forBounds: bounds) == rect)
        }
    }
    
    @Test(arguments: [CGFloat(320), CGFloat(402)])
    func descriptionHasAReadableCenteredWidth(_ width: CGFloat) throws {
        let fixture = AuthScreenFixture(size: CGSize(width: width, height: 874))
        let label = try #require(authLabels(in: fixture.controller.view).first {
            $0.text == "Enter your API token to access your projects".localized
        })
        let rect = label.convert(label.bounds, to: fixture.controller.view)
        #expect(abs(rect.width - min(320, width - 40)) < 0.5)
        #expect(abs(rect.midX - fixture.controller.view.bounds.midX) < 0.5)
        #expect(label.numberOfLines == 0 && label.adjustsFontForContentSizeCategory)
    }
    
    @Test func compactLargeTextRemainsScrollableAndButtonsGrow() throws {
        let fixture = AuthScreenFixture(size: CGSize(width: 320, height: 480))
        fixture.parent.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        fixture.window.layoutIfNeeded()
        fixture.controller.view.setNeedsLayout()
        fixture.controller.view.layoutIfNeeded()
        let scroll = try #require(fixture.controller.view.subviews.first as? UIScrollView)
        let login: UIButton = try fixture.control(.authButton)
        let demo: UIButton = try fixture.control(.authDemo)
        #expect(scroll.contentSize.height > scroll.bounds.height)
        #expect(login.bounds.height >= 52 && demo.bounds.height >= 48)
        let rect = demo.convert(demo.bounds, to: scroll)
        scroll.scrollRectToVisible(rect, animated: false)
        #expect(scroll.bounds.intersects(rect))
    }
}

enum AuthScreenErrorCase: CaseIterable, Equatable, Sendable {
    case credentials, forbidden, offline, lostConnection, timeout, throttled, server, storage, unknown
    
    var error: Error {
        switch self {
        case .credentials: return API.NetError.invalidCredantials
        case .forbidden: return API.NetError.httpError(
            statusCode: 403,
            message: "server-echo",
            retryAfter: nil
        )
        case .offline: return URLError(.notConnectedToInternet)
        case .lostConnection: return URLError(.networkConnectionLost)
        case .timeout: return URLError(.timedOut)
        case .throttled: return API.NetError.httpError(
            statusCode: 429,
            message: "server-echo",
            retryAfter: 12
        )
        case .server: return API.NetError.httpError(statusCode: 503, message: "server-echo", retryAfter: nil)
        case .storage: return KeychainError.unhandledError(status: -1)
        case .unknown: return URLError(.badServerResponse)
        }
    }
    
    var invalid: Bool { self == .credentials }
    
    var message: String {
        switch self {
        case .credentials: return "Invalid API token. Check it and try again."
        case .forbidden: return "Could not verify access with this token"
        case .offline, .lostConnection: return "Could not connect. Check your internet connection and try again."
        case .timeout: return "Token verification timed out. Try again."
        case .throttled: return "Too many attempts. Try again later."
        case .server: return "Qase is temporarily unavailable. Try again later."
        case .storage: return "Could not save API token. Try again."
        case .unknown: return "Could not sign in. Try again."
        }
    }
}

@MainActor
private final class AuthScreenFixture {
    let service = AuthScreenService()
    let controller: AuthViewController
    let parent = UIViewController()
    let window: UIWindow
    
    init(size: CGSize = CGSize(width: 402, height: 874)) {
        controller = AuthViewController(auth: service)
        window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = parent
        window.makeKeyAndVisible()
        parent.addChild(controller)
        parent.view.addSubview(controller.view)
        controller.view.frame = parent.view.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.didMove(toParent: parent)
        window.layoutIfNeeded()
    }
    
    func control<T: UIView>(_ identifier: AccessibilityID) throws -> T {
        try requireControl(controller.view, identifier)
    }
}

@MainActor
private func assertTokenFieldGeometry(_ field: UITextField) throws {
    field.layoutIfNeeded()
    let left = try #require(field.leftView)
    let right = try #require(field.rightView)
    let leftRect = left.convert(left.bounds, to: field)
    let rightRect = right.convert(right.bounds, to: field)
    #expect(abs(leftRect.width - 44) < 0.5 && abs(rightRect.width - 44) < 0.5)
    #expect(abs(leftRect.minX - field.bounds.minX) < 0.5)
    #expect(abs(rightRect.maxX - field.bounds.maxX) < 0.5)
    #expect(abs(leftRect.height - field.bounds.height) < 0.5)
    #expect(abs(rightRect.height - field.bounds.height) < 0.5)
    #expect(field.bounds.contains(leftRect) && field.bounds.contains(rightRect))
    #expect(rightRect.height >= 44)
    for accessory in [left, right] {
        let icon = try #require(accessory.subviews.compactMap { $0 as? UIImageView }.first {
            $0.image != nil
        })
        let rect = icon.alignmentRect(forFrame: icon.frame)
        #expect(abs(rect.width - 22) < 0.5 && abs(rect.height - 22) < 0.5)
        #expect(abs(rect.midX - accessory.bounds.midX) < 0.5)
        #expect(abs(rect.midY - accessory.bounds.midY) < 0.5)
        #expect(accessory.bounds.contains(rect))
        #expect(accessory.bounds.contains(icon.convert(icon.bounds, to: accessory)))
    }
    let text = field.textRect(forBounds: field.bounds)
    #expect(text.width > 0 && text.height > 0 && field.bounds.contains(text))
    #expect(abs(text.minX - leftRect.maxX - 8) < 0.5)
    #expect(abs(rightRect.minX - text.maxX - 8) < 0.5)
    #expect(abs(text.minY - field.bounds.minY - 12) < 0.5)
    #expect(field.editingRect(forBounds: field.bounds) == text)
    #expect(field.placeholderRect(forBounds: field.bounds) == text)
}

@MainActor
private func authLabels(in view: UIView) -> [UILabel] {
    let own = (view as? UILabel).map { [$0] } ?? []
    return own + view.subviews.flatMap { authLabels(in: $0) }
}

@MainActor
private func requireControl<T: UIView>(_ view: UIView, _ identifier: AccessibilityID) throws -> T {
    if view.accessibilityIdentifier == identifier.identifier { return try #require(view as? T) }
    for child in view.subviews {
        if let found: T = findControl(child, identifier) { return found }
    }
    Issue.record("Missing auth control: \(identifier.identifier)")
    throw AuthScreenFixtureError.unexpectedMethod
}

@MainActor
private func findControl<T: UIView>(_ view: UIView, _ identifier: AccessibilityID) -> T? {
    if view.accessibilityIdentifier == identifier.identifier { return view as? T }
    for child in view.subviews {
        if let result: T = findControl(child, identifier) { return result }
    }
    return nil
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
    while !condition() { await Task.yield() }
}

private enum AuthScreenFixtureError: Error { case unexpectedMethod }

@MainActor
private final class AuthScreenService: AuthServicing {
    var tokens: [String] = []
    var cancelled = false
    private var pending: CheckedContinuation<Void, Error>?
    private var onStarted: (() -> Void)?
    var isDemoMode: Bool { false }
    
    func isUserLoggedIn() -> Bool { false }
    
    func loggedIn(token: String?) async throws {
        tokens.append(token ?? "")
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending = continuation
                let notify = onStarted
                onStarted = nil
                notify?()
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.cancelled = true }
        }
    }
    
    func waitForStart(_ action: () -> Void) async {
        await withCheckedContinuation { continuation in
            onStarted = { continuation.resume() }
            action()
        }
    }
    
    func finish(error: Error? = nil) {
        let continuation = pending
        pending = nil
        if let error { continuation?.resume(throwing: error) }
        else { continuation?.resume() }
    }
    
    func logout() async throws { throw AuthScreenFixtureError.unexpectedMethod }
    func validateReplacementToken(_ token: String) async throws -> ValidatedTokenCandidate {
        throw AuthScreenFixtureError.unexpectedMethod
    }
    
    func commitReplacementToken(_ candidate: ValidatedTokenCandidate) throws -> TokenReplacementResult {
        throw AuthScreenFixtureError.unexpectedMethod
    }
}
