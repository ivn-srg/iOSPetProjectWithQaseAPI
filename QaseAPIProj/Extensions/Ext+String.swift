//
//  Ext+LocalizableString.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 28.10.2024.
//

import Foundation
import UIKit
import Down

// MARK: - Localized
extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}

// MARK: - toAttributedString
extension String {
    func toAttributedString() -> NSAttributedString? {
        // TODO: - добавить покраску для темизации
        let data = Down(markdownString: self)
        return try? data.toAttributedString()
    }
}

