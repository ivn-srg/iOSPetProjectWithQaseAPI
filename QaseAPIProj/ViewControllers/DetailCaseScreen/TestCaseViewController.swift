import SnapKit
import UIKit

final class TestCaseViewController: UIViewController {
    let viewModel: DetailTabbarControllerViewModel
    private let projectTitle: String?
    private var task: Task<Void, Never>?
    private var isFetching = false
    private var isSubmitting = false
    private var isConfirmingDeparture = false
    private var previousTabVisibility: Bool?
    private weak var previousPopDelegate: UIGestureRecognizerDelegate?
    private lazy var form = GeneralDetailCaseViewController(vm: viewModel, projectTitle: projectTitle)
    private lazy var saveItem = UIBarButtonItem(
        title: "Save".localized,
        style: .plain,
        target: self,
        action: #selector(saveChanges)
    )
    private lazy var backItem = UIBarButtonItem(
        image: UIImage(systemName: "chevron.left"),
        style: .plain,
        target: self,
        action: #selector(goBack)
    )
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(reference: TestCaseReference, projectTitle: String? = nil) {
        viewModel = DetailTabbarControllerViewModel(reference: reference)
        self.projectTitle = projectTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(viewModel.reference.projectCode)-\(viewModel.caseId)"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = backItem
        backItem.accessibilityLabel = "Back".localized
        backItem.accessibilityIdentifier = "form.back"
        saveItem.accessibilityIdentifier = "form.save"
        spinner.color = AppTheme.Palette.accent
        spinner.accessibilityLabel = "Saving".localized
        view.backgroundColor = AppTheme.Palette.canvas
        addChild(form)
        view.addSubview(form.view)
        form.view.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        form.didMove(toParent: self)
        form.onKeyboardVisibilityChanged = { [weak self] visible in self?.setKeyboardVisible(visible) }
        viewModel.delegate = self
        viewModel.checkDataChanged = { [weak self] in self?.checkConditionAndToggleRightBarButton() }
        checkConditionAndToggleRightBarButton()
        fetchCase()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let gesture = navigationController?.interactivePopGestureRecognizer {
            if gesture.delegate !== self {
                previousPopDelegate = gesture.delegate
                gesture.delegate = self
            }
            gesture.isEnabled = (navigationController?.viewControllers.count ?? 0) > 1
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        form.finishEditing()
        view.endEditing(true)
        restoreTabVisibility()
        if let gesture = navigationController?.interactivePopGestureRecognizer, gesture.delegate === self {
            gesture.delegate = previousPopDelegate
        }
    }

    deinit { task?.cancel() }

    private func setKeyboardVisible(_ visible: Bool) {
        if visible {
            guard navigationController?.topViewController === self, view.window != nil else { return }
            if previousTabVisibility == nil { previousTabVisibility = tabBarController?.isTabBarHidden }
            tabBarController?.setTabBarHidden(true, animated: false)
        } else {
            restoreTabVisibility()
        }
    }

    private func restoreTabVisibility() {
        if let previousTabVisibility { tabBarController?.setTabBarHidden(
            previousTabVisibility,
            animated: false
        ) }
        previousTabVisibility = nil
    }

    private func fetchCase() {
        guard !isFetching, !isSavingDraft, viewModel.isSessionCurrent else { return }
        isFetching = true
        form.clearError()
        checkConditionAndToggleRightBarButton()
        task = Task { [weak self] in
            guard let self else { return }
            defer {
                self.isFetching = false
                self.checkConditionAndToggleRightBarButton()
            }
            do {
                try await self.viewModel.fetchCaseDataJSON()
            } catch {
                guard self.viewModel.isSessionCurrent else { return }
                self.form.showError(
                    "Could not load the test case. Try again.".localized,
                    retry: { [weak self] in
                        self?.fetchCase()
                    }
                )
            }
        }
    }

    @objc private func saveChanges() {
        form.finishEditing()
        view.endEditing(true)
        guard viewModel.canSaveChanges, !isSavingDraft else { return }
        form.clearError()
        isSubmitting = true
        checkConditionAndToggleRightBarButton()
        task = Task { [weak self] in
            guard let self else { return }
            defer {
                self.isSubmitting = false
                self.checkConditionAndToggleRightBarButton()
            }
            do {
                try await self.viewModel.updateTestCaseData()
                guard self.viewModel.isSessionCurrent, self.viewModel.isUploadingSuccess else { return }
                self.isSubmitting = false
                self.checkConditionAndToggleRightBarButton()
                UIAlertController.showSimpleAlert(
                    on: self,
                    title: "Success".localized,
                    message: "Changes saved".localized
                )
            } catch {
                guard self.viewModel.isSessionCurrent else { return }
                self.form.showError("Could not save the test case. Try again.".localized)
            }
        }
    }

    @objc private func goBack() {
        Task { [weak self] in
            guard let self, await self.requestDeparture() else { return }
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension TestCaseViewController: DetailTestCaseProtocol {
    func updateUI() { checkConditionAndToggleRightBarButton() }
}

extension TestCaseViewController: CheckEnablingRBBProtocol {
    func checkConditionAndToggleRightBarButton() {
        guard isViewLoaded else { return }
        backItem.isEnabled = !isSavingDraft
        saveItem.isEnabled = viewModel.canSaveChanges && !isSavingDraft && !isFetching
        if isSavingDraft {
            spinner.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        } else {
            spinner.stopAnimating()
            navigationItem.rightBarButtonItem = saveItem
        }
        form.updateValues()
        form
            .setEditingEnabled(viewModel.changedTestCase != nil && !isSavingDraft && !isFetching && viewModel
                .isSessionCurrent)
    }
}

extension TestCaseViewController: FormDepartureParticipant {
    var isSavingDraft: Bool { viewModel.isSaving || isSubmitting }
    var hasUnsavedChanges: Bool { viewModel.hasUnsavedChanges }
    var canSaveDraft: Bool { viewModel.canSaveChanges && !isSubmitting }

    func requestDeparture() async -> Bool {
        form.finishEditing()
        view.endEditing(true)
        guard !isSavingDraft, !isConfirmingDeparture, viewModel.isSessionCurrent else { return false }
        isConfirmingDeparture = true
        defer { isConfirmingDeparture = false }
        let allowed = await FormDepartureGuard.confirm(
            self,
            on: self,
            message: "Unsaved test case changes will be lost."
                .localized
        )
        return allowed && viewModel.isSessionCurrent && !isSavingDraft
    }

    func saveDraft() async throws {
        form.finishEditing()
        view.endEditing(true)
        guard !isSavingDraft else { throw API.NetError.invalidRequest("A save is already in progress") }
        let callback = viewModel.updatingFinishCallback
        viewModel.updatingFinishCallback = {}
        defer { viewModel.updatingFinishCallback = callback }
        try await viewModel.updateTestCaseData()
        guard viewModel.isUploadingSuccess, viewModel.isSessionCurrent else {
            throw API.NetError.invalidRequest("The draft was not saved")
        }
    }

    func discardDraft() {
        viewModel.discardDraft()
        checkConditionAndToggleRightBarButton()
    }
}

extension TestCaseViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard (navigationController?.viewControllers.count ?? 0) > 1, !isSavingDraft else { return false }
        form.finishEditing()
        view.endEditing(true)
        if hasUnsavedChanges {
            goBack()
            return false
        }
        return previousPopDelegate?.gestureRecognizerShouldBegin?(gestureRecognizer) ?? true
    }
}
