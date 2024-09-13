//
//  TextFieldWithTitle.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.09.2024.
//

import UIKit
import SnapKit

enum GeneralCaseTextFieldTypes {
    case name, description, precondition, postcondition
}

final class GeneralCaseTextField: UIView {
    
    // MARK: - UI components
    private lazy var titlelbl: UILabel = {
        let vc = UILabel()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.font = .systemFont(ofSize: 20, weight: .bold)
        vc.numberOfLines = 0
        return vc
    }()
    
    private var textField: TextFieldWithPadding = {
        let decslbl = TextFieldWithPadding()
        decslbl.translatesAutoresizingMaskIntoConstraints = false
        decslbl.backgroundColor = .white
        decslbl.layer.borderWidth = 1.0
        decslbl.font = .systemFont(ofSize: 16)
        decslbl.layer.borderColor = UIColor.gray.cgColor
        decslbl.layer.cornerRadius = 8.0
        decslbl.isUserInteractionEnabled = true
        return decslbl
    }()
    
    // MARK: - Lyfecycle
    
    init(textType: GeneralCaseTextFieldTypes, textFieldValue: String = "") {
        super.init(frame: .zero)
        
        let title: String
        switch textType {
        case .name:
            title = "Title"
        case .description:
            title = "Description"
        case .precondition:
            title = "Pre-condition"
        case .postcondition:
            title = "Post-condition"
        }
        
        titlelbl.text = title
        textField.text = textFieldValue
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureView() {
        self.addSubview(titlelbl)
        titlelbl.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
        }
        
        self.addSubview(textField)
        textField.snp.makeConstraints {
            $0.top.equalTo(titlelbl.snp.bottom).offset(8)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    func updateTextFieldValue(_ value: String) {
        textField.text = value
    }
}

final class TextFieldWithPadding: UITextField {
    var textPadding = UIEdgeInsets(
        top: 10,
        left: 10,
        bottom: 10,
        right: 10
    )

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }
}
