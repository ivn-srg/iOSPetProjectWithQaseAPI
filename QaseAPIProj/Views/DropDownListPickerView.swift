//
//  DropDownListPickerView.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 30.01.2024.
//

import UIKit

class DropDownListPickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var data = [String]()
    var textField = UITextField()
    var pickerView = UIPickerView()
    
    func setupPickerView() {
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    
    // MARK: UIPickerViewDelegate & UIPickerViewDataSource
    
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
