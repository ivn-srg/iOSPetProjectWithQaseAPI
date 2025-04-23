//
//  SwitcherWithTitle.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 16.09.2024.
//

import UIKit

final class SwitcherWithTitle: UIView {
    // MARK: - Fields
    var switchValueChanged: ((Bool) -> Void)?
    private var viewModel: UpdatableEntityProtocol?
    
    // MARK: - UI components
    private lazy var titlelbl: UILabel = {
        let vc = UILabel()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.font = .systemFont(ofSize: 16, weight: .bold)
        vc.numberOfLines = 0
        return vc
    }()
    
    private lazy var switcher: UISwitch = {
        let swtch = UISwitch()
        swtch.translatesAutoresizingMaskIntoConstraints = false
        swtch.onTintColor = AppTheme.fioletColor
        return swtch
    }()
    
    // MARK: - Lyfecycle
    
    init(title: String, testCaseVM: UpdatableEntityProtocol?) {
        self.viewModel = testCaseVM
        super.init(frame: .zero)
        
        titlelbl.text = title
        switcher.isOn = viewModel?.testCase?.isFlaky ?? false
        configureView()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        self.addSubview(switcher)
        switcher.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        
        self.addSubview(titlelbl)
        titlelbl.snp.makeConstraints {
            $0.centerY.leading.equalToSuperview()
            $0.trailing.equalTo(switcher.snp.leading).offset(-20)
        }
    }
    
    private func setupActions() {
        switcher.addTarget(self, action: #selector(switchValueDidChange(_:)), for: .valueChanged)
    }
    
    // MARK: - Actions
    @objc private func switchValueDidChange(_ sender: UISwitch) {
        switchValueChanged?(sender.isOn)
    }
    
    func configure(with isOn: Bool) {
        switcher.isOn = isOn
    }
}
