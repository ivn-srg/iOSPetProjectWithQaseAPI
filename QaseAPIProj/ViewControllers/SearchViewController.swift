//
//  SearchViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 02/09/2026.
//

import UIKit

final class SearchViewController: UIViewController, UISearchResultsUpdating {

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        controller.searchBar.placeholder = "Поиск"
        controller.searchBar.autocapitalizationType = .none
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Поиск"
        view.backgroundColor = .systemBackground
        configureNavigationItem()
    }

    private func configureNavigationItem() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        if #available(iOS 26.0, *) {
            navigationItem.preferredSearchBarPlacement = .integrated
        }

        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "line.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(didTapMenu)
        )

        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: self,
            action: #selector(didTapFilter)
        )

        navigationItem.leftBarButtonItem = menuButton
        navigationItem.rightBarButtonItem = filterButton

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = nil

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    @objc private func didTapMenu() {
        print("Меню")
    }

    @objc private func didTapFilter() {
        print("Фильтр")
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, !text.isEmpty else { return }
        print("Поиск: \(text)")
    }
}
