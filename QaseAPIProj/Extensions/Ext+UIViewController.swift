//
//  Ext+UIViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 24.10.2024.
//

import UIKit

extension UIViewController {
    // Universalized func for error handling
    @discardableResult
    func executeWithErrorHandling(
        presentingViewController: UIViewController? = nil,
        _ action: @escaping () async throws -> Void
    ) -> Task<Void, Never> {
        Task {
            do {
                try await action()
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else { return }
                var errorMessage = "Unknown Error".localized

                if let error = error as? API.NetError {
                    switch error {
                    case .invalidURL, .timeout:
                        errorMessage = "Something went wrong".localized
                    case .parsingError(let message), .otherNetworkError(let message),
                         .serializationError(let message):
                        errorMessage = message
                    case .noInternetConnection:
                        errorMessage = "Internet connection problem".localized
                    case .invalidCredantials:
                        errorMessage = "Invalid credentials".localized
                    case .invalidRequest(let message):
                        errorMessage = message
                    case .httpError(_, let message, _):
                        errorMessage = message
                    }
                } else {
                    errorMessage = error.localizedDescription
                }

                await MainActor.run {
                    UIAlertController.showSimpleAlert(
                        on: presentingViewController ?? self,
                        title: "Error".localized,
                        message: errorMessage
                    )
                }
            }
        }
    }
}

extension UIViewController {
    /// Верхний презентер: идёт по модальной цепочке, выбранной вкладке и видимому экрану навигации.
    var topPresentedController: UIViewController {
        if let presented = presentedViewController, !presented.isBeingDismissed {
            return presented.topPresentedController
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topPresentedController
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.topPresentedController
        }
        return self
    }

    /// Можно ли показать модальный экран сейчас; при незавершённом переходе `present` молча не сработает.
    var canPresentNow: Bool {
        isViewLoaded && view.window != nil && !isBeingPresented && !isBeingDismissed
            && presentedViewController == nil
    }
}

extension UIViewController {
    /// Ждёт завершения present/dismiss/push в модальной цепочке и у верхнего экрана, чтобы `canPresentNow`
    /// не отказывал из-за закрывающегося алерта или диалога. Ожидание ограничено по времени (~1 с).
    @MainActor
    func awaitPresentationTransitions() async {
        let deadline = ContinuousClock.now + .seconds(1)
        while !Task.isCancelled, ContinuousClock.now < deadline,
              let transitioning = controllerInTransition() {
            if let coordinator = transitioning.transitionCoordinator {
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    // По документации Apple completion может вызваться и при `animate == false`.
                    var resumed = false
                    let finish = {
                        guard !resumed else { return }
                        resumed = true
                        continuation.resume()
                    }
                    if !coordinator.animate(alongsideTransition: nil, completion: { _ in finish() }) {
                        finish()
                    }
                }
            } else {
                // Переход без координатора завершает run loop: проверяем условие по таймеру.
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    /// Верхний контроллер, на котором можно показать модальный экран, после завершения переходов.
    /// `nil`, если сверху уже алерт или показ сейчас невозможен.
    @MainActor
    func presenterWhenReady() async -> UIViewController? {
        await awaitPresentationTransitions()
        let presenter = topPresentedController
        guard !(presenter is UIAlertController), presenter.canPresentNow else { return nil }
        return presenter
    }

    private func controllerInTransition() -> UIViewController? {
        var candidates: [UIViewController] = []
        for start in [viewIfLoaded?.window?.rootViewController, self] {
            var next = start
            while let controller = next {
                candidates.append(controller)
                next = controller.presentedViewController
            }
        }
        let top = topPresentedController
        candidates.append(top)
        if let navigation = top.navigationController { candidates.append(navigation) }
        return candidates.first {
            $0.transitionCoordinator != nil || $0.isBeingPresented || $0.isBeingDismissed
        }
    }
}
