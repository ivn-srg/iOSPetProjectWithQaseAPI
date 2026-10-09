import UIKit
import SnapKit

final class CreateSuiteOrCaseViewController: UIViewController {
    private let viewModel: CreateSuiteOrCaseViewModel
    private let projectTitle: String
    private let onEntityCreated: (() -> Void)?
    private let scrollView = UIScrollView()
    private let content = UIStackView()
    private let message = FormMessageView()
    private var isSavingSequence = false
    private var isSubmitting = false
    private var isConfirmingDeparture = false
    private var loadTask: Task<Void, Never>?
    private weak var focusedField: GeneralCaseTextField?
    private lazy var parentCatalog = SuitePickerViewModel(projectCode: viewModel.projectCode, projectTitle: projectTitle)
    private lazy var suiteView = CreateSuiteView(linkedViewModel: viewModel)
    private lazy var caseView = CreateTestCaseView(linkedViewModel: viewModel)
    private lazy var createItem = UIBarButtonItem(title: "Create".localized, style: .plain, target: self, action: #selector(createEntity))
    private lazy var closeItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeForm))
    private lazy var spinner: UIActivityIndicatorView = {
        let value = UIActivityIndicatorView(style: .medium)
        value.color = AppTheme.Palette.accent
        value.accessibilityLabel = "Saving".localized
        return value
    }()
    private lazy var segment: UISegmentedControl = {
        let value = UISegmentedControl(items: ["Suite".localized, "Case".localized])
        value.selectedSegmentIndex = 0
        value.accessibilityIdentifier = "form.entityType"
        value.addTarget(self, action: #selector(changeEntity), for: .valueChanged)
        return value
    }()

    init(viewModel: CreateSuiteOrCaseViewModel, projectTitle: String? = nil, onEntityCreated: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.projectTitle = projectTitle ?? viewModel.projectCode
        self.onEntityCreated = onEntityCreated
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Creation".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = closeItem
        closeItem.accessibilityIdentifier = "form.close"
        createItem.accessibilityIdentifier = "form.create"
        view.backgroundColor = AppTheme.Palette.canvas
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        content.axis = .vertical
        content.spacing = AppTheme.Space.section
        scrollView.addSubview(content)
        content.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide).inset(AppTheme.Space.screen)
            $0.width.equalTo(scrollView.frameLayoutGuide).offset(-2 * AppTheme.Space.screen)
        }
        let project = UILabel()
        project.text = projectTitle
        project.font = .preferredFont(forTextStyle: .body)
        project.adjustsFontForContentSizeCategory = true
        project.numberOfLines = 0
        project.textColor = AppTheme.Palette.secondaryText
        content.addArrangedSubview(segment)
        content.addArrangedSubview(project)
        content.addArrangedSubview(message)
        content.addArrangedSubview(suiteView)
        content.addArrangedSubview(caseView)
        suiteView.onFocusChange = { [weak self] field in self?.revealCaret(in: field) }
        caseView.onFocusChange = { [weak self] field in self?.revealCaret(in: field) }
        suiteView.parentButton.addTarget(self, action: #selector(chooseParent), for: .touchUpInside)
        caseView.parentButton.addTarget(self, action: #selector(chooseParent), for: .touchUpInside)
        viewModel.delegate = self
        viewModel.showErrorClosure = { [weak self] _, _ in
            self?.message.show("A title is required".localized)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShown),
            name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShown),
            name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        checkConditionAndToggleRightBarButton()
    }

    deinit {
        loadTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    private func revealCaret(in field: GeneralCaseTextField) {
        focusedField = field
        DispatchQueue.main.async { [weak self, weak field] in
            guard let self, let field else { return }
            self.view.layoutIfNeeded()
            if let rect = field.focusedCaretRect(in: self.scrollView) {
                self.scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -12), animated: true)
            }
        }
    }

    @objc private func keyboardShown() {
        if let field = focusedField { revealCaret(in: field) }
    }

    private func finishEditing() {
        if viewModel.creatingEntityIsSuite { suiteView.finishEditing() }
        else { caseView.finishEditing() }
        view.endEditing(true)
    }

    @objc private func changeEntity() {
        guard !isSavingDraft else { return }
        finishEditing()
        viewModel.creatingEntityIsSuite = segment.selectedSegmentIndex == 0
        message.clear()
        scrollView.setContentOffset(.zero, animated: false)
    }

    @objc private func chooseParent() {
        guard !isSavingDraft, viewModel.isSessionCurrent else { return }
        finishEditing()
        let forSuite = viewModel.creatingEntityIsSuite
        let id = forSuite ? viewModel.creatingSuite.parentId : viewModel.creatingTestCase.suiteId
        let model = SuitePickerViewModel(projectCode: viewModel.projectCode, selectedID: id, projectTitle: projectTitle)
        let picker = SuitePickerViewController(viewModel: model) { [weak self] selected in
            guard let self, self.viewModel.isSessionCurrent, !self.isSavingDraft else { return }
            self.parentCatalog = model
            self.viewModel.selectParent(selected, forSuite: forSuite)
        }
        let navigation = UINavigationController(rootViewController: picker)
        navigation.navigationBar.tintColor = AppTheme.Palette.accent
        navigation.modalPresentationStyle = .pageSheet
        present(navigation, animated: true)
    }

    @objc private func createEntity() {
        finishEditing()
        guard viewModel.canCreate, !isSavingDraft else { return }
        message.clear()
        isSubmitting = true
        checkConditionAndToggleRightBarButton()
        loadTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.isSubmitting = false
                self.checkConditionAndToggleRightBarButton()
            }
            do {
                try await self.viewModel.createNewEntity()
                guard self.viewModel.isSessionCurrent, self.viewModel.isEntityWasCreated else { return }
                self.isSubmitting = false
                self.checkConditionAndToggleRightBarButton()
                self.onEntityCreated?()
                if self.viewModel.hasAnyUnsavedChanges {
                    let allowed = await self.confirmDeparture(message: "Entity created. Unsaved changes in the other form remain.".localized)
                    if allowed { self.navigationController?.dismiss(animated: true) }
                    else { self.showRemainingDraft() }
                } else {
                    UIAlertController.showSimpleAlert(on: self, title: "Success".localized,
                        message: "Your entity was created successfully".localized) { [weak self] _ in
                        self?.navigationController?.dismiss(animated: true)
                    }
                }
            } catch {
                guard self.viewModel.isSessionCurrent else { return }
                self.message.show("Could not create the entity. Try again.".localized)
                self.scrollView.setContentOffset(.zero, animated: true)
            }
            self.checkConditionAndToggleRightBarButton()
        }
    }

    private func showRemainingDraft() {
        guard viewModel.hasAnyUnsavedChanges else { return }
        viewModel.creatingEntityIsSuite = viewModel.suiteHasUnsavedChanges
        segment.selectedSegmentIndex = viewModel.creatingEntityIsSuite ? 0 : 1
        scrollView.setContentOffset(.zero, animated: true)
    }

    @objc private func closeForm() {
        Task { [weak self] in
            guard let self, await self.requestDeparture() else { return }
            self.navigationController?.dismiss(animated: true)
        }
    }

    private func confirmDeparture(message: String) async -> Bool {
        guard !isConfirmingDeparture, !isSavingDraft, viewModel.isSessionCurrent else { return false }
        isConfirmingDeparture = true
        defer { isConfirmingDeparture = false }
        let allowed = await FormDepartureGuard.confirm(self, on: self, message: message)
        return allowed && viewModel.isSessionCurrent && !isSavingDraft
    }
}

