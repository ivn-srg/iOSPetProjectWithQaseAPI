//
//  PropertiesDetailCaseViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class PropertiesDetailCaseViewController: UIViewController, UITextFieldDelegate {
    
    let vm: DetailTabbarControllerViewModel
    
    // MARK: - UI
    
    private lazy var viewCn: UIView = {
        let vc = UIView()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.backgroundColor = .white
        return vc
    }()
    
    private lazy var severitylbl: UILabel = {
        let tf = UILabel()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = .systemFont(ofSize: 15, weight: .bold)
        tf.text = "Severity"
        return tf
    }()
    
    private lazy var statuslbl: UILabel = {
        let tf = UILabel()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = .systemFont(ofSize: 15, weight: .bold)
        tf.text = "Status"
        return tf
    }()
    
    private lazy var prioritylbl: UILabel = {
        let tf = UILabel()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = .systemFont(ofSize: 15, weight: .bold)
        tf.text = "Priority"
        return tf
    }()
    
    private lazy var behaviorlbl: UILabel = {
        let tf = UILabel()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = .systemFont(ofSize: 15, weight: .bold)
        tf.text = "Behavior"
        return tf
    }()
    
    private lazy var typelbl: UILabel = {
        let tf = UILabel()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = .systemFont(ofSize: 15, weight: .bold)
        tf.text = "Type"
        return tf
    }()
    
    private lazy var layerlbl: UILabel = {
        let tf = UILabel()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = .systemFont(ofSize: 15, weight: .bold)
        tf.text = "Layer"
        return tf
    }()
    
    private lazy var automationStatuslbl: UILabel = {
        let tf = UILabel()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = .systemFont(ofSize: 15, weight: .bold)
        tf.text = "Automation Status"
        return tf
    }()
    
    private lazy var severityTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white
        tf.layer.borderWidth = 1.0
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.cornerRadius = 8.0
        return tf
    }()
    
    private lazy var statusTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white
        tf.layer.borderWidth = 1.0
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.cornerRadius = 8.0
        return tf
    }()
    
    private lazy var priorityTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white
        tf.layer.borderWidth = 1.0
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.cornerRadius = 8.0
        return tf
    }()
    
    private lazy var behaviorTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white
        tf.layer.borderWidth = 1.0
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.cornerRadius = 8.0
        return tf
    }()
    
    private lazy var typeTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white
        tf.layer.borderWidth = 1.0
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.cornerRadius = 8.0
        return tf
    }()
    
    private lazy var layerTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white
        tf.layer.borderWidth = 1.0
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.cornerRadius = 8.0
        return tf
    }()
    
    private lazy var automationStatusTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white
        tf.layer.borderWidth = 1.0
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.cornerRadius = 8.0
        return tf
    }()
    
    private lazy var severityPickerView: GenericPickerView<String> = {
        let pv = GenericPickerView<String>(items: Constants.Severity.returnAllEnumCases())
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private lazy var statusPickerView: GenericPickerView<String> = {
        let pv = GenericPickerView<String>(items: Constants.Status.returnAllEnumCases())
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private lazy var priorityPickerView: GenericPickerView<String> = {
        let pv = GenericPickerView<String>(items: Constants.Priority.returnAllEnumCases())
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private lazy var behaviorPickerView: GenericPickerView<String> = {
        let pv = GenericPickerView<String>(items: Constants.Behavior.returnAllEnumCases())
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private lazy var typePickerView: GenericPickerView<String> = {
        let pv = GenericPickerView<String>(items: Constants.Types.returnAllEnumCases())
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private lazy var layerPickerView: GenericPickerView<String> = {
        let pv = GenericPickerView<String>(items: Constants.Layer.returnAllEnumCases())
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private lazy var automationStatusPickerView: GenericPickerView<String> = {
        let pv = GenericPickerView<String>(items: Constants.AutomationStatus.returnAllEnumCases())
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    // MARK: - Lifecycles
    
    init(vm: DetailTabbarControllerViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupTextFields()
    }
    
    private func setupView() {
        let labels = [severitylbl, statuslbl, prioritylbl, behaviorlbl, typelbl, layerlbl, automationStatuslbl]
        let textFields = [severityTextField, statusTextField, priorityTextField, behaviorTextField, typeTextField, layerTextField, automationStatusTextField]
        var listOfNSLayoutConstraint = [NSLayoutConstraint]()
        
        // добавление на супервью и добавление ограничений
        view.addSubview(viewCn)
        listOfNSLayoutConstraint.append(viewCn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
        listOfNSLayoutConstraint.append(viewCn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
        listOfNSLayoutConstraint.append(viewCn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))
        
        // добавление вьюшек на супервью
        for index in 0..<textFields.count {
            view.addSubview(labels[index])
            view.addSubview(textFields[index])
        }
        // добавление ограничений для вьюшек
        for index in 0..<textFields.count {
            if index == 0 {
                listOfNSLayoutConstraint.append(labels[index].topAnchor.constraint(equalTo: viewCn.topAnchor, constant: 30))
                listOfNSLayoutConstraint.append(labels[index].centerXAnchor.constraint(equalTo: viewCn.centerXAnchor))
                listOfNSLayoutConstraint.append(labels[index].leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30))
                listOfNSLayoutConstraint.append(labels[index].trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30))
                
                listOfNSLayoutConstraint.append(textFields[index].topAnchor.constraint(equalTo: labels[index].bottomAnchor, constant: 5))
                listOfNSLayoutConstraint.append(textFields[index].centerXAnchor.constraint(equalTo: viewCn.centerXAnchor))
                listOfNSLayoutConstraint.append(textFields[index].leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30))
                listOfNSLayoutConstraint.append(textFields[index].trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30))
            } else {
                listOfNSLayoutConstraint.append(labels[index].topAnchor.constraint(equalTo: textFields[index - 1].bottomAnchor, constant: 20))
                listOfNSLayoutConstraint.append(labels[index].centerXAnchor.constraint(equalTo: viewCn.centerXAnchor))
                listOfNSLayoutConstraint.append(labels[index].leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30))
                listOfNSLayoutConstraint.append(labels[index].trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30))
                
                listOfNSLayoutConstraint.append(textFields[index].topAnchor.constraint(equalTo: labels[index].bottomAnchor, constant: 5))
                listOfNSLayoutConstraint.append(textFields[index].centerXAnchor.constraint(equalTo: viewCn.centerXAnchor))
                listOfNSLayoutConstraint.append(textFields[index].leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30))
                listOfNSLayoutConstraint.append(textFields[index].trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30))
            }
        }
        
        NSLayoutConstraint.activate(listOfNSLayoutConstraint)
    }
    
    func setupTextFields() {
        let textFields = [severityTextField, statusTextField, priorityTextField, behaviorTextField, typeTextField, layerTextField, automationStatusTextField]
        let pickerViews = [severityPickerView, statusPickerView, priorityPickerView, behaviorPickerView, typePickerView, layerPickerView, automationStatusPickerView]
        
        for index in 0..<textFields.count {
            textFields[index].inputView = pickerViews[index]
            textFields[index].delegate = self
            textFields[index].placeholder = "Select an option"
            textFields[index].borderStyle = .roundedRect
            
            switch textFields[index] {
            case severityTextField:
                textFields[index].text = Constants.Severity.returnAllEnumCases()[vm.testCase?.severity ?? 0]
            case statusTextField:
                textFields[index].text = Constants.Status.returnAllEnumCases()[vm.testCase?.status ?? 0]
            case priorityTextField:
                textFields[index].text = Constants.Priority.returnAllEnumCases()[vm.testCase?.priority ?? 0]
            case behaviorTextField:
                textFields[index].text = Constants.Behavior.returnAllEnumCases()[vm.testCase?.behavior ?? 0]
            case typeTextField:
                textFields[index].text = Constants.Types.returnAllEnumCases()[vm.testCase?.type ?? 0]
            case layerTextField:
                textFields[index].text = Constants.Layer.returnAllEnumCases()[vm.testCase?.layer ?? 0]
            case automationStatusTextField:
                textFields[index].text = Constants.AutomationStatus.returnAllEnumCases()[vm.testCase?.automation ?? 0]
            default:
                textFields[index].text = pickerViews[index].items.first
            }
            
            pickerViews[index].didSelectItem = { selectedItem in
                textFields[index].text = selectedItem
            }
            
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
            toolbar.setItems([doneButton], animated: false)
            
            textFields[index].inputAccessoryView = toolbar
        }
    }
    
    @objc func doneButtonTapped() {
        view.endEditing(true)
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            self.setupTextFields()
            LoadingIndicator.stopLoading()
        }
    }
}
