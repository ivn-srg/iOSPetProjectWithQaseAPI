//
//  TextFieldWithPadding.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 23.10.2024.
//

import UIKit

final class TextFieldWithPadding: UITextField {
    private struct Layout { static let inputInset: CGFloat = 10 }
    var textPadding = UIEdgeInsets(
        top: Layout.inputInset,
        left: Layout.inputInset,
        bottom: Layout.inputInset,
        right: Layout.inputInset
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

extension TextFieldWithPadding: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.layer.borderColor = AppTheme.Palette.accent.cgColor
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        textField.layer.borderColor = UIColor.gray.cgColor
    }
}
