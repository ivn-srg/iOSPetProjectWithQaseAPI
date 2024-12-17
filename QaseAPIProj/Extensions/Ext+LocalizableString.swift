//
//  Ext+LocalizableString.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 28.10.2024.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
