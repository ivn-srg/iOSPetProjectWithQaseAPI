import SnapKit
import UIKit

final class CreatingProjectViewController: UIViewController {
    private let viewModel: CreatingProjectViewModel
    private let createdCallback: (() -> Void)?
    private let scrollView = UIScrollView()
    private let content = UIStackView()
    private let message = FormMessageView()
    private var task: Task<Void, Never>?
    private weak var focusedField: GeneralCaseTextField?
    private lazy var createItem = UIBarButtonItem(
        title: "Create".localized,
        style: .plain,
        target: self,
        action: #selector(createProject)
    )
    private lazy var closeItem = UIBarButtonItem(
        systemItem: .close,
        primaryAction: UIAction { [weak self] _ in self?.closeForm() }
    )
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var fields: [GeneralCaseTextField] = []

    init(viewModel: CreatingProjectViewModel, createdCallback: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.createdCallback = createdCallback
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Creating project".localized
        view.backgroundColor = AppTheme.Palette.canvas
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = closeItem
        closeItem.accessibilityIdentifier = AccessibilityID.formClose.identifier
        createItem.accessibilityIdentifier = AccessibilityID.formCreate.identifier
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
            $0.width.equalTo(scrollView.frameLayoutGuide).offset(-AppTheme.Space.screen * 2)
        }
        fields = [FieldType.title, FieldType.description, FieldType.code].map { type in
            let field = GeneralCaseTextField(textType: type, detailVM: viewModel)
            field.onFocusChange = { [weak self, weak field] focused in
                guard focused, let self, let field else { return }
                self.focusedField = field
                self.revealCaret()
            }
            return field
        }
        content.addArrangedSubview(message)
        content.addArrangedSubview(FormSectionView(title: "Main information".localized, rows: fields))
        viewModel.delegate = self
        viewModel.creatingFinishCallback = { [weak self] in
            guard let self else { return }
            self.createdCallback?()
            self.dismiss(animated: true)
        }
        viewModel.showErrorClosure = { [weak self] _, text in self?.message.show(text) }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(revealCaret),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
        checkConditionAndToggleRightBarButton()
    }

    deinit {
        task?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func revealCaret() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let field = self.focusedField else { return }
            self.view.layoutIfNeeded()
            if let rect = field.focusedCaretRect(in: self.scrollView) {
                self.scrollView.scrollRectToVisible(
                    rect.insetBy(dx: 0, dy: -AppTheme.Space.medium),
                    animated: true
                )
            }
        }
    }

    private func closeForm() {
        Task { [weak self] in
            guard let self, await self.requestDeparture() else { return }
            self.dismiss(animated: true)
        }
    }

    @objc private func createProject() {
        guard task == nil, canSaveDraft else { return }
        view.endEditing(true)
        message.clear()
        task = Task { [weak self] in
            guard let self else { return }
            defer { self.task = nil }
            do { try await self.viewModel.createNewProject() }
            catch is CancellationError { }
            catch { self.message.show("Something went wrong".localized) }
        }
    }
}

extension CreatingProjectViewController: CheckEnablingRBBProtocol {
    func checkConditionAndToggleRightBarButton() {
        createItem.isEnabled = canSaveDraft && hasUnsavedChanges && !viewModel.isSaving
        closeItem.isEnabled = !viewModel.isSaving
        fields.forEach { $0.setEditingEnabled(!viewModel.isSaving) }
        isModalInPresentation = hasUnsavedChanges || viewModel.isSaving
        if viewModel.isSaving {
            spinner.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        } else {
            spinner.stopAnimating()
            navigationItem.rightBarButtonItem = createItem
        }
    }
}

extension CreatingProjectViewController: FormDepartureParticipant {
    var hasUnsavedChanges: Bool { viewModel.hasUnsavedChanges }
    var canSaveDraft: Bool { !viewModel.creatingProject.isEmpty }
    var isSavingDraft: Bool { viewModel.isSaving }

    func requestDeparture() async -> Bool {
        view.endEditing(true)
        return await FormDepartureGuard.confirm(
            self,
            on: self,
            message: "Some changes cannot be saved. Stay to finish editing or discard them.".localized
        )
    }

    func saveDraft() async throws {
        let callback = viewModel.creatingFinishCallback
        viewModel.creatingFinishCallback = {}
        defer { viewModel.creatingFinishCallback = callback }
        try await viewModel.createNewProject()
        guard viewModel.isEntityWasCreated else { throw API.NetError.invalidRequest("Create failed") }
    }

    func discardDraft() { viewModel.discardDraft() }
}
