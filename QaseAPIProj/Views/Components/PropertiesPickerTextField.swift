//
//  PropertiesPickerTextField.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 15.09.2024.
//

import UIKit

final class PropertiesPickerTextField: UIView {
    // MARK: - Fields
    private let textType: FieldType
    private var testCaseViewModel: UpdatableEntityProtocol?
    
    // MARK: - UI components
    private lazy var titleLabel: UILabel = {
        let tf = UILabel()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = .systemFont(ofSize: 16, weight: .bold)
        return tf
    }()
    
    private lazy var textField = CustomSelectableView(textFieldType: textType, detailCaseVM: testCaseViewModel)
    
    // MARK: - Lyfecycle
    init(textType: FieldType, detailCaseVM: UpdatableEntityProtocol?) {
        self.textType = textType
        self.testCaseViewModel = detailCaseVM
        super.init(frame: .zero)
        
        titleLabel.text = textType.localized
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureView() {
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
        }
        
        self.addSubview(textField)
        textField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    func updateValue() {
        textField.updateSelectedValue()
    }
}
