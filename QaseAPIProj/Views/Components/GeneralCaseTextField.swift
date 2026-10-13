import SnapKit
import UIKit

final class GeneralCaseTextField: UIView {
    enum Style: Equatable {
        case legacy
        case entityForm
    }

    var onFocusChange: ((Bool) -> Void)?
    private let textType: FieldType
    private let style: Style
    private let viewModel: UpdatableEntityProtocol?
    private var didBlur = false
    private var committedValue = ""
    private let titleLabel = UILabel()
    private let textView = UITextView()
    private let placeholder = UILabel()
    private let counter = UILabel()
    private let validation = UILabel()
    private var placeholderHeightConstraint: Constraint?

    init(
        textType: FieldType,
        textViewValue: String? = "",
        detailVM: UpdatableEntityProtocol? = nil,
        style: Style = .legacy
    ) {
        self.textType = textType
        self.style = style
        viewModel = detailVM
        super.init(frame: .zero)
        textView.accessibilityIdentifier = "field." + textType.rawValue
        textView.accessibilityLabel = textType.localized
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        titleLabel.numberOfLines = 0
        titleLabel.text = textType == .title && style == .entityForm ? textType.localized + " *" : textType
            .localized
        if let creating = detailVM as? CreateSuiteOrCaseViewModel, textType == .parentSuite {
            textView.text = creating.parentSuiteId.map(String.init) ?? Constants.EMPTY_TEXT
        } else {
            textView.text = textViewValue ?? ""
        }
        committedValue = textView.text ?? ""
        if style == .entityForm {
            setupEntityForm()
        } else {
            setupLegacy()
        }
        updatePresentation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLegacy() {
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        textView.backgroundColor = AppTheme.bgSecondaryColor
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.cornerRadius = 10
        textView.font = .systemFont(ofSize: 16)
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        addSubview(titleLabel)
        addSubview(textView)
        titleLabel.snp.makeConstraints { $0.top.horizontalEdges.equalToSuperview() }
        textView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }

    private func setupEntityForm() {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = AppTheme.Palette.secondaryText
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = AppTheme.Palette.text
        textView.backgroundColor = AppTheme.Palette.secondarySurface
        textView.layer.cornerRadius = 16
        textView.layer.borderWidth = 1
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 11, bottom: 14, right: 11)
        placeholder.font = textView.font
        placeholder.adjustsFontForContentSizeCategory = true
        placeholder.textColor = AppTheme.Palette.tertiaryText
        placeholder.numberOfLines = 0
        placeholder.text = textType == .title ? "Enter a title".localized : "Optional".localized
        placeholder.isUserInteractionEnabled = false
        placeholder.isAccessibilityElement = false
        counter.font = UIFont.preferredFont(forTextStyle: .caption1)
        counter.adjustsFontForContentSizeCategory = true
        counter.textColor = AppTheme.Palette.tertiaryText
        counter.isAccessibilityElement = false
        validation.font = UIFont.preferredFont(forTextStyle: .caption1)
        validation.adjustsFontForContentSizeCategory = true
        validation.textColor = AppTheme.Palette.danger
        validation.numberOfLines = 0
        validation.text = "A title is required".localized
        validation.isAccessibilityElement = false
        textView.accessibilityHint = "Maximum 500 characters".localized
        let spacer = UIView()
        spacer.setContentHuggingPriority(UILayoutPriority(1), for: .horizontal)
        let footnotes = UIStackView(arrangedSubviews: [validation, spacer, counter])
        footnotes.alignment = .top
        footnotes.spacing = 8
        validation.setContentHuggingPriority(.defaultLow, for: .horizontal)
        counter.setContentHuggingPriority(.required, for: .horizontal)
        counter.setContentCompressionResistancePriority(.required, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [titleLabel, textView, footnotes])
        stack.axis = .vertical
        stack.spacing = 6
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        textView.snp.makeConstraints { $0.height.greaterThanOrEqualTo(textType == .title ? 60 : 88) }
        textView.addSubview(placeholder)
        placeholder.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview().offset(14)
        }
        textView.snp.makeConstraints {
            placeholderHeightConstraint = $0.height.greaterThanOrEqualTo(placeholder.snp.height).offset(28)
                .constraint
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatePresentation()
    }

