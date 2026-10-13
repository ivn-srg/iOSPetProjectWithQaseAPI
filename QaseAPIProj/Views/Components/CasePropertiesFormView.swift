import SnapKit
import UIKit

final class CasePropertiesFormView: UIView {
    private let viewModel: UpdatableEntityProtocol
    private var fields: [CustomSelectableView] = []
    private let flakySwitch: SwitcherWithTitle

    init(viewModel: UpdatableEntityProtocol) {
        self.viewModel = viewModel
        flakySwitch = SwitcherWithTitle(
            title: FieldType.isFlaky.localized,
            isOn: viewModel.formCase?.isFlaky ?? false
        )
        super.init(frame: .zero)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = AppTheme.Space.section
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        stack.addArrangedSubview(section("Classification", fields: [.severity, .status, .priority]))
        stack.addArrangedSubview(section("Type and layer", fields: [.behavior, .type, .layer]))
        let automation = makeField(.automation)
        stack.addArrangedSubview(FormSectionView(
            title: "Automation".localized,
            rows: [automation, flakySwitch]
        ))
        flakySwitch.switchValueChanged = { [weak self] value in
            self?.viewModel.updateValue(for: .isFlaky, value: value)
        }
        updateValues()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeField(_ type: FieldType) -> CustomSelectableView {
        let field = CustomSelectableView(textFieldType: type, detailCaseVM: viewModel)
        fields.append(field)
        return field
    }

    private func section(_ title: String, fields: [FieldType]) -> FormSectionView {
        FormSectionView(title: title.localized, rows: fields.map(makeField))
    }

    func updateValues() {
        fields.forEach { $0.updateSelectedValue() }
        let draft = viewModel.formCase
        flakySwitch.configure(with: draft?.isFlaky ?? false)
    }

    func setEditingEnabled(_ enabled: Bool) {
        fields.forEach { $0.setEditingEnabled(enabled) }
        flakySwitch.setEditingEnabled(enabled)
    }
}