extension CreateSuiteOrCaseViewController: CheckEnablingRBBProtocol {
    func checkConditionAndToggleRightBarButton() {
        guard isViewLoaded else { return }
        let busy = isSavingDraft
        closeItem.isEnabled = !busy
        createItem.isEnabled = viewModel.canCreate && !busy
        if busy {
            spinner.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        } else {
            spinner.stopAnimating()
            navigationItem.rightBarButtonItem = createItem
        }
        segment.isEnabled = !busy
        segment.selectedSegmentIndex = viewModel.creatingEntityIsSuite ? 0 : 1
        suiteView.isHidden = !viewModel.creatingEntityIsSuite
        caseView.isHidden = viewModel.creatingEntityIsSuite
        suiteView.updateValues()
        caseView.updateValues()
        suiteView.setEditingEnabled(!busy && viewModel.isSessionCurrent)
        caseView.setEditingEnabled(!busy && viewModel.isSessionCurrent)
        suiteView.parentButton.update(title: parentCatalog.title(for: viewModel.creatingSuite.parentId),
            path: parentCatalog.ancestorTitle(to: viewModel.creatingSuite.parentId))
        caseView.parentButton.update(title: parentCatalog.title(for: viewModel.creatingTestCase.suiteId),
            path: parentCatalog.ancestorTitle(to: viewModel.creatingTestCase.suiteId))
    }
}

extension CreateSuiteOrCaseViewController: FormDepartureParticipant {
    var isSavingDraft: Bool { viewModel.isSaving || isSavingSequence || isSubmitting }
    var hasUnsavedChanges: Bool { viewModel.hasAnyUnsavedChanges }
    var canSaveDraft: Bool { viewModel.canSaveAllDrafts && !isSavingSequence }

    func requestDeparture() async -> Bool {
        finishEditing()
        return await confirmDeparture(message: "There are unsaved changes in the suite or case form.".localized)
    }

    func saveDraft() async throws {
        finishEditing()
        guard canSaveDraft, !isSavingDraft else { throw API.NetError.invalidRequest("The drafts cannot be saved") }
        let previous = viewModel.creatingEntityIsSuite
        let callback = viewModel.creatingFinishCallback
        isSavingSequence = true
        viewModel.creatingFinishCallback = {}
        checkConditionAndToggleRightBarButton()
        defer {
            viewModel.creatingFinishCallback = callback
            viewModel.creatingEntityIsSuite = previous
            isSavingSequence = false
            checkConditionAndToggleRightBarButton()
        }
        for forSuite in [true, false] {
            let dirty = forSuite ? viewModel.suiteHasUnsavedChanges : viewModel.caseHasUnsavedChanges
            guard dirty else { continue }
            viewModel.creatingEntityIsSuite = forSuite
            try await viewModel.createNewEntity()
            guard viewModel.isEntityWasCreated, viewModel.isSessionCurrent else {
                throw API.NetError.invalidRequest("The draft was not created")
            }
            onEntityCreated?()
        }
    }

    func discardDraft() {
        guard !isSavingDraft else { return }
        viewModel.discardDraft()
        checkConditionAndToggleRightBarButton()
    }
}
