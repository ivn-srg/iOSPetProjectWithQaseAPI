//
//  TilesCollectionViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 03/09/2026.
//

import UIKit

protocol TileCollectionItem {
    var iconImage: UIImage { get }
    var title: String { get }
    var subtitle: String { get }
}

// MARK: - Layout constants

private enum TileMetrics {
    static let iconSide: CGFloat = 35
    static let minTileWidth: CGFloat = 76
    static let contentInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
    static let stackSpacing: CGFloat = 5
    static let interitemSpacing: CGFloat = 5
    static let sectionInset = UIEdgeInsets(top: 5, left: 16, bottom: 5, right: 16)
    static let cornerRadius: CGFloat = 12
}

// MARK: - Collection view

final class TilesCollectionView: UICollectionView {

    /// Прототип для расчёта размеров. Не попадает в иерархию и не переиспользуется.
    private let sizingCell = TileCollectionViewCell()

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = TileMetrics.interitemSpacing
        layout.minimumInteritemSpacing = TileMetrics.interitemSpacing
        layout.sectionInset = TileMetrics.sectionInset

        super.init(frame: .zero, collectionViewLayout: layout)

        backgroundColor = .clear
        showsHorizontalScrollIndicator = false
        alwaysBounceHorizontal = true
        alwaysBounceVertical = false
        register(
            TileCollectionViewCell.self,
            forCellWithReuseIdentifier: TileCollectionViewCell.identifier
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Размер ячейки под item — считается по её собственным констрейнтам.
    func itemSize(for item: TileCollectionItem) -> CGSize {
        sizingCell.sizeFitting(item)
    }

    /// Высота, достаточная для самой высокой ячейки плюс отступы секции.
    func contentHeight(for items: [TileCollectionItem]) -> CGFloat {
        guard !items.isEmpty else { return 0 }

        let tallest = items.map { itemSize(for: $0).height }.max() ?? 0
        return tallest + TileMetrics.sectionInset.top + TileMetrics.sectionInset.bottom
    }
}

// MARK: - Cell

final class TileCollectionViewCell: UICollectionViewCell {

    static let identifier = "TileCollectionViewCell"

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .vertical)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    /// Задаёт и вертикальную цепочку, и ширину ячейки: контент внутри стека
    /// определяет его ширину, а стек через свои inset'ы — ширину contentView.
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = TileMetrics.stackSpacing
        return stack
    }()

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        iconImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
    }

    private func setup() {
        backgroundColor = .secondarySystemBackground
        if #available(iOS 26.0, *) {
            cornerConfiguration = .corners(radius: .fixed(TileMetrics.cornerRadius))
        } else {
            layer.cornerRadius = TileMetrics.cornerRadius
        }
        clipsToBounds = true

        // contentView намеренно остаётся на autoresizing-маске: UIKit сам
        // синхронизирует его с bounds ячейки, а собственные констрейнты на нём
        // дают варнинг о missing constraints to the cell.
        contentView.addSubview(stackView)

        iconImageView.snp.makeConstraints {
            $0.size.equalTo(TileMetrics.iconSide)
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(TileMetrics.contentInsets)
            $0.width.greaterThanOrEqualTo(
                TileMetrics.minTileWidth - TileMetrics.contentInsets.left - TileMetrics.contentInsets.right
            )
        }
    }

    func configure(with item: TileCollectionItem) {
        iconImageView.image = item.iconImage
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }

    /// Размер под конкретный item. Считается на contentView, минуя
    /// `UIView-Encapsulated-Layout-*`, которые UIKit ставит на саму ячейку.
    func sizeFitting(_ item: TileCollectionItem) -> CGSize {
        configure(with: item)

        return contentView.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}
