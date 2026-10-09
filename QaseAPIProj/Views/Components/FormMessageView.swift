import UIKit
import SnapKit

final class FormMessageView: UIView {
    private let label = UILabel()
    private let retryButton = UIButton(type: .system)
    private var retryAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppTheme.Palette.dangerBackground
        layer.cornerRadius = AppTheme.Radius.control
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        icon.tintColor = AppTheme.Palette.danger
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints {
            $0.width.height.equalTo(20)
        }
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = AppTheme.Palette.danger
        label.numberOfLines = 0
        retryButton.setTitle("Retry".localized, for: .normal)
        retryButton.tintColor = AppTheme.Palette.accent
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        retryButton.titleLabel?.adjustsFontForContentSizeCategory = true
        retryButton.addTarget(self, action: #selector(retry), for: .touchUpInside)
        retryButton.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        let message = UIStackView(arrangedSubviews: [icon, label])
        message.alignment = .top
        message.spacing = 8
        let stack = UIStackView(arrangedSubviews: [message, retryButton])
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ message: String, retry: (() -> Void)? = nil) {
        label.text = message
        retryAction = retry
        retryButton.isHidden = retry == nil
        isHidden = false
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    func clear() {
        isHidden = true
        retryAction = nil
    }

    @objc private func retry() { retryAction?() }
}
