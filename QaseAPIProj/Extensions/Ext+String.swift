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
    var withoutLineBreaks: String {
        self.replacingOccurrences(of: "\n", with: " ")
    }
    
    func toAttributedString() -> NSAttributedString? {
        let attributedString = try? NSMutableAttributedString(
            markdown: self,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        )
        
        guard let attributedString = attributedString else { return nil }
        
        attributedString.beginEditing()
        attributedString.enumerateAttributes(
            in: NSRange(location: 0, length: attributedString.length),
            options: []
        ) { attributes, range, _ in
            if attributes[.link] == nil {
                var updatedAttributes = attributes
                updatedAttributes[.foregroundColor] = UIColor.label
                updatedAttributes[.font] = UIFont.systemFont(ofSize: 14)
                attributedString.setAttributes(updatedAttributes, range: range)
            }
        }
        attributedString.endEditing()
        
        return attributedString
    }
}


