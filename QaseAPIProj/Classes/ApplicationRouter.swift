import UIKit

@MainActor
protocol ApplicationNavigationHost: AnyObject {
    var navigationRoot: UIViewController { get }
    var viewControllers: [UIViewController]? { get }
    var selectedViewController: UIViewController? { get set }
    var selectedIndex: Int { get set }
    func replaceRoots(_ controllers: [UIViewController], selectedIndex: Int)
}

@MainActor
protocol ApplicationRouting: RepositoryRouting {
    func start()
}

@MainActor
final class ApplicationRouter: ApplicationRouting {
    private let factory: FeatureScreenFactory
    private let selection: SelectedProjectStore
    private let coordinator: ApplicationProjectCoordinator
    private let session: SessionContext
    private weak var shell: ApplicationNavigationHost?
    private var loadTask: Task<Void, Never>?

    init(
        factory: FeatureScreenFactory,
        selection: SelectedProjectStore,
        coordinator: ApplicationProjectCoordinator,
        session: SessionContext
    ) {
        self.factory = factory
        self.selection = selection
        self.coordinator = coordinator
        self.session = session
    }

    private var viewControllers: [UIViewController]? { shell?.viewControllers }
    private var selectedViewController: UIViewController? { shell?.selectedViewController }
    private var selectedIndex: Int {
        get { shell?.selectedIndex ?? AppTab.home.rawValue }
        set { shell?.selectedIndex = newValue }
    }

    private var projectCode: String? { selection.selectedProject?.code }
    deinit { loadTask?.cancel() }

    func attach(_ shell: ApplicationNavigationHost) {
        self.shell = shell
        coordinator.attach(shell)
    }

    func start() {
        selection.onSelectionRequested = { [weak self] project in
            guard let self else { return false }
            return await self.coordinator.choose(project)
        }
        selection.onSelectionChanged = { [weak self] in self?.rebuildRoots() }
        loadTask = Task { [weak self] in await self?.selection.load() }
    }

    private func rebuildRoots() {
        guard let shell else { return }
        let active = shell.selectedIndex
        shell.navigationRoot.dismiss(animated: false)
        shell.replaceRoots(factory.makeRoots(router: self), selectedIndex: active)
    }

    private func present(_ controller: UIViewController, animated: Bool) {
        shell?.navigationRoot.present(controller, animated: animated)
    }

    private func dismiss(animated: Bool) {
        shell?.navigationRoot.dismiss(animated: animated)
    }

    private func push(_ controller: UIViewController, tab: AppTab? = nil) {
        if let tab { selectedIndex = tab.rawValue }
        (selectedViewController as? UINavigationController)?.pushViewController(controller, animated: true)
    }

    func selectProject(_ project: ProjectSummary) {
        guard selection.projects.contains(where: { $0.code == project.code }) else { return }
        Task { _ = await coordinator.choose(project) }
    }

    func showCases(search: Bool) {
        guard let code = projectCode,
              let nav = viewControllers?[AppTab.repository.rawValue] as? UINavigationController
        else {
            manageProjects()
            return
        }
        let stamp = session.capture()
        Task {
            guard await coordinator.prepareForChange(in: nav, switchingProject: false),
                  session.isCurrent(stamp), projectCode == code else { return }
            selectedIndex = AppTab.repository.rawValue
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
        push(
            factory.makeRepository(projectCode: model.projectCode, suite: suite, router: self),
            tab: .repository
        )
    }

    func openAncestor(_ breadcrumb: RepositoryBreadcrumb, from model: TestEntitiesViewModel) {
        guard model.projectCode == projectCode, breadcrumb.id != model.location.suiteID,
              let nav = viewControllers?[AppTab.repository.rawValue] as? UINavigationController
        else { return }
        Task {
            guard await coordinator.prepareForChange(in: nav, switchingProject: false),
                  model.projectCode == projectCode else { return }
            if let target = nav.viewControllers.compactMap({ $0 as? RepositoryViewController })
                .first(where: { $0.model.location.suiteID == breadcrumb.id }) {
                nav.popToViewController(target, animated: true)
            } else if let id = breadcrumb.id, let suite = model.catalog.first(where: { $0.id == id }) {
                var controllers = nav.viewControllers
                controllers.removeLast()
                controllers.append(factory.makeRepository(
                    projectCode: model.projectCode,
                    suite: suite,
                    router: self
                ))
                nav.setViewControllers(controllers, animated: true)
            }
        }
    }

    func repositoryBack() {
        (selectedViewController as? UINavigationController)?.popViewController(animated: true) }

    func manageProjects() {
        let controller = factory
            .makeProjectsController(onCreateProject: { [weak self] in self?.createProject() })
        controller.onSelectProject = { [weak self] project in
            guard let self else { return }
            let summary = self.selection.projects.first(where: { $0.code == project.code })
                ?? ProjectSummary(
                    title: project.title,
                    code: project.code,
                    description: project.description,
                    descriptionWasProvided: project.descriptionWasProvided
                )
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
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak nav] _ in nav?.dismiss(animated: true) }
        )
        present(nav, animated: true)
    }

    func createEntity(in location: RepositoryLocation) {
        guard location.projectCode == projectCode,
              let presenter = (selectedViewController as? UINavigationController)?.topViewController
        else { return }
        let source = presenter as? RepositoryViewController
        let controller = factory.makeEntityCreationController(
            location: location,
            projectTitle: selection.selectedProject?.title,
            onCreated: { [weak source] in Task { await source?.model.reload() } }
        )
        presenter.present(controller, animated: true)
    }

    private func createProject() {
        let controller = factory.makeProjectCreationController(
            onCreated: { [weak self] in
                Task { await self?.selection.load() }
            }
        )
        let presenter = shell?.navigationRoot.presentedViewController ?? shell?.navigationRoot
        presenter?.present(controller, animated: true)
    }

    func showCase(reference: TestCaseReference) {
        let projectTitle = selection.selectedProject?.code == reference.projectCode ? selection
            .selectedProject?.title : nil
        push(factory.makeCaseController(reference: reference, projectTitle: projectTitle))
    }

    func showRuns() {
        guard let project = selection.selectedProject else {
            manageProjects()
            return
        }
        push(
            factory.makeRunsController(project: project, onRun: { [weak self] in self?.showRun(id: $0) }),
            tab: .work
        )
    }

    func showRun(id: Int) {
        guard let projectCode else { return }
        push(
            factory.makeRunController(
                projectCode: projectCode,
                id: id,
                onCase: { [weak self] in
                    self?.showCase(reference: $0)
                }
            ),
            tab: .work
        )
    }

    func showDefects() {
        guard let project = selection.selectedProject else {
            manageProjects()
            return
        }
        push(factory.makeDefectsController(
            project: project,
            onDefect: { [weak self] id in
                guard let self, self.projectCode == project.code else { return }
                self.push(self.factory.makeDefectController(projectCode: project.code, id: id))
            }
        ), tab: .work)
    }
}
