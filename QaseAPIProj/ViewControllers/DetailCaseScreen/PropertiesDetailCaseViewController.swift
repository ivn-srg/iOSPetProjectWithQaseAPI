//
//  PropertiesDetailCaseViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class PropertiesDetailCaseViewController: UIViewController {
    
    private lazy var viewCn: UIView = {
        let vc = UIView()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.backgroundColor = .white
        return vc
    }()
    
    private lazy var pickerView: UIPickerView = {
        let pv = UIPickerView()
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    // TODO: - Сделать текстовое поле в интеграции с дата пикером для всех выпадающий списков
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    private func setupView() {
        
        view.addSubview(viewCn)
        view.addSubview(textField)
        
        NSLayoutConstraint.activate([
            viewCn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            viewCn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            viewCn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            viewCn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            textField.topAnchor.constraint(equalTo: viewCn.topAnchor, constant: 30),
            textField.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 10),
            textField.trailingAnchor.constraint(equalTo: viewCn.centerXAnchor)
        ])
    }
    
    func setupTextField() {
        textField.inputView = pickerView
//        textField.delegate = self
        textField.placeholder = "Select an option"
        textField.borderStyle = .roundedRect
        
        // Добавь кнопку Done на клавиатуре для закрытия pickerView
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.setItems([doneButton], animated: false)
        
        textField.inputAccessoryView = toolbar
        
        
    }
    
    // Метод, который вызывается при нажатии на кнопку Done
    @objc func doneButtonTapped() {
        textField.resignFirstResponder() // Скрыть клавиатуру
    }
}
