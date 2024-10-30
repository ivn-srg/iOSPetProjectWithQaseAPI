//
//  ButtonWithLeadingImage.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 29.10.2024.
//

import UIKit

final class ButtonWithLeadingImage: UIView {
    // MARK: - Fields
    let leadingImage: UIImage?
    let title: String?
    let actionWhileTap: () -> Void
    
    // MARK: - UI components
    private lazy var box: UIView = {
        let box = UIView()
        box.translatesAutoresizingMaskIntoConstraints = false
        return box
    }()
    
    private lazy var leadingImageView: UIImageView = {
        let image = UIImageView(image: leadingImage)
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleButton = UILabel()
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        titleButton.text = title
        titleButton.textColor = .red
        titleButton.textAlignment = .center
        return titleButton
    }()
    
    // MARK: - Lyfecycle
    init(leadingImage: UIImage?, title: String, actionWhileTouch: @escaping () -> Void) {
        self.leadingImage = leadingImage
        self.title = title
        self.actionWhileTap = actionWhileTouch
        super.init(frame: .zero)
        configureView()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        addSubview(box)
        box.addSubview(leadingImageView)
        box.addSubview(titleLabel)
        
        box.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(10)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        leadingImageView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTapGesture() {
        actionWhileTap()
    }
}
