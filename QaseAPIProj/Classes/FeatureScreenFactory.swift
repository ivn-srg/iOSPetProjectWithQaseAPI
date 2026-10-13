import SwiftUI
import UIKit

@MainActor
final class FeatureScreenFactory {
    private let network: NetworkManager
    private let cache: AppCache
    private let session: SessionContext
    private let repository: HomeReading & RepositoryReading & WorkReading
    private let selection: SelectedProjectStore
    private let catalogLoader: SuiteCatalogLoading
    private let auth: AuthServicing
    private let bundle: Bundle
    private let preferences: AppSettingsStore
    private let prepareForChange: @MainActor () async -> Bool
    private let reportFailure: (String) -> Void

    init(
        network: NetworkManager,
        cache: AppCache,
        session: SessionContext,
        repository: HomeReading & RepositoryReading & WorkReading,
        selection: SelectedProjectStore,
        catalogLoader: SuiteCatalogLoading,
        auth: AuthServicing,
        preferences: AppSettingsStore,
        bundle: Bundle,
        prepareForChange: @escaping @MainActor () async -> Bool,
        reportFailure: @escaping (String) -> Void
    ) {
        self.network = network
        self.cache = cache
        self.session = session
        self.repository = repository
        self.selection = selection
        self.catalogLoader = catalogLoader
        self.auth = auth
        self.bundle = bundle
        self.preferences = preferences
        self.prepareForChange = prepareForChange
        self.reportFailure = reportFailure
    }

    private var cacheFailure: () -> Void {
        { [reportFailure] in
            reportFailure("Could not update cached data. Fresh data remains available.".localized)
        }
    }

    func makeRoots(router: ApplicationRouting) -> [UIViewController] {
        let homeModel = HomeViewModel(
            repository: repository,
            cache: cache,
            selection: selection,
            session: session
        )
        let home = navigation(
            HomeViewController(viewModel: homeModel, router: router),
            title: "Home",
            symbol: .houseFill,
            tab: .home
        )
        let repositoryRoot: UIViewController
        let workRoot: UIViewController
        if let project = selection.selectedProject {
            let entities = makeRepository(projectCode: project.code, router: router)
            repositoryRoot = entities
            workRoot = host(
                WorkHomeView(
                    selection: selection,
                    onRuns: { [weak router] in router?.showRuns() },
                    onDefects: { [weak router] in router?.showDefects() },
                    onSelectProject: { [weak router] in router?.selectProject($0) },
                    onManageProjects: { [weak router] in router?.manageProjects() }
                ),
                title: "Work".localized
            )
        } else {
            repositoryRoot = emptyRoot(router: router)
            workRoot = emptyRoot(router: router)
        }
        let repositoryNav = navigation(
            repositoryRoot,
            title: "Repository",
            symbol: .internaldriveFill,
            tab: .repository
        )
        let work = navigation(workRoot, title: "Work", symbol: .playCircle, tab: .work)
        let settingsModel = SettingsViewModel(
            preferences: preferences,
            auth: auth,
            cache: cache,
            session: session,
            bundle: bundle
        )
        let settings = navigation(
            SettingsViewController(
                model: settingsModel,
                onFailure: reportFailure,
                navigate: { [weak self, weak settingsModel] route, presenter in
                    guard let self, let settingsModel else { return }
                    self.showSettings(route, from: presenter, model: settingsModel)
                },
                makeTokenController: { [weak self] in
                    guard let self else { return UIViewController() }
                    return self.makeTokenController()
                },
                prepareForChange: prepareForChange
            ),
            title: "Settings",
            symbol: .gearshapeFill,
            tab: .settings
        )
        return [home, repositoryNav, work, settings]
    }

