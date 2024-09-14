//
//  PropertiesPickerTextField.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 15.09.2024.
//

import UIKit

enum PropertiesCaseTextFieldTypes: String {
    case severity = "Severity"
    case status = "Status"
    case priority = "Priority"
    case behavior = "Behavior"
    case type = "Type"
    case layer = "Layer"
    case automationStatus = "Automation status"
}

final class PropertiesPickerTextField: UIView, UITextFieldDelegate {
    // MARK: - Fields
    private let textType: PropertiesCaseTextFieldTypes
    
    // MARK: - UI components
    private lazy var titleLabel: UILabel = {
        let tf = UILabel()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = .systemFont(ofSize: 15, weight: .bold)
        tf.text = "Severity"
        return tf
    }()
    
    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white
        tf.layer.borderWidth = 1.0
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.cornerRadius = 8.0
        return tf
    }()
    
    private lazy var pickerView: GenericPickerView<String> = {
        let pickerValueItems: [String]
        switch textType {
        case .severity:
            pickerValueItems = Constants.Severity.returnAllEnumCases()
        case .status:
            pickerValueItems = Constants.Status.returnAllEnumCases()
        case .priority:
            pickerValueItems = Constants.Priority.returnAllEnumCases()
        case .behavior:
            pickerValueItems = Constants.Behavior.returnAllEnumCases()
        case .type:
            pickerValueItems = Constants.Types.returnAllEnumCases()
        case .layer:
            pickerValueItems = Constants.Layer.returnAllEnumCases()
        case .automationStatus:
            pickerValueItems = Constants.AutomationStatus.returnAllEnumCases()
        }
        let pv = GenericPickerView<String>(items: pickerValueItems)
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    // MARK: - Lyfecycle
    init(textType: PropertiesCaseTextFieldTypes, textFieldValue: Int) {
        self.textType = textType
        super.init(frame: .zero)
        
        titleLabel.text = textType.rawValue
        textField.text = convertIntValueToString(typeField: textType, textFieldValue)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureView() {
        textField.inputView = pickerView
        textField.delegate = self
        textField.placeholder = "Select an option"
        textField.borderStyle = .roundedRect
        
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
        }
        
        self.addSubview(textField)
        textField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
        
        pickerView.didSelectItem = { selectedItem in
            self.textField.text = selectedItem
        }
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.setItems([doneButton], animated: false)
        
        textField.inputAccessoryView = toolbar
    }
    
    private func convertIntValueToString(typeField: PropertiesCaseTextFieldTypes, _ value: Int) -> String {
        switch typeField {
        case .severity:
            return Constants.Severity.returnAllEnumCases()[value]
        case .status:
            return Constants.Status.returnAllEnumCases()[value]
        case .priority:
            return Constants.Priority.returnAllEnumCases()[value]
        case .behavior:
            return Constants.Behavior.returnAllEnumCases()[value]
        case .type:
            return Constants.Types.returnAllEnumCases()[value]
        case .layer:
            return Constants.Layer.returnAllEnumCases()[value]
        case .automationStatus:
            return Constants.AutomationStatus.returnAllEnumCases()[value]
        }
    }
    
    func updateTextFieldValue(_ value: Int) {
        textField.text = convertIntValueToString(typeField: textType, value)
    }
    
    @objc func doneButtonTapped() {
        textField.resignFirstResponder()
    }
}
