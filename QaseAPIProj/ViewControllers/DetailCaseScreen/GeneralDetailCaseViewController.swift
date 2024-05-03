//
//  GeneralDetailCaseViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class GeneralDetailCaseViewController: UIViewController {
    
    var testCaseData: TestEntity?
    let vm: DetailTabbarControllerViewModel
    
    init(vm: DetailTabbarControllerViewModel) {
        self.vm = vm
        self.testCaseData = vm.testCase
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var viewCn: UIView = {
        let vc = UIView()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.backgroundColor = .white
        return vc
    }()
    
    private lazy var descriptionlbl: UILabel = {
        let vc = UILabel()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.font = .systemFont(ofSize: 15, weight: .bold)
        return vc
    }()
    
    private var descriptionField: UITextView = {
        let decslbl = UITextView()
        decslbl.translatesAutoresizingMaskIntoConstraints = false
        decslbl.backgroundColor = .white
        decslbl.isScrollEnabled = false
        decslbl.layer.borderWidth = 1.0
        decslbl.layer.borderColor = UIColor.gray.cgColor
        decslbl.layer.cornerRadius = 8.0
        return decslbl
    }()
    
    private lazy var preconditionlbl: UILabel = {
        let vc = UILabel()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.font = .systemFont(ofSize: 15, weight: .bold)
        return vc
    }()
    
    private var preconditionField: UITextView = {
        let precondlbl = UITextView()
        precondlbl.translatesAutoresizingMaskIntoConstraints = false
        precondlbl.backgroundColor = .white
        precondlbl.isScrollEnabled = false
        precondlbl.layer.borderWidth = 1.0
        precondlbl.layer.borderColor = UIColor.gray.cgColor
        precondlbl.layer.cornerRadius = 8.0
        return precondlbl
    }()
    
    private lazy var postconditionlbl: UILabel = {
        let vc = UILabel()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.font = .systemFont(ofSize: 15, weight: .bold)
        return vc
    }()
    
    private var postconditionField: UITextView = {
        let postcondlbl = UITextView()
        postcondlbl.translatesAutoresizingMaskIntoConstraints = false
        postcondlbl.backgroundColor = .white
        postcondlbl.isScrollEnabled = false
        postcondlbl.layer.borderWidth = 1.0
        postcondlbl.layer.borderColor = UIColor.gray.cgColor
        postcondlbl.layer.cornerRadius = 8.0
        return postcondlbl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    private func setupView() {
        
        descriptionlbl.text = "Description"
        descriptionField.text = testCaseData?.description ?? "Not set"
        preconditionlbl.text = "Pre-condition"
        preconditionField.text = testCaseData?.preconditions ?? "Not set"
        postconditionlbl.text = "Post-condition"
        postconditionField.text = testCaseData?.postconditions ?? "Not set"
        
        view.addSubview(viewCn)
        view.addSubview(descriptionlbl)
        view.addSubview(descriptionField)
        view.addSubview(preconditionlbl)
        view.addSubview(preconditionField)
        view.addSubview(postconditionlbl)
        view.addSubview(postconditionField)
        
        NSLayoutConstraint.activate([
            viewCn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            viewCn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            viewCn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            viewCn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            descriptionlbl.topAnchor.constraint(equalTo: viewCn.topAnchor, constant: 30),
            descriptionlbl.centerXAnchor.constraint(equalTo: viewCn.centerXAnchor),
            descriptionlbl.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30),
            descriptionlbl.trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30),
            
            descriptionField.topAnchor.constraint(equalTo: descriptionlbl.bottomAnchor, constant: 5),
            descriptionField.centerXAnchor.constraint(equalTo: viewCn.centerXAnchor),
            descriptionField.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30),
            descriptionField.trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30),
            
            preconditionlbl.topAnchor.constraint(equalTo: descriptionField.bottomAnchor, constant: 20),
            preconditionlbl.centerXAnchor.constraint(equalTo: viewCn.centerXAnchor),
            preconditionlbl.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30),
            preconditionlbl.trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30),
            
            preconditionField.topAnchor.constraint(equalTo: preconditionlbl.bottomAnchor, constant: 5),
            preconditionField.centerXAnchor.constraint(equalTo: viewCn.centerXAnchor),
            preconditionField.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30),
            preconditionField.trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30),
            
            postconditionlbl.topAnchor.constraint(equalTo: preconditionField.bottomAnchor, constant: 20),
            postconditionlbl.centerXAnchor.constraint(equalTo: viewCn.centerXAnchor),
            postconditionlbl.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30),
            postconditionlbl.trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30),
            
            postconditionField.topAnchor.constraint(equalTo: postconditionlbl.bottomAnchor, constant: 5),
            postconditionField.centerXAnchor.constraint(equalTo: viewCn.centerXAnchor),
            postconditionField.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30),
            postconditionField.trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30),
        ])
    }
    
    @objc func updateUI() {
        DispatchQueue.main.async {
            self.setupView()
        }
    }
}
