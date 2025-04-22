//
//  EmptyListLabel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 22.04.2025.
//

import UIKit
import SnapKit

final class EmptyDataLabel: UILabel {
    
    // MARK: - Life cycle
    init() {
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        text = "There's nothing here yet 🙁".localized
        textAlignment = .center
        textColor = .gray
        numberOfLines = 0
        isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
