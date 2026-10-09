import UIKit
import SnapKit

final class CreateTestCaseView: UIView {
    let parentButton = FormParentButton()
    var onFocusChange: ((GeneralCaseTextField) -> Void)?
    private let viewModel: CreateSuiteOrCaseViewModel
    private var fields: [FieldType: GeneralCaseTextField] = [:]
    private let properties: CasePropertiesFormView

    init(linkedViewModel: CreateSuiteOrCaseViewModel) {
        viewModel = linkedViewModel
        properties = CasePropertiesFormView(viewModel: linkedViewModel)
        super.init(frame: .zero)
        let title = makeField(.title, value: linkedViewModel.creatingTestCase.title)
        let description = makeField(.description, value: linkedViewModel.creatingTestCase.description)
        let precondition = makeField(.precondition, value: linkedViewModel.creatingTestCase.preconditions)
        let postcondition = makeField(.postcondition, value: linkedViewModel.creatingTestCase.postconditions)
        let stack = UIStackView(arrangedSubviews: [
            FormSectionView(title: "Main information".localized, rows: [title, description]),
            FormSectionView(title: "Conditions".localized, rows: [precondition, postcondition]),
            FormSectionView(title: "Location".localized, rows: [parentButton]),
            properties
        ])
        stack.axis = .vertical
        stack.spacing = AppTheme.Space.section
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeField(_ type: FieldType, value: String?) -> GeneralCaseTextField {
        let field = GeneralCaseTextField(textType: type, textViewValue: value, detailVM: viewModel, style: .entityForm)
        fields[type] = field
        field.onFocusChange = { [weak self, weak field] focused in
            if focused, let field { self?.onFocusChange?(field) }
        }
        return field
    }

    func updateValues() {
        let value = viewModel.creatingTestCase
        fields[.title]?.updateTextViewValue(value.title)
        fields[.description]?.updateTextViewValue(value.description)
        fields[.precondition]?.updateTextViewValue(value.preconditions)
        fields[.postcondition]?.updateTextViewValue(value.postconditions)
        properties.updateValues()
    }

    func setEditingEnabled(_ enabled: Bool) {
        fields.values.forEach { $0.setEditingEnabled(enabled) }
        properties.setEditingEnabled(enabled)
        parentButton.isEnabled = enabled
    }

    func finishEditing() { fields.values.forEach { $0.finishEditing() } }
}
