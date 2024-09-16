//
//  SwitcherWithTitle.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 16.09.2024.
//

import UIKit

class SwitcherWithTitle: UIView {
    // MARK: - Fields
    
    // MARK: - UI components
    private lazy var titlelbl: UILabel = {
        let vc = UILabel()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.font = .systemFont(ofSize: 20, weight: .bold)
        vc.numberOfLines = 0
        return vc
    }()
    
    private lazy var switcher: UISwitch = {
        let isFS = UISwitch()
        isFS.translatesAutoresizingMaskIntoConstraints = false
        isFS.isUserInteractionEnabled = true
        return isFS
    }()
    
    // MARK: - Lyfecycle
    
    init(testCase: TestEntity?) {
        super.init(frame: .zero)
        
        titlelbl.text = "Is Flaky"
        switcher.isOn = testCase?.isFlaky == 1
        configureView()
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
    
    func updateSwitcherValue(_ value: Bool) {
        switcher.setOn(value, animated: true)
    }
    
    func addSwitchTarget(_ target: Any?, action: Selector, for event: UIControl.Event) {
        switcher.addTarget(target, action: action, for: event)
    }
}
