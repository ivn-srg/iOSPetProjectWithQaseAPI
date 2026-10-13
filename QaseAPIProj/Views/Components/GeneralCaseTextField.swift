import SnapKit
import UIKit

final class GeneralCaseTextField: UIView {
    var onFocusChange: ((Bool) -> Void)?
    private let textType: FieldType
    private let viewModel: FormValueUpdating?
    private var didBlur = false
    private var committedValue = ""
    private let titleLabel = UILabel()
    private let textView = UITextView()
    private let placeholder = UILabel()
    private let counter = UILabel()
    private let validation = UILabel()
    private let footnotes = UIStackView()
    private struct Layout {
        static let borderWidth: CGFloat = 1
        static let inputInset: CGFloat = 12
        static let labelSpacing: CGFloat = 6
        static let titleHeight: CGFloat = 48
        static let multilineHeight: CGFloat = 80
    }

    private var placeholderHeightConstraint: Constraint?

    init(textType: FieldType, textViewValue: String? = "", detailVM: FormValueUpdating? = nil) {
        self.textType = textType
        viewModel = detailVM
        super.init(frame: .zero)
        textView.accessibilityIdentifier = AccessibilityID.field(textType.accessibilityField).identifier
        textView.accessibilityLabel = textType.localized
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineFragmentPadding = 0
        titleLabel.numberOfLines = 0
        titleLabel.text = textType == .title ? textType.localized + " *" : textType.localized
        textView.text = textViewValue ?? ""
        committedValue = textView.text ?? ""
        setupEntityForm()
        registerForTraitChanges([
            UITraitUserInterfaceStyle.self,
            UITraitPreferredContentSizeCategory.self
        ]) { (view: Self, _) in
            view.refreshTraits()
        }
        updatePresentation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupEntityForm() {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = AppTheme.Palette.secondaryText
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = AppTheme.Palette.text
        textView.backgroundColor = AppTheme.Palette.secondarySurface
        textView.layer.cornerRadius = AppTheme.Radius.card
        textView.layer.borderWidth = Layout.borderWidth
        textView.textContainerInset = UIEdgeInsets(
            top: Layout.inputInset,
            left: Layout.inputInset,
            bottom: Layout.inputInset,
            right: Layout.inputInset
        )
        placeholder.font = textView.font
        placeholder.adjustsFontForContentSizeCategory = true
        placeholder.textColor = AppTheme.Palette.tertiaryText
        placeholder.numberOfLines = 0
        switch textType {
        case .title: placeholder.text = "Enter a title".localized
        case .code: placeholder.text = FieldType.code.localized
        default: placeholder.text = "Optional".localized
        }
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
        validation.text = (textType == .code ? "A project code is required" : "A title is required").localized
        validation.isAccessibilityElement = false
        let spacer = UIView()
        spacer.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        [validation, spacer, counter].forEach(footnotes.addArrangedSubview)
        footnotes.alignment = .top
        footnotes.spacing = AppTheme.Space.small
        validation.setContentHuggingPriority(.defaultLow, for: .horizontal)
        counter.setContentHuggingPriority(.required, for: .horizontal)
        counter.setContentCompressionResistancePriority(.required, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [titleLabel, textView, footnotes])
        stack.axis = .vertical
        stack.spacing = Layout.labelSpacing
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        let minimumHeight = (textType == .title || textType == .code) ? Layout.titleHeight : Layout
            .multilineHeight
        textView.snp.makeConstraints { $0.height.greaterThanOrEqualTo(minimumHeight) }
        textView.addSubview(placeholder)
        placeholder.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.inputInset)
            $0.top.equalToSuperview().offset(Layout.inputInset)
        }
        textView.snp.makeConstraints {
            placeholderHeightConstraint = $0.height.greaterThanOrEqualTo(placeholder.snp.height)
                .offset(Layout.inputInset * 2).constraint
        }
    }

    private func refreshTraits() {
        updatePresentation()
    }

    private func updatePresentation() {
        placeholder.isHidden = !textView.text.isEmpty
        if placeholder.isHidden { placeholderHeightConstraint?.deactivate() }
        else { placeholderHeightConstraint?.activate() }
        counter.text = "\(textView.text.count)/\(FormTextInputPolicy.characterLimit)"
        counter.isHidden = !textView.isFirstResponder
        let invalid = (textType == .title || textType == .code) && didBlur && textView.text
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        validation.isHidden = !invalid
        footnotes.isHidden = !invalid && counter.isHidden
        let border: UIColor
        if invalid { border = AppTheme.Palette.danger }
        else if textView.isFirstResponder { border = AppTheme.Palette.accent }
        else { border = .clear }
        textView.layer.borderColor = border.resolvedColor(with: traitCollection).cgColor
        textView.accessibilityHint = invalid ? validation.text : String.localizedStringWithFormat(
            "Maximum %lld characters".localized,
            FormTextInputPolicy.characterLimit
        )
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