    private func updatePresentation() {
        guard style == .entityForm else { return }
        placeholder.isHidden = !textView.text.isEmpty
        if placeholder.isHidden { placeholderHeightConstraint?.deactivate() }
        else { placeholderHeightConstraint?.activate() }
        counter.text = "\(textView.text.count)/\(FormTextInputPolicy.characterLimit)"
        counter.alpha = textView.isFirstResponder ? 1 : 0
        let invalid = textType == .title && didBlur && textView.text
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        validation.isHidden = !invalid
        textView.layer
            .borderColor = (invalid ? AppTheme.Palette.danger : textView.isFirstResponder ? AppTheme.Palette
                .accent : UIColor.clear).resolvedColor(with: traitCollection).cgColor
        textView.accessibilityHint = invalid ? "A title is required".localized : "Maximum 500 characters"
            .localized
    }

    private func publishText() {
        switch textType {
        case .title, .description, .precondition, .postcondition, .code:
            viewModel?.updateValue(for: textType, value: textView.text ?? "")
        case .parentSuite:
            viewModel?.updateValue(for: .parentSuite, value: Int(textView.text) ?? 0)
        default: break
        }
    }

    private func commitText() {
        guard textView.markedTextRange == nil else {
            refreshTextLayout()
            return
        }
        guard (textView.text ?? "") != committedValue else {
            refreshTextLayout()
            return
        }
        let edit = FormTextInputPolicy.committed(textView.text ?? "", selection: textView.selectedRange)
        if edit.text != textView.text {
            textView.text = edit.text
            textView.selectedRange = edit.selection
        }
        committedValue = edit.text
        refreshTextLayout()
        publishText()
    }

    private func refreshTextLayout() {
        updatePresentation()
        invalidateIntrinsicContentSize()
        textView.invalidateIntrinsicContentSize()
        if textView.isFirstResponder { onFocusChange?(true) }
    }

    func focusedCaretRect(in target: UIView) -> CGRect? {
        guard textView.isFirstResponder, let selection = textView.selectedTextRange else { return nil }
        return textView.convert(textView.caretRect(for: selection.end), to: target)
    }

    func updateTextViewValue(_ value: String?) {
        guard textView.markedTextRange == nil, textView.text != (value ?? "") else { return }
        let selection = textView.selectedRange
        textView.text = value ?? ""
        committedValue = textView.text ?? ""
        let location = min(selection.location, textView.text.utf16.count)
        textView.selectedRange = NSRange(
            location: location,
            length: min(selection.length, textView.text.utf16.count - location)
        )
        refreshTextLayout()
    }

    func finishEditing() {
        guard textView.isFirstResponder else { return }
        if textView.markedTextRange != nil { textView.unmarkText() }
        commitText()
        textView.resignFirstResponder()
    }

    func setEditingEnabled(_ enabled: Bool) {
        textView.isEditable = enabled
        textView.isSelectable = enabled
    }
}

extension GeneralCaseTextField: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        guard textView.markedTextRange == nil else { return true }
        guard let edit = FormTextInputPolicy.replacing(textView.text ?? "", range: range, with: text)
        else { return false }
        guard let swiftRange = Range(range, in: textView.text ?? "") else { return false }
        let proposed = (textView.text ?? "").replacingCharacters(in: swiftRange, with: text)
        guard proposed != edit.text else { return true }
        textView.text = edit.text
        textView.selectedRange = edit.selection
        commitText()
        return false
    }

    func textViewDidChange(_ textView: UITextView) {
        commitText()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        if textView.isFirstResponder { onFocusChange?(true) }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        updatePresentation()
        onFocusChange?(true)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        didBlur = true
        commitText()
        updatePresentation()
        onFocusChange?(false)
    }
}
