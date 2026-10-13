import SnapKit
import UIKit

final class CreateSuiteView: UIView {
    let parentButton = FormParentButton()
    var onFocusChange: ((GeneralCaseTextField) -> Void)?
    private let viewModel: EntityCreationViewModel
    private var fields: [FieldType: GeneralCaseTextField] = [:]

    init(linkedViewModel: EntityCreationViewModel) {
        viewModel = linkedViewModel
        super.init(frame: .zero)
        let title = makeField(.title, value: linkedViewModel.creatingSuite.title)
        let description = makeField(.description, value: linkedViewModel.creatingSuite.itemDescription)
        let precondition = makeField(.precondition, value: linkedViewModel.creatingSuite.preconditions)
        let stack = UIStackView(arrangedSubviews: [
            FormSectionView(title: "Main information".localized, rows: [title, description]),
            FormSectionView(title: "Conditions".localized, rows: [precondition]),
            FormSectionView(title: "Location".localized, rows: [parentButton])
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
        let field = GeneralCaseTextField(textType: type, textViewValue: value, detailVM: viewModel)
        fields[type] = field
        field.onFocusChange = { [weak self, weak field] focused in
            if focused, let field { self?.onFocusChange?(field) }
        }
        return field
    }

    func updateValues() {
        fields[.title]?.updateTextViewValue(viewModel.creatingSuite.title)
        fields[.description]?.updateTextViewValue(viewModel.creatingSuite.itemDescription)
        fields[.precondition]?.updateTextViewValue(viewModel.creatingSuite.preconditions)
    }

    func setEditingEnabled(_ enabled: Bool) {
        fields.values.forEach { $0.setEditingEnabled(enabled) }
        parentButton.isEnabled = enabled
    }

    func finishEditing() { fields.values.forEach { $0.finishEditing() } }
}
