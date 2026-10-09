import UIKit
import SnapKit

final class PropertiesPickerTextField: UIView {
    private let selectableView: CustomSelectableView

    init(textType: FieldType, detailCaseVM: UpdatableEntityProtocol?) {
        selectableView = CustomSelectableView(textFieldType: textType, detailCaseVM: detailCaseVM)
        super.init(frame: .zero)
        addSubview(selectableView)
        selectableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateValue() {
        selectableView.updateSelectedValue()
    }

    func setEditingEnabled(_ enabled: Bool) {
        selectableView.setEditingEnabled(enabled)
    }
}
