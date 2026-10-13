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
        guard viewController !== selectedViewController else { return true }
        guard !isChangingTab else { return false }
        guard let origin = selectedViewController,
              let top = (origin as? UINavigationController)?.topViewController,
              let form = top as? FormDepartureParticipant else { return true }
        guard !form.isSavingDraft else { return false }
        let stamp = session.capture()
        isChangingTab = true
        Task { [weak self] in
            guard let self else { return }
            defer { self.isChangingTab = false }
            guard await form.requestDeparture(), self.session.isCurrent(stamp),
                  self.selectedViewController === origin,
                  self.viewControllers?.contains(where: { $0 === viewController }) == true else { return }
            self.selectedViewController = viewController
        }
        return false
    }
}
