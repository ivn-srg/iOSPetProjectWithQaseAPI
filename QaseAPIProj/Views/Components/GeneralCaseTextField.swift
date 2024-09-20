//
//  TextFieldWithTitle.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.09.2024.
//

import UIKit
import SnapKit

enum GeneralCaseTextFieldTypes {
    case name, description, precondition, postcondition, code
}

final class GeneralCaseTextField: UIView {
    private let textType: GeneralCaseTextFieldTypes
    private var detailViewModel: Any?
    private var textViewHeightConstraint: Constraint?
    
    // MARK: - UI components
    private lazy var titlelbl: UILabel = {
        let vc = UILabel()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.font = .systemFont(ofSize: 20, weight: .bold)
        vc.numberOfLines = 0
        return vc
    }()
    
    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.layer.borderWidth = 1.0
        tv.font = .systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.gray.cgColor
        tv.layer.cornerRadius = 8.0
        tv.isUserInteractionEnabled = true
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        tv.textContainer.lineBreakMode = .byWordWrapping
        tv.textContainer.maximumNumberOfLines = 4
        return tv
    }()
    
    // MARK: - Lyfecycle
    
    init(textType: GeneralCaseTextFieldTypes, textViewValue: String = "", detailVM: Any? = nil) {
        self.textType = textType
        self.detailViewModel = detailVM
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
        case .code:
            title = "Project code"
        }
        
        textView.delegate = self
        titlelbl.text = title
        textView.text = textViewValue
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
            self.textViewHeightConstraint = $0.height.equalTo(50).constraint
        }
    }
    
    func updateTextViewValue(_ value: String) {
        textView.text = value
    }
}

extension GeneralCaseTextField: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let maxCharacters = 300
        if textView.text.count > maxCharacters {
            textView.text = String(textView.text.prefix(maxCharacters))
        }
        
        let maxHeight: CGFloat = 150
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = min(size.height, maxHeight)
        
        textViewHeightConstraint?.update(offset: newHeight)
        
        switch textType {
        case .name:
            if let detailViewModel = detailViewModel as? DetailTabbarControllerViewModel {
                detailViewModel.changedTestCase?.title = textView.text
            } else if let detailViewModel = detailViewModel as? CreatingProjectViewModel {
                detailViewModel.creatingProject.title = textView.text
            }
        case .description:
            if let detailViewModel = detailViewModel as? DetailTabbarControllerViewModel {
                detailViewModel.changedTestCase?.description = textView.text
            } else if let detailViewModel = detailViewModel as? CreatingProjectViewModel {
                detailViewModel.creatingProject.description = textView.text
            }
        case .precondition:
            if let detailViewModel = detailViewModel as? DetailTabbarControllerViewModel {
                detailViewModel.changedTestCase?.preconditions = textView.text
            }
        case .postcondition:
            if let detailViewModel = detailViewModel as? DetailTabbarControllerViewModel {
                detailViewModel.changedTestCase?.postconditions = textView.text
            }
        case .code:
            if let detailViewModel = detailViewModel as? CreatingProjectViewModel {
                detailViewModel.creatingProject.code = textView.text
            }
        }
    }
}

