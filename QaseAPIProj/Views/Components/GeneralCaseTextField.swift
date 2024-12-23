//
//  TextFieldWithTitle.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.09.2024.
//

import UIKit
import SnapKit


final class GeneralCaseTextField: UIView {
    private let textType: FieldType
    private var detailViewModel: UpdatableEntityProtocol?
    
    // MARK: - UI components
    private lazy var titlelbl: UILabel = {
        let vc = UILabel()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.font = .systemFont(ofSize: 16, weight: .bold)
        vc.numberOfLines = 0
        return vc
    }()
    
    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = AppTheme.bgSecondaryColor
        tv.layer.borderWidth = 1
        tv.font = .systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.gray.cgColor
        tv.layer.cornerRadius = 10
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        tv.textContainer.lineBreakMode = .byWordWrapping
        tv.textContainer.maximumNumberOfLines = 0
        return tv
    }()
    
    // MARK: - Lyfecycle
    
    init(textType: FieldType, textViewValue: String? = "", detailVM: UpdatableEntityProtocol? = nil) {
        self.textType = textType
        self.detailViewModel = detailVM
        super.init(frame: .zero)
        
        textView.delegate = self
        titlelbl.text = textType.localized
        textView.text = if let detailVM = detailVM as? CreateSuiteOrCaseViewModel, textType == .parentSuite {
            "\(detailVM.parentSuiteId)"
        } else {
            textView.text.isEmpty ? textViewValue : textView.text
        }
        
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView.resignFirstResponder()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView.resignFirstResponder()
    }
    
    func configureView() {
        self.addSubview(titlelbl)
        titlelbl.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
        }
        
        self.addSubview(textView)
        textView.snp.makeConstraints {
            $0.top.equalTo(titlelbl.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview().priority(.low)
        }
    }
    
    func updateTextViewValue(_ value: String?) {
        textView.text = value
    }
}

extension GeneralCaseTextField: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let maxCharacters = 500
        if textView.text.count > maxCharacters {
            textView.text = String(textView.text.prefix(maxCharacters))
        }
        
        switch textType {
        case .title, .description, .precondition, .postcondition, .code:
            switch textType {
            case .title:
                detailViewModel?.updateValue(for: .title, value: textView.text)
            case .description:
                detailViewModel?.updateValue(for: .description, value: textView.text)
            case .precondition:
                detailViewModel?.updateValue(for: .precondition, value: textView.text)
            case .postcondition:
                detailViewModel?.updateValue(for: .postcondition, value: textView.text)
            case .code:
                detailViewModel?.updateValue(for: .code, value: textView.text)
            default: break
            }
        case .parentSuite:
            detailViewModel?.updateValue(for: .parentSuite, value: Int(textView.text) ?? 0)
        default: break
        }
    }
}
