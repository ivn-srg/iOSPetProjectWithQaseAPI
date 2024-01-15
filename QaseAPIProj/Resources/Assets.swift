//
//  Assets.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 09.01.2024.
//

import UIKit

enum Assets {
    static let LogoApp = UIImage(named: "FullLogo.png")
    static let notAutomationImage = UIImage(systemName: "hand.raised")?.withTintColor(.systemGray)
    static let toBeAutomationImage = UIImage(systemName: "person.2.badge.gearshape")?.withTintColor(.systemGray)
    static let automationImage = UIImage(systemName: "gearshape.fill")?.withTintColor(.systemGray)
    static let highPriorityImage = UIImage(systemName: "arrow.up")?.withTintColor(.red)
    static let mediumPriorityImage = UIImage(systemName: "circle")?.withTintColor(.systemGray)
    static let lowPriorityImage = UIImage(systemName: "arrow.down")?.withTintColor(.green)
}
