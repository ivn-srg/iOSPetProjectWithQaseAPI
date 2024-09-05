//
//  GeneralDetailCaseViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class GeneralDetailCaseViewController: UIViewController, UpdateDataInVCProtocol {
    
    let vm: DetailTabbarControllerViewModel
    weak var delegate: SwipeTabbarProtocol?
    
    private lazy var viewCn: UIView = {
        let vc = UIView()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.backgroundColor = .white
        return vc
    }()
    
    private lazy var titlelbl: UILabel = {
        let vc = UILabel()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.font = .systemFont(ofSize: 15, weight: .bold)
        return vc
    }()
    
    private var titleField: UITextView = {
        let decslbl = UITextView()
        decslbl.translatesAutoresizingMaskIntoConstraints = false
        decslbl.backgroundColor = .white
        decslbl.isScrollEnabled = false
        decslbl.layer.borderWidth = 1.0
        decslbl.layer.borderColor = UIColor.gray.cgColor
        decslbl.layer.cornerRadius = 8.0
        return decslbl
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
    
    private lazy var panRecognize: UISwipeGestureRecognizer = {
        let gestureRecognizer = UISwipeGestureRecognizer()
        gestureRecognizer.addTarget(self, action: #selector(swipeBetweenViewsDelegate))
        return gestureRecognizer
    }()
    
    // MARK: - Lifecycle

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
        updateUI()
    }
    
    private func setupView() {
        titlelbl.text = "Title"
        descriptionlbl.text = "Description"
        preconditionlbl.text = "Pre-condition"
        postconditionlbl.text = "Post-condition"
        
        view.addSubview(viewCn)
        view.addSubview(titlelbl)
        view.addSubview(titleField)
        view.addSubview(descriptionlbl)
        view.addSubview(descriptionField)
        view.addSubview(preconditionlbl)
        view.addSubview(preconditionField)
        view.addSubview(postconditionlbl)
        view.addSubview(postconditionField)
        view.addGestureRecognizer(panRecognize)
        
        NSLayoutConstraint.activate([
            viewCn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            viewCn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            viewCn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            viewCn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            titlelbl.topAnchor.constraint(equalTo: viewCn.topAnchor, constant: 30),
            titlelbl.centerXAnchor.constraint(equalTo: viewCn.centerXAnchor),
            titlelbl.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30),
            titlelbl.trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30),
            
            titleField.topAnchor.constraint(equalTo: titlelbl.bottomAnchor, constant: 5),
            titleField.centerXAnchor.constraint(equalTo: viewCn.centerXAnchor),
            titleField.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30),
            titleField.trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30),
            
            descriptionlbl.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 20),
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
    
    @objc func swipeBetweenViewsDelegate() {
        self.delegate?.swipeBetweenViews(panRecognize)
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            self.titleField.text = self.vm.testCase?.title ?? "Not set"
            self.descriptionField.text = self.vm.testCase?.description ?? "Not set"
            self.preconditionField.text = self.vm.testCase?.preconditions ?? "Not set"
            self.postconditionField.text = self.vm.testCase?.postconditions ?? "Not set"
            LoadingIndicator.stopLoading()
        }
    }
    
    @objc func pull2Refresh() {
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
}
