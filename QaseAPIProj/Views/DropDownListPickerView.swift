//
//  DropDownListPickerView.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 30.01.2024.
//

import UIKit

class DropDownListPickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    
//    let viewModel: DropDownListPickerViewModel
    
    var data = [Constants.Severity.blocker.rawValue, Constants.Severity.critical.rawValue]
    var textField = UITextField()
    var pickerView = UIPickerView()
    
    func setupPickerView() {
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    
    // MARK: - UIPickerViewDelegate & UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        textField.text = data[row]
    }
}

class GenericPickerView<T>: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var items: [T] = []
    var didSelectItem: ((T) -> Void)?
    
    init(items: [T]) {
        super.init(frame: .zero)
        self.items = items
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        self.dataSource = self
        self.delegate = self
    }
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items.count
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(items[row])"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedItem = items[row]
        didSelectItem?(selectedItem)
    }
}