    private func navigation(
        _ root: UIViewController,
        title: String,
        symbol: AppSymbol,
        tab: AppTab
    ) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.tintColor = AppTheme.Palette.accent
        nav.navigationBar.prefersLargeTitles = true
        root.title = title.localized
        root.navigationItem.largeTitleDisplayMode = tab == .home ? .never : .always
        nav.tabBarItem = UITabBarItem(
            title: title.localized,
            image: UIImage(symbol: symbol),
            tag: tab.rawValue
        )
        nav.tabBarItem.accessibilityIdentifier = tab.accessibilityID.identifier
        return nav
    }

    private func host<V: View>(_ view: V, title: String, largeTitle: Bool = false) -> UIViewController {
        let controller = UIHostingController(rootView: view)
        controller.title = title
        controller.navigationItem.largeTitleDisplayMode = largeTitle ? .always : .never
        return controller
    }

    private func emptyRoot(router: ApplicationRouting) -> UIViewController {
        host(ScrollView {
            VStack(spacing: AppTheme.Space.section) {
                Image(symbol: .folder).font(.largeTitle)
                Text("No projects".localized).font(.headline)
                Text("Choose or create a project to get started.".localized).foregroundStyle(.secondary)
                Button("Manage projects".localized) { [weak router] in router?.manageProjects() }
                    .frame(minHeight: AppTheme.Size.touch)
                    .accessibilityIdentifier(AccessibilityID.projectManage.identifier)
            }.padding(AppTheme.Space.screen).frame(maxWidth: .infinity)
        }.background(Color(uiColor: AppTheme.Palette.canvas)), title: "Choose project".localized)
    }

    func makeRepository(
        projectCode: String,
        suite: TestListEntity? = nil, router: RepositoryRouting
    ) -> RepositoryViewController {
        let parent = suite.flatMap { ParentSuite(id: $0.id, title: $0.title, codeOfProject: projectCode) }
        return RepositoryViewController(
            model: TestEntitiesViewModel(
                projectCode: projectCode,
                parentSuite: parent,
                network: network,
                repository: repository,
                catalogLoader: catalogLoader,
                dao: cache,
                session: session,
                onCacheFailure: cacheFailure
            ),
            selection: selection,
            router: router
        )
    }

    private func makePickerModel(
        projectCode: String,
        selectedID: Int? = nil,
        projectTitle: String?
    ) -> SuitePickerViewModel {
        SuitePickerViewModel(
            projectCode: projectCode,
            selectedID: selectedID,
            projectTitle: projectTitle,
            loader: catalogLoader,
            dao: cache,
            session: session
        )
    }

    private func makeParentPicker(
        projectCode: String,
        selectedID: Int?,
        projectTitle: String?,
        onSelect: @escaping (SuitePickerViewModel, Int?) -> Void
    )
        -> UIViewController {
        let model = makePickerModel(
            projectCode: projectCode,
            selectedID: selectedID,
            projectTitle: projectTitle
        )
        let picker = SuitePickerViewController(viewModel: model) { selected in onSelect(model, selected) }
        let navigation = UINavigationController(rootViewController: picker)
        navigation.navigationBar.tintColor = AppTheme.Palette.accent
        navigation.modalPresentationStyle = .pageSheet
        return navigation
    }

    private func makeRunListModel(projectCode: String) -> PagedReadViewModel<RunReadDTO> {
        PagedReadViewModel(session: session, cached: { [repository] _ in
            repository.hasCachedRuns(projectCode: projectCode) ? repository
                .cachedRuns(projectCode: projectCode) : nil
        }, fetch: { [repository] _, offset in try await repository.runs(
            projectCode: projectCode,
            offset: offset
        ) })
    }

    private func makeDefectListModel(projectCode: String) -> PagedReadViewModel<DefectReadDTO> {
        PagedReadViewModel(session: session, cached: { [repository] _ in
            repository.hasCachedDefects(projectCode: projectCode) ? repository
                .cachedDefects(projectCode: projectCode) : nil
        }, fetch: { [repository] _, offset in try await repository.defects(
            projectCode: projectCode,
            offset: offset
        ) })
    }

    private func makeRunDetailModel(projectCode: String, id: Int) -> ReadDetailViewModel<RunReadDTO> {
        ReadDetailViewModel(
            session: session,
            cached: { [repository] in repository.cachedRun(projectCode: projectCode, id: id) },
            failureMessage: "Could not load run".localized,
            fetch: { [repository] in try await repository.run(projectCode: projectCode, id: id) }
        )
    }

    private func makeDefectDetailModel(projectCode: String, id: Int) -> ReadDetailViewModel<DefectReadDTO> {
        ReadDetailViewModel(
            session: session,
            cached: { [repository] in repository.cachedDefect(projectCode: projectCode, id: id) },
            failureMessage: "Could not load defect".localized,
            fetch: { [repository] in try await repository.defect(projectCode: projectCode, id: id) }
        )
    }

    private func makeTokenController() -> UIViewController {
        let model = TokenReplacementViewModel(auth: auth, prepareForChange: prepareForChange)
        let controller = TokenReplacementController(model: model)
        let navigation = UINavigationController(rootViewController: controller)
        navigation.navigationBar.tintColor = AppTheme.Palette.accent
        navigation.modalPresentationStyle = .fullScreen
        model.onClose = { [weak navigation] in navigation?.dismiss(animated: true) }
        return navigation
    }

    func makeProjectsController(onCreateProject: @escaping () -> Void) -> ProjectsViewController {
        ProjectsViewController(
            viewModel: ProjectsViewModel(
                network: network,
                dao: cache,
                session: session,
                onCacheFailure: cacheFailure
            ),
            onCreateProject: onCreateProject
        )
    }

    func makeProjectCreationController(onCreated: @escaping () -> Void) -> UIViewController {
        let model = CreatingProjectViewModel(network: network, session: session)
        let controller = CreatingProjectViewController(viewModel: model, createdCallback: onCreated)
        let navigation = UINavigationController(rootViewController: controller)
        navigation.navigationBar.tintColor = AppTheme.Palette.accent
        navigation.modalPresentationStyle = .fullScreen
        return navigation
    }

    func makeEntityCreationController(
        location: RepositoryLocation,
        projectTitle: String?,
        onCreated: @escaping () -> Void
    ) -> UIViewController {
        let model = EntityCreationViewModel(
            projectCode: location.projectCode,
            parentSuiteId: location.suiteID,
            network: network,
            session: session
        )
        let controller = CreateSuiteOrCaseViewController(
            viewModel: model,
            parentCatalog: makePickerModel(
                projectCode: location.projectCode,
                projectTitle: projectTitle
            ),
            makeParentPicker: { [weak self] id, title, onSelect in
                self?.makeParentPicker(
                    projectCode: location.projectCode,
                    selectedID: id,
                    projectTitle: title,
                    onSelect: onSelect
                ) ?? UIViewController()
            },
            projectTitle: projectTitle,
            onEntityCreated: onCreated
        )
        let navigation = UINavigationController(rootViewController: controller)
        navigation.navigationBar.tintColor = AppTheme.Palette.accent
        navigation.modalPresentationStyle = .fullScreen
        return navigation
    }

    func makeCaseController(reference: TestCaseReference, projectTitle: String?) -> TestCaseViewController {
        let model = TestCaseEditorViewModel(
            reference: reference,
            network: network,
            dao: cache,
            session: session,
            onCacheFailure: cacheFailure
        )
        let controller = TestCaseViewController(
            viewModel: model,
            form: GeneralDetailCaseViewController(vm: model, projectTitle: projectTitle),
            session: session
        )
        controller.navigationItem.largeTitleDisplayMode = .never
        return controller
    }

    func makeRunsController(project: ProjectSummary, onRun: @escaping (Int) -> Void) -> UIViewController {
        host(
            RunListView(
                projectCode: project.code,
                selection: selection,
                model: makeRunListModel(projectCode: project.code),
                onRun: onRun
            ),
            title: "Runs".localized,
            largeTitle: true
        )
    }

    func makeRunController(
        projectCode: String,
        id: Int,
        onCase: @escaping (TestCaseReference) -> Void
    ) -> UIViewController {
        host(
            RunDetailView(projectCode: projectCode, model: makeRunDetailModel(
                projectCode: projectCode,
                id: id
            ), onCase: onCase),
            title: "Run".localized
        )
    }

    func makeDefectsController(
        project: ProjectSummary,
        onDefect: @escaping (Int) -> Void
    ) -> UIViewController {
        host(
            DefectListView(
                projectCode: project.code,
                selection: selection,
                model: makeDefectListModel(projectCode: project.code),
                onDefect: onDefect
            ),
            title: "Defects".localized,
            largeTitle: true
        )
    }

    func makeDefectController(projectCode: String, id: Int) -> UIViewController {
        host(
            DefectDetailView(projectCode: projectCode, model: makeDefectDetailModel(
                projectCode: projectCode,
                id: id
            )),
            title: "Defect".localized
        )
    }

    private func showSettings(
        _ route: SettingsRoute,
        from presenter: UIViewController,
        model: SettingsViewModel
    ) {
        let controller: UIViewController
        switch route {
        case .appearance:
            controller = settingsPage(
                AppearanceSettingsView(preferences: model.preferences),
                title: "Theme".localized
            )
        case .cache:
            controller = settingsPage(CacheSettingsView(model: model), title: "Manage cache".localized)
        case .about:
            controller = settingsPage(AboutSettingsView(model: model), title: "About application".localized)
        default: return
        }
        presenter.navigationController?.pushViewController(controller, animated: true)
    }

    private func settingsPage<V: View>(_ view: V, title: String) -> UIViewController {
        let controller = UIHostingController(rootView: view)
        controller.title = title
        controller.navigationItem.largeTitleDisplayMode = .never
        return controller
    }

}
