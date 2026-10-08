import SwiftUI
import UIKit

final class MainTabbarViewController: UITabBarController, RepositoryRouting {
    private let session = SessionContext.shared
    private let cache = RealmManager.shared
    private lazy var repository = HomeRepository(network: ApiServiceConfiguration.shared.apiService, dao: cache, session: session)
    private lazy var selection = SelectedProjectStore(repository: repository, cache: cache, session: session)
    private lazy var coordinator = ApplicationProjectCoordinator(store: selection, shell: self)
    private lazy var homeRouter = WeakHomeRouter(target: self)
    private var loadTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = AppTheme.Palette.accent
        tabBar.unselectedItemTintColor = AppTheme.Palette.secondaryText
        selection.onSelectionRequested = { [weak self] project in
            guard let self else { return false }
            return await self.coordinator.choose(project)
        }
        selection.onSelectionChanged = { [weak self] in self?.rebuildRoots() }
        rebuildRoots()
        loadTask = Task { [weak self] in await self?.selection.load() }
    }

    deinit { loadTask?.cancel() }

    private func rebuildRoots() {
        let active = viewControllers == nil ? 0 : selectedIndex
        if presentedViewController != nil { dismiss(animated: false) }
        let homeModel = HomeViewModel(repository: repository, cache: cache, selection: selection, session: session)
        let home = navigation(HomeViewController(viewModel: homeModel, router: homeRouter), title: "Home", symbol: "house.fill", tag: 0)
        let repositoryRoot: UIViewController
        let workRoot: UIViewController
        if let project = selection.selectedProject {
            let entities = makeRepository(projectCode: project.code)
            repositoryRoot = entities
            workRoot = host(WorkHomeView(selection: selection,
                onRuns: { [weak self] in self?.showRuns() },
                onDefects: { [weak self] in self?.showDefects() },
                onSelectProject: { [weak self] in self?.selectProject($0) },
                onManageProjects: { [weak self] in self?.manageProjects() }), title: "Work".localized)
        } else {
            repositoryRoot = emptyRoot()
            workRoot = emptyRoot()
        }
        let repositoryNav = navigation(repositoryRoot, title: "Repository", symbol: "internaldrive.fill", tag: 1)
        let work = navigation(workRoot, title: "Work", symbol: "play.circle", tag: 2)
        let settings = navigation(SettingsViewController(prepareForChange: { [weak self] in
            guard let self else { return false }
            return await self.coordinator.prepareForChange(switchingProject: false)
        }), title: "Settings", symbol: "gearshape.fill", tag: 3)
        setViewControllers([home, repositoryNav, work, settings], animated: false)
        selectedIndex = min(active, 3)
    }

    private func navigation(_ root: UIViewController, title: String, symbol: String, tag: Int) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.tintColor = AppTheme.Palette.accent
        nav.navigationBar.prefersLargeTitles = true
        root.title = title.localized
        root.navigationItem.largeTitleDisplayMode = tag == 0 ? .never : .always
        nav.tabBarItem = UITabBarItem(title: title.localized, image: UIImage(systemName: symbol), tag: tag)
        nav.tabBarItem.accessibilityIdentifier = "tab." + title.lowercased()
        return nav
    }

    private func emptyRoot() -> UIViewController {
        host(ScrollView {
            VStack(spacing: AppTheme.Space.section) {
                Image(systemName: "folder").font(.largeTitle)
                Text("No projects".localized).font(.headline)
                Text("Choose or create a project to get started.".localized).foregroundStyle(.secondary)
                Button("Manage projects".localized) { [weak self] in self?.manageProjects() }
                    .frame(minHeight: AppTheme.Size.touch)
                    .accessibilityIdentifier("project.manage")
            }.padding(AppTheme.Space.screen).frame(maxWidth: .infinity)
        }.background(Color(uiColor: AppTheme.Palette.canvas)), title: "Choose project".localized)
    }

    private func host<V: View>(_ view: V, title: String, largeTitle: Bool = false) -> UIViewController {
        let controller = UIHostingController(rootView: view)
        controller.title = title
        controller.navigationItem.largeTitleDisplayMode = largeTitle ? .always : .never
        return controller
    }

    func selectProject(_ project: ProjectSummary) {
        guard selection.projects.contains(where: { $0.code == project.code }) else { return }
        Task { _ = await coordinator.choose(project) }
    }

    func manageProjects() {
        let controller = ProjectsViewController()
        controller.onSelectProject = { [weak self] project in
            guard let self else { return }
            let summary = self.selection.projects.first(where: { $0.code == project.code })
                ?? ProjectSummary(title: project.title, code: project.code, description: project.description, descriptionWasProvided: project.descriptionWasProvided)
            Task { if await self.coordinator.choose(summary) { self.dismiss(animated: true) } }
        }
        controller.beforeDeleteProject = { [weak self] project in
            guard let self else { return false }
            if project.code != self.selection.selectedProject?.code { return true }
            return await self.coordinator.prepareForChange()
        }
        controller.onProjectDeleted = { [weak self] code in
            Task { await self?.selection.didDeleteProject(code: code) }
        }
        controller.onProjectsChanged = { [weak self] in
            Task { await self?.selection.load() }
        }
        let nav = UINavigationController(rootViewController: controller)
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak nav] _ in nav?.dismiss(animated: true) })
        present(nav, animated: true)
    }

    private var projectCode: String? { selection.selectedProject?.code }
    private func push(_ controller: UIViewController, tab: Int? = nil) {
        if let tab { selectedIndex = tab }
        (selectedViewController as? UINavigationController)?.pushViewController(controller, animated: true)
    }

    private func makeRepository(projectCode: String, suite: TestListEntity? = nil) -> RepositoryViewController {
        let parent = suite.flatMap { ParentSuite(id: $0.id, title: $0.title, codeOfProject: projectCode) }
        return RepositoryViewController(model: TestEntitiesViewModel(projectCode: projectCode, parentSuite: parent,
            network: ApiServiceConfiguration.shared.apiService, dao: cache, session: session), selection: selection, router: homeRouter)
    }

    func showCases(search: Bool) {
        guard let code = projectCode, let nav = viewControllers?[1] as? UINavigationController else { manageProjects(); return }
        let stamp = session.capture()
        Task {
            guard await coordinator.prepareForChange(in: nav, switchingProject: false), session.isCurrent(stamp), projectCode == code else { return }
            selectedIndex = 1
            nav.popToRootViewController(animated: false)
            if let root = nav.viewControllers.first as? RepositoryViewController {
                root.model.query = ""
                root.model.requestSearchFocus = search
            }
        }
    }

    func showSuites() { showCases(search: false) }

    func openSuite(_ suite: TestListEntity, from model: TestEntitiesViewModel) {
        guard model.projectCode == projectCode else { return }
        push(makeRepository(projectCode: model.projectCode, suite: suite), tab: 1)
    }

    func openAncestor(_ breadcrumb: RepositoryBreadcrumb, from model: TestEntitiesViewModel) {
        guard model.projectCode == projectCode, breadcrumb.id != model.location.suiteID,
              let nav = viewControllers?[1] as? UINavigationController else { return }
        Task {
            guard await coordinator.prepareForChange(in: nav, switchingProject: false), model.projectCode == projectCode else { return }
            if let target = nav.viewControllers.compactMap({ $0 as? RepositoryViewController }).first(where: { $0.model.location.suiteID == breadcrumb.id }) {
                nav.popToViewController(target, animated: true)
            } else if let id = breadcrumb.id, let suite = model.catalog.first(where: { $0.id == id }) {
                var controllers = nav.viewControllers
                controllers.removeLast()
                controllers.append(makeRepository(projectCode: model.projectCode, suite: suite))
                nav.setViewControllers(controllers, animated: true)
            }
        }
    }

    func repositoryBack() { (selectedViewController as? UINavigationController)?.popViewController(animated: true) }

    func createEntity(in location: RepositoryLocation) {
        guard location.projectCode == projectCode else { return }
        let controller = CreateSuiteOrCaseViewController(viewModel: .init(projectCode: location.projectCode, parentSuiteId: location.suiteID))
        controller.modalPresentationStyle = .fullScreen
        (selectedViewController as? UINavigationController)?.topViewController?.present(controller, animated: true)
    }

    func showRuns() {
        guard let project = selection.selectedProject else { manageProjects(); return }
        push(host(RunListView(projectCode: project.code, selection: selection, repository: repository, session: session,
            onRun: { [weak self] in self?.showRun(id: $0) }), title: "Runs".localized, largeTitle: true), tab: 2)
    }

    func showRun(id: Int) {
        guard let projectCode else { return }
        push(host(RunDetailView(projectCode: projectCode, runID: id, repository: repository, session: session,
            onCase: { [weak self] in self?.showCase(reference: $0) }), title: "Run".localized), tab: 2)
    }

    func showDefects() {
        guard let project = selection.selectedProject else { manageProjects(); return }
        push(host(DefectListView(projectCode: project.code, selection: selection, repository: repository, session: session,
            onDefect: { [weak self] id in
                guard let self else { return }
                self.push(self.host(DefectDetailView(projectCode: project.code, defectID: id, repository: self.repository, session: self.session), title: "Defect".localized))
            }), title: "Defects".localized, largeTitle: true), tab: 2)
    }

    func showCase(reference: TestCaseReference) {
        let controller = TestCaseViewController(reference: reference)
        controller.navigationItem.largeTitleDisplayMode = .never
        push(controller)
    }
}
