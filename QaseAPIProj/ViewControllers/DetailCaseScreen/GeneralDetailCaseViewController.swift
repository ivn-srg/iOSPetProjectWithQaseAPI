import SnapKit
import UIKit

final class GeneralDetailCaseViewController: UIViewController {
    var onKeyboardVisibilityChanged: ((Bool) -> Void)?
    private let vm: TestCaseEditorViewModel
    private let projectTitle: String
    private let scrollView = UIScrollView()
    private let content = UIStackView()
    private let message = FormMessageView()
    private let steps = UIStackView()
    private var fields: [FieldType: GeneralCaseTextField] = [:]
    private var renderedSteps: [StepsInTestCase]?
    private var dataSections: [UIView] = []
    private weak var focusedField: GeneralCaseTextField?
    private lazy var properties = CasePropertiesFormView(viewModel: vm, style: .grouped)

    init(vm: TestCaseEditorViewModel, projectTitle: String? = nil) {
        self.vm = vm
        self.projectTitle = projectTitle ?? vm.reference.projectCode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.Palette.canvas
        view.keyboardLayoutGuide.usesBottomSafeArea = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
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
        content.addArrangedSubview(project)
        content.addArrangedSubview(message)
        let title = makeField(.title)
        let description = makeField(.description)
        let precondition = makeField(.precondition)
        let postcondition = makeField(.postcondition)
        let main = FormSectionView(
            title: "Main information".localized,
            rows: [title, description],
            style: .grouped
        )
        let conditions = FormSectionView(
            title: "Conditions".localized,
            rows: [precondition, postcondition],
            style: .grouped
        )
        content.addArrangedSubview(main)
        content.addArrangedSubview(conditions)
        content.addArrangedSubview(properties)
        let heading = UILabel()
        heading.text = "Steps".localized
        heading.font = .preferredFont(forTextStyle: .headline)
        heading.adjustsFontForContentSizeCategory = true
        heading.numberOfLines = 0
        heading.textColor = AppTheme.Palette.secondaryText
        heading.accessibilityTraits.insert(.header)
        steps.axis = .vertical
        steps.spacing = AppTheme.Space.medium
        let stepGroup = UIStackView(arrangedSubviews: [heading, steps])
        stepGroup.axis = .vertical
        stepGroup.spacing = AppTheme.Space.small
        content.addArrangedSubview(stepGroup)
        dataSections = [main, conditions, properties, stepGroup]
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardShown(_:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardShown(_:)),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardHidden),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        updateValues()
        updateBottomInsets()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func makeField(_ type: FieldType) -> GeneralCaseTextField {
        let field = GeneralCaseTextField(textType: type, detailVM: vm, style: .grouped)
        fields[type] = field
        field.onFocusChange = { [weak self, weak field] focused in
            guard focused, let self, let field else { return }
            self.focusedField = field
            self.revealCaret()
        }
        return field
    }

    private func revealCaret() {
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

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateBottomInsets()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateBottomInsets()
    }

    private func updateBottomInsets() {
        let keyboardTop = view.keyboardLayoutGuide.layoutFrame.minY
        let keyboardVisible = keyboardTop < view.bounds.maxY - view.safeAreaInsets.bottom
        let bottom = keyboardVisible ? 0 : view.safeAreaInsets.bottom
        if scrollView.contentInset.bottom != bottom {
            scrollView.contentInset.bottom = bottom
            scrollView.verticalScrollIndicatorInsets.bottom = bottom
        }
    }

    @objc private func keyboardShown(_ notification: Notification) {
        guard focusedField?.focusedCaretRect(in: scrollView) != nil,
              let screen = notification.object as? UIScreen,
              let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        let keyboardFrame = screen.coordinateSpace.convert(frame, to: view)
        guard view.bounds.intersection(keyboardFrame).height > 0 else { return }
        onKeyboardVisibilityChanged?(true)
        revealCaret()
    }

    @objc private func keyboardHidden() { onKeyboardVisibilityChanged?(false) }

    func updateValues() {
        guard isViewLoaded else { return }
        let draft = vm.changedTestCase ?? vm.testCase
        dataSections.forEach { $0.isHidden = draft == nil }
        fields[.title]?.updateTextViewValue(draft?.title)
        fields[.description]?.updateTextViewValue(draft?.description)
        fields[.precondition]?.updateTextViewValue(draft?.preconditions)
        fields[.postcondition]?.updateTextViewValue(draft?.postconditions)
        properties.updateValues()
        if let draft, renderedSteps != draft.steps {
            renderedSteps = draft.steps
            steps.arrangedSubviews.forEach { $0.removeFromSuperview() }
            if !draft.steps.isEmpty {
                appendSteps(draft.steps, prefix: nil)
            } else {
                updateEmptySteps()
            }
        }
    }

    private func updateEmptySteps() {
        guard steps.arrangedSubviews.isEmpty else { return }
        let label = UILabel()
        label.text = "No steps yet".localized
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = AppTheme.Palette.secondaryText
        label.accessibilityIdentifier = AccessibilityID.caseStepsEmpty.identifier
        steps.addArrangedSubview(label)
    }

    private func appendSteps(_ values: [StepsInTestCase], prefix: String?) {
        for (index, step) in values.enumerated() {
            let number = prefix.map { $0 + "." + String(index + 1) } ?? String(index + 1)
            steps.addArrangedSubview(TestCaseStepView(step: step, number: number))
            if let children = step.steps, !children.isEmpty { appendSteps(children, prefix: number) }
        }
    }

    func setEditingEnabled(_ enabled: Bool) {
        fields.values.forEach { $0.setEditingEnabled(enabled) }
        properties.setEditingEnabled(enabled)
    }

    func finishEditing() { fields.values.forEach { $0.finishEditing() } }

    func showError(_ text: String, retry: (() -> Void)? = nil) {
        message.show(text, retry: retry)
        scrollView.setContentOffset(.zero, animated: true)
    }

    func clearError() { message.clear() }
}
