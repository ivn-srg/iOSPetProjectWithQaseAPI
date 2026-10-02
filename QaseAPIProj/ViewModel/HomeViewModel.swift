//
//  HomeViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 03/09/2026.
//

import UIKit

final class HomeViewModel {
    struct ProjectInfoCollectionItem: TileCollectionItem {
        let iconImage: UIImage
        let title: String
        let subtitle: String
    }

    let items: [TileCollectionItem]

    init() {
        let caseImage = AppTheme.textDocumentImage.paint(to: .primaryU)
        let configuredCaseImage = caseImage.applyingSymbolConfiguration(.init(font: .systemFont(ofSize: 18))) ?? caseImage

        items = [
            ProjectInfoCollectionItem(iconImage: configuredCaseImage, title: "249", subtitle: "Кейсы"),
            ProjectInfoCollectionItem(iconImage: AppTheme.squareStackImage.paint(to: .cyan), title: "54", subtitle: "Наборы"),
            ProjectInfoCollectionItem(iconImage: AppTheme.playCircleImage.paint(to: .green), title: "3", subtitle: "Запуски"),
            ProjectInfoCollectionItem(iconImage: AppTheme.bugImage.paint(to: .orange), title: "5", subtitle: "Дефекты")
        ]
    }
}
