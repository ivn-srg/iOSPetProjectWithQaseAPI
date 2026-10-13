import Foundation

enum AccessibilityID: Hashable, Sendable {
    case addNewProjectRBB
    case authButton
    case authDemo
    case authMessage
    case authScreen
    case authTokenVisibility
    case caseStepsEmpty
    case formBack
    case formClose
    case formCreate
    case formEntityType
    case formSave
    case homeScreen
    case homeOpenRun
    case homeSearchCases
    case homeAllCases
    case inputTextField
    case logoImg
    case navigationBar
    case projectManage
    case projectPicker
    case projectsTableView
    case repositoryCounts
    case repositoryCreate
    case repositoryLevel
    case repositorySearch
    case repositoryScreen
    case settingsAbout
    case settingsAppearance
    case settingsCache
    case settingsCacheClear
    case settingsLanguage
    case settingsLogout
    case settingsToken
    case settingsTokenCancel
    case settingsTokenInput
    case settingsTokenSave
    case settingsScreen
    case suitePickerClose
    case suitePickerList
    case suitePickerRetry
    case suitePickerRoot
    case suitePickerSearch
    case suitePickerStatus
    case tabHome
    case tabRepository
    case tabSettings
    case tabWork
    case workLoading
    case workProject
    case field(Field)
    case breadcrumb(Int?)
    case repositoryCase(Int)
    case repositorySuite(Int)
    case suitePickerSuite(Int)
    case recent(project: String, caseID: Int)
    case entity(project: String, id: Int)
    case step(String)
    case appearance(Appearance)

    enum Field: String, CaseIterable, Sendable {
        case title = "Title"
        case description = "Description"
        case precondition = "Precondition"
        case postcondition = "Postcondition"
        case code = "Project code"
        case parentSuite = "Parent suite"
        case severity = "Severity"
        case status = "Status"
        case priority = "Priority"
        case behavior = "Behavior"
        case type = "Type"
        case layer = "Layer"
        case isFlaky = "Is Flaky"
        case automation = "Automation status"
    }

    enum Appearance: String, CaseIterable, Sendable { case system, light, dark }

    var identifier: String {
        switch self {
        case .addNewProjectRBB: return "addNewProjectRBB"
        case .authButton: return "authButton"
        case .authDemo: return "auth.demo"
        case .authMessage: return "auth.message"
        case .authScreen: return "auth.screen"
        case .authTokenVisibility: return "auth.tokenVisibility"
        case .caseStepsEmpty: return "case.steps.empty"
        case .formBack: return "form.back"
        case .formClose: return "form.close"
        case .formCreate: return "form.create"
        case .formEntityType: return "form.entityType"
        case .formSave: return "form.save"
        case .homeAllCases: return "home.allCases"
        case .homeSearchCases: return "home.searchCases"
        case .homeOpenRun: return "home.openRun"
        case .homeScreen: return "homeScreen"
        case .inputTextField: return "inputTextField"
        case .logoImg: return "logoImg"
        case .navigationBar: return "navigationBar"
        case .projectManage: return "project.manage"
        case .projectPicker: return "project.picker"
        case .projectsTableView: return "projectsTableView"
        case .repositoryCounts: return "repository.counts"
        case .repositoryCreate: return "repository.create"
        case .repositoryLevel: return "repository.level"
        case .repositorySearch: return "repository.search"
        case .repositoryScreen: return "repositoryScreen"
        case .settingsAbout: return "settings.about"
        case .settingsAppearance: return "settings.appearance"
        case .settingsCache: return "settings.cache"
        case .settingsCacheClear: return "settings.cache.clear"
        case .settingsLanguage: return "settings.language"
        case .settingsLogout: return "settings.logout"
        case .settingsToken: return "settings.token"
        case .settingsTokenCancel: return "settings.token.cancel"
        case .settingsTokenInput: return "settings.token.input"
        case .settingsTokenSave: return "settings.token.save"
        case .settingsScreen: return "settingsScreen"
        case .suitePickerClose: return "suitePicker.close"
        case .suitePickerList: return "suitePicker.list"
        case .suitePickerRetry: return "suitePicker.retry"
        case .suitePickerRoot: return "suitePicker.root"
        case .suitePickerSearch: return "suitePicker.search"
        case .suitePickerStatus: return "suitePicker.status"
        case .tabHome: return "tab.home"
        case .tabRepository: return "tab.repository"
        case .tabSettings: return "tab.settings"
        case .tabWork: return "tab.work"
        case .workLoading: return "work.loading"
        case .workProject: return "work.project"
        case .field(let field): return "field." + field.rawValue
        case .breadcrumb(let id): return "repository.breadcrumb." + (id.map(String.init) ?? "root")
        case .repositoryCase(let id): return "repository.case.\(id)"
        case .repositorySuite(let id): return "repository.suite.\(id)"
        case .suitePickerSuite(let id): return "suitePicker.suite.\(id)"
        case .recent(let project, let id): return "recent.\(project)-\(id)"
        case .entity(let project, let id): return "\(project)-\(id)"
        case .step(let path): return "case.step." + path
        case .appearance(let appearance): return "settings.appearance." + appearance.rawValue
        }
    }
}
