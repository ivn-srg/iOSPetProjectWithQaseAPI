import UIKit

final class MainTabbarViewController: UITabBarController, ApplicationNavigationHost {
    private let router: ApplicationRouting
    private let session: SessionContext
    private var isChangingTab = false
    var navigationRoot: UIViewController { self }

    init(roots: [UIViewController], router: ApplicationRouting, session: SessionContext) {
        self.router = router
        self.session = session
        super.init(nibName: nil, bundle: nil)
        setViewControllers(roots, animated: false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.tintColor = AppTheme.Palette.accent
        tabBar.unselectedItemTintColor = AppTheme.Palette.secondaryText
        router.start()
    }

    func replaceRoots(_ controllers: [UIViewController], selectedIndex: Int) {
        setViewControllers(controllers, animated: false)
        self.selectedIndex = min(selectedIndex, controllers.count - 1)
    }
}

extension MainTabbarViewController: UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        guard !isChangingTab else { return false }
        guard viewController !== selectedViewController else { return shouldReselect(selectedViewController) }
        guard let origin = selectedViewController,
              let top = (origin as? UINavigationController)?.topViewController,
              let form = top as? FormDepartureParticipant else { return true }
        confirmDeparture(of: form, from: origin, requiring: viewController) { [weak self] in
            self?.selectedViewController = viewController
        }
        return false
    }

    private func shouldReselect(_ origin: UIViewController?) -> Bool {
        guard let nav = origin as? UINavigationController, nav.viewControllers.count > 1,
              let top = nav.topViewController,
              let form = top as? FormDepartureParticipant else { return true }
        // Незавершённый ввод IME попадает в модель только после resign first responder.
        form.finishEditing()
        guard form.hasUnsavedChanges else { return true }
        confirmDeparture(of: form, from: nav, requiring: nav) {
            nav.popToRootViewController(animated: true)
        }
        return false
    }

    /// Запрашивает подтверждение ухода с формы и выполняет `action`, только если после ожидания
    /// сессия и вкладка не изменились, а `target` всё ещё в `viewControllers`.
    private func confirmDeparture(
        of form: FormDepartureParticipant,
        from origin: UIViewController,
        requiring target: UIViewController,
        then action: @escaping () -> Void
    ) {
        guard !form.isSavingDraft else { return }
        let stamp = session.capture()
        isChangingTab = true
        Task { [weak self] in
            guard let self else { return }
            defer { self.isChangingTab = false }
            guard await form.requestDeparture(), self.session.isCurrent(stamp),
                  self.selectedViewController === origin,
                  self.viewControllers?.contains(where: { $0 === target }) == true else { return }
            action()
        }
    }
}
