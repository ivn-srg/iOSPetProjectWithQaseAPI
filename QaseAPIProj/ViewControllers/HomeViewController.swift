//
//  HomeViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 02/09/2026.
//

import UIKit

final class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel = .init()

    private lazy var projectDigitsCollectionView: TilesCollectionView = {
        let cv = TilesCollectionView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = "Home".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .search, target: self,
            action: #selector(didTapSearch)
        )

        view.addSubview(projectDigitsCollectionView)

        projectDigitsCollectionView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(0)
        }

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: HomeViewController, _) in
            self.projectDigitsCollectionView.collectionViewLayout.invalidateLayout()
            self.updateTilesHeight()
        }

        updateTilesHeight()
    }

    private func updateTilesHeight() {
        let height = projectDigitsCollectionView.contentHeight(for: viewModel.items)

        projectDigitsCollectionView.snp.updateConstraints {
            $0.height.equalTo(height)
        }
    }
    @objc func didTapSearch() {
        navigationController?.modalPresentationStyle = .fullScreen
        navigationController?.present(SearchViewController(), animated: true)
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        projectDigitsCollectionView.itemSize(for: viewModel.items[indexPath.row])
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TileCollectionViewCell.identifier, for: indexPath) as? TileCollectionViewCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: viewModel.items[indexPath.row])

        return cell
    }
}
