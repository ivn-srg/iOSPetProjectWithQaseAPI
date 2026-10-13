import SnapKit
import UIKit

final class AuthViewController: UIViewController {
    private let auth: AuthServicing
    private var loginTask: Task<Void, Never>?
    private var requestID: UUID?
    private var state = AuthScreenState.idle
    private let scrollView = UIScrollView()
    private let content = UIStackView()
    private let logoImg = UIImageView(image: AppImages.logo)
    private let inputTokenField = AuthTokenTextField()
    private let visibilityButton = UIButton(type: .system)
    private let visibilityIcon = UIImageView()
    private let authButton = AuthActionButton(primary: true)
    private let demoButton = AuthActionButton(primary: false)
    private let messageLabel = UILabel()
    private let messageIcon = UIImageView(image: AppImages.exclamationmarkCircle)
    private lazy var message = UIStackView(arrangedSubviews: [messageIcon, messageLabel])
    private var topConstraint: Constraint?
    private var inputHeightConstraint: Constraint?
    private var topInset = AppTheme.Space.section

    init(auth: AuthServicing) {
        self.auth = auth
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        loginTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        registerForTraitChanges([
            UITraitUserInterfaceStyle.self,
            UITraitPreferredContentSizeCategory.self
        ]) { (controller: Self, _) in
            controller.refreshTraits()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(revealInput),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
        render()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = scrollView.bounds.width - AppTheme.Space.screen * 2
        guard width > 0 else { return }
        let height = content.systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let inset = max(
            AppTheme.Space.section,
            (scrollView.bounds.height - height) / 2 - AppTheme.Space.large
        )
        // Updating only the changed inset avoids repeatedly invalidating layout.
        if abs(topInset - inset) > 0.5 {
            topInset = inset
            topConstraint?.update(offset: inset)
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        if parent == nil { stopLogin() }
        super.willMove(toParent: parent)
    }

    private func setup() {
        view.accessibilityIdentifier = AccessibilityID.authScreen.identifier
        view.backgroundColor = AppTheme.Palette.canvas
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        content.axis = .vertical
        content.spacing = AppTheme.Space.regular
        scrollView.addSubview(content)
        content.snp.makeConstraints {
            topConstraint = $0.top.equalTo(scrollView.contentLayoutGuide.snp.top)
                .offset(AppTheme.Space.section).constraint
            $0.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom).inset(AppTheme.Space.section)
            $0.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(AppTheme.Space.screen)
            $0.width.equalTo(scrollView.frameLayoutGuide).offset(-AppTheme.Space.screen * 2)
        }

        let logoContainer = UIView()
        logoContainer.addSubview(logoImg)
        logoImg.contentMode = .scaleAspectFit
        logoImg.isUserInteractionEnabled = true
        logoImg.accessibilityIdentifier = AccessibilityID.logoImg.identifier
        logoImg.accessibilityLabel = "Qase"
        logoImg.isAccessibilityElement = true
        let ratio = (logoImg.image?.size.height ?? 54) / (logoImg.image?.size.width ?? 136)
        logoImg.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.bottom.equalToSuperview()
            $0.width.equalTo(Layout.logoWidth)
            $0.height.equalTo(Layout.logoWidth * ratio)
        }
        logoImg.addGestureRecognizer(UILongPressGestureRecognizer(
            target: self,
            action: #selector(openDemoByLongPress(_:))
        ))
        let title = makeLabel("Sign in to Qase", font: AppTheme.Typography.screenUIKit, centered: true)
        title.accessibilityTraits.insert(.header)
        let subtitle = makeLabel(
            "Enter your API token to access your projects",
            font: .preferredFont(forTextStyle: .subheadline),
            centered: true
        )
        subtitle.textColor = AppTheme.Palette.secondaryText
        let subtitleContainer = UIView()
        subtitleContainer.addSubview(subtitle)
        subtitle.snp.makeConstraints {
            $0.centerX.top.bottom.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.width.lessThanOrEqualTo(Layout.descriptionWidth)
            $0.width.equalToSuperview().priority(750)
        }
        let tokenTitle = makeLabel("API token", font: AppTheme.Typography.metadataUIKit)
        tokenTitle.isAccessibilityElement = false
        let fieldGroup = UIStackView(arrangedSubviews: [tokenTitle, inputTokenField])
        fieldGroup.axis = .vertical
        fieldGroup.spacing = AppTheme.Space.small
        setupTokenField()
        setupMessage()
        authButton.accessibilityIdentifier = AccessibilityID.authButton.identifier
        demoButton.accessibilityIdentifier = AccessibilityID.authDemo.identifier
        authButton.addTarget(self, action: #selector(startLogin), for: .touchUpInside)
        demoButton.addTarget(self, action: #selector(startDemo), for: .touchUpInside)
        [logoContainer, title, subtitleContainer, fieldGroup, message, authButton, demoButton]
            .forEach(content.addArrangedSubview)
        content.setCustomSpacing(AppTheme.Space.section, after: logoContainer)
        content.setCustomSpacing(AppTheme.Space.small, after: title)
        content.setCustomSpacing(AppTheme.Space.large, after: subtitleContainer)
        content.setCustomSpacing(AppTheme.Space.medium, after: authButton)
    }

    private func setupTokenField() {
        inputTokenField.delegate = self
        inputTokenField.accessibilityIdentifier = AccessibilityID.inputTextField.identifier
        inputTokenField.accessibilityLabel = "API token".localized
        inputTokenField.backgroundColor = AppTheme.Palette.secondarySurface
        inputTokenField.textColor = AppTheme.Palette.text
        inputTokenField.font = AppTheme.Typography.bodyUIKit
        inputTokenField.adjustsFontForContentSizeCategory = true
        inputTokenField.layer.cornerRadius = AppTheme.Radius.control
        inputTokenField.layer.borderWidth = 1
        inputTokenField.isSecureTextEntry = true
        inputTokenField.autocorrectionType = .no
        inputTokenField.autocapitalizationType = .none
        inputTokenField.spellCheckingType = .no
        inputTokenField.keyboardType = .asciiCapable
        inputTokenField.returnKeyType = .go
        inputTokenField.enablesReturnKeyAutomatically = true
        inputTokenField.addTarget(self, action: #selector(tokenChanged), for: .editingChanged)
        inputTokenField.snp.makeConstraints {
            inputHeightConstraint = $0.height.greaterThanOrEqualTo(Layout.controlHeight).constraint
        }

        let keyContainer = UIView(frame: CGRect(
            x: 0,
            y: 0,
            width: AppTheme.Size.touch,
            height: Layout.controlHeight
        ))
        let key = UIImageView(image: UIImage(symbol: .key))
        key.contentMode = .scaleAspectFit
        key.tintColor = AppTheme.Palette.secondaryText
        key.isAccessibilityElement = false
        keyContainer.addSubview(key)
        key.snp.makeConstraints {
            $0.width.height.equalTo(AppTheme.Size.actionIcon)
            $0.center.equalToSuperview()
        }
        inputTokenField.leftView = keyContainer
        inputTokenField.leftViewMode = .always
        visibilityButton.frame = CGRect(x: 0, y: 0, width: AppTheme.Size.touch, height: Layout.controlHeight)
        visibilityButton.accessibilityIdentifier = AccessibilityID.authTokenVisibility.identifier
        visibilityIcon.contentMode = .scaleAspectFit
        visibilityIcon.tintColor = AppTheme.Palette.secondaryText
        visibilityIcon.isAccessibilityElement = false
        visibilityIcon.isUserInteractionEnabled = false
        visibilityButton.addSubview(visibilityIcon)
        visibilityIcon.snp.makeConstraints {
            $0.width.height.equalTo(AppTheme.Size.actionIcon)
            $0.center.equalToSuperview()
        }
        visibilityButton.addTarget(self, action: #selector(toggleTokenVisibility), for: .touchUpInside)
        inputTokenField.rightView = visibilityButton
        inputTokenField.rightViewMode = .always

        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(
                title: "Done".localized,
                style: .done,
                target: self,
                action: #selector(closeKeyboard)
            )
        ]
        toolbar.sizeToFit()
        inputTokenField.inputAccessoryView = toolbar
        refreshTraits()
    }

    private func setupMessage() {
        message.axis = .horizontal
        message.alignment = .top
        message.spacing = AppTheme.Space.small
        message.accessibilityIdentifier = AccessibilityID.authMessage.identifier
        message.isAccessibilityElement = true
        messageIcon.contentMode = .scaleAspectFit
        messageIcon.isAccessibilityElement = false
        messageIcon.snp.makeConstraints {
            $0.width.equalTo(AppTheme.Size.actionIcon)
            $0.height.equalTo(AppTheme.Size.actionIcon).priority(999)
        }
        messageLabel.font = AppTheme.Typography.metadataUIKit
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.numberOfLines = 0
        messageLabel.isAccessibilityElement = false
        message.isHidden = true
    }

    private func makeLabel(_ key: String, font: UIFont, centered: Bool = false) -> UILabel {
        let label = UILabel()
        label.text = key.localized
        label.font = font
        label.textColor = AppTheme.Palette.text
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = centered ? .center : .natural
        return label
    }

    private func refreshTraits() {
        let font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
        inputTokenField.font = font
        messageLabel.font = .preferredFont(forTextStyle: .footnote, compatibleWith: traitCollection)
        inputTokenField.attributedPlaceholder = NSAttributedString(
            string: "Enter API token".localized,
            attributes: [.foregroundColor: AppTheme.Palette.secondaryText, .font: font]
        )
        inputHeightConstraint?.update(offset: max(
            Layout.controlHeight,
            font.lineHeight + AppTheme.Space.section
        ))
        render()
        view.setNeedsLayout()
    }

    private func render() {
        let busy = state.operation != nil
        inputTokenField.isEnabled = !busy
        visibilityButton.isEnabled = !busy
        authButton.isEnabled = !busy && !(inputTokenField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        demoButton.isEnabled = !busy
        authButton.present(
            title: (state.operation == .token ? "Checking…" : "Sign in").localized,
            loading: state.operation == .token
        )
        demoButton.present(
            title: (state.operation == .demo ? "Opening demo…" : "Try demo").localized,
            loading: state.operation == .demo
        )
        visibilityIcon.image = UIImage(
            symbol: inputTokenField.isSecureTextEntry ? .eyeSlash : .eye,
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: AppTheme.Size.actionIcon,
                weight: .regular
            )
        )
        visibilityButton
            .accessibilityLabel = (inputTokenField.isSecureTextEntry ? "Show token" : "Hide token").localized
        visibilityButton.accessibilityValue = (inputTokenField.isSecureTextEntry ? "Hidden" : "Visible")
            .localized
        message.isHidden = state.failure == nil
        messageLabel.text = state.failure?.key.localized
        message.accessibilityLabel = messageLabel.text
        let color = state.failure?.warning == true ? AppTheme.Palette.warning : AppTheme.Palette.danger
        messageLabel.textColor = color
        messageIcon.tintColor = color
        let border: UIColor
        if state.failure?.marksTokenInvalid == true { border = AppTheme.Palette.danger }
        else if inputTokenField.isFirstResponder { border = AppTheme.Palette.accent }
        else { border = AppTheme.Palette.strongBorder }
        inputTokenField.layer.borderColor = border.resolvedColor(with: traitCollection).cgColor
    }

    @objc private func tokenChanged() {
        guard state.operation == nil else { return }
        state = .idle
        render()
    }

    @objc private func toggleTokenVisibility() {
        guard state.operation == nil else { return }
        let text = inputTokenField.text ?? ""
        let selected = inputTokenField.selectedTextRange.map {
            (
                inputTokenField.offset(from: inputTokenField.beginningOfDocument, to: $0.start),
                inputTokenField.offset(from: inputTokenField.beginningOfDocument, to: $0.end)
            )
        }
        inputTokenField.isSecureTextEntry.toggle()
        inputTokenField.text = text
        if let selected,
           let start = inputTokenField.position(
               from: inputTokenField.beginningOfDocument,
               offset: selected.0
           ),
           let end = inputTokenField.position(from: inputTokenField.beginningOfDocument, offset: selected.1) {
            inputTokenField.selectedTextRange = inputTokenField.textRange(from: start, to: end)
        }
        render()
    }

    @objc private func closeKeyboard() { view.endEditing(true) }

    @objc private func revealInput() {
        guard inputTokenField.isFirstResponder else { return }
        revealForm()
    }

    private func revealForm() {
        view.layoutIfNeeded()
        let fieldRect = inputTokenField.convert(inputTokenField.bounds, to: scrollView)
        let actionRect = authButton.convert(authButton.bounds, to: scrollView)
        let region = fieldRect.union(actionRect).insetBy(dx: 0, dy: -AppTheme.Space.medium)
        let target = region.height <= scrollView.bounds.height
            ? region : fieldRect.insetBy(dx: 0, dy: -AppTheme.Space.medium)
        scrollView.scrollRectToVisible(target, animated: true)
    }

    @objc private func startLogin() {
        let token = (inputTokenField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { return }
        start(token: token, operation: .token)
    }

    @objc private func startDemo() { start(token: "QASE_DEMO", operation: .demo) }

    @objc private func openDemoByLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        startDemo()
    }

    private func start(token: String, operation: AuthOperation) {
        guard requestID == nil else { return }
        let id = UUID()
        requestID = id
        state = .loading(operation)
        view.endEditing(true)
        render()
        let service = auth
        // Do not promote self across await: the root may remove this screen during login.
        loginTask = Task { @MainActor [weak self, service] in
            var failure: AuthFailure?
            do {
                try Task.checkCancellation()
                try await service.loggedIn(token: token)
            } catch is CancellationError {
                // Cancellation is not an authentication failure.
            } catch let error as URLError where error.code == .cancelled {
                // URLSession can report cancellation with URLError instead.
            } catch {
                failure = AuthFailure.make(error, operation: operation)
            }
            guard !Task.isCancelled else { return }
            self?.finish(id: id, failure: failure)
        }
    }

    private func finish(id: UUID, failure: AuthFailure?) {
        guard requestID == id else { return }
        requestID = nil
        loginTask = nil
        state = failure.map(AuthScreenState.failed) ?? .idle
        render()
        if let failure {
            revealForm()
            UIAccessibility.post(notification: .announcement, argument: failure.key.localized)
        }
    }

    private func stopLogin() {
        requestID = nil
        loginTask?.cancel()
        loginTask = nil
    }
}

extension AuthViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        startLogin()
        return false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        render()
        revealForm()
    }

    func textFieldDidEndEditing(_ textField: UITextField) { render() }
}

private enum AuthOperation: Equatable { case token, demo }

private enum AuthScreenState {
    case idle
    case loading(AuthOperation)
    case failed(AuthFailure)

    var operation: AuthOperation? {
        if case .loading(let operation) = self { return operation }
        return nil
    }

    var failure: AuthFailure? {
        if case .failed(let failure) = self { return failure }
        return nil
    }
}

private struct AuthFailure {
    let key: String
    var warning = false
    var marksTokenInvalid = false

    static func make(_ error: Error, operation: AuthOperation) -> Self {
        if error is KeychainError { return Self(key: "Could not save API token. Try again.") }
        if let network = error as? API.NetError {
            switch network {
            case .invalidCredantials, .httpError(statusCode: 401, message: _, retryAfter: _):
                return operation == .token
                    ? Self(key: "Invalid API token. Check it and try again.", marksTokenInvalid: true)
                    : Self(key: "Could not open demo. Try again.")
            case .httpError(statusCode: 403, message: _, retryAfter: _):
                return Self(key: "Could not verify access with this token")
            case .httpError(statusCode: 429, message: _, retryAfter: _):
                return Self(key: "Too many attempts. Try again later.")
            case .httpError(let status, _, _) where (500 ... 599).contains(status):
                return Self(key: "Qase is temporarily unavailable. Try again later.")
            case .noInternetConnection:
                return Self(
                    key: "Could not connect. Check your internet connection and try again.",
                    warning: true
                )
            case .timeout:
                return Self(key: "Token verification timed out. Try again.", warning: true)
            default: break
            }
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost,
                 .dnsLookupFailed:
                return Self(
                    key: "Could not connect. Check your internet connection and try again.",
                    warning: true
                )
            case .timedOut:
                return Self(key: "Token verification timed out. Try again.", warning: true)
            default: break
            }
        }
        return Self(key: operation == .demo ? "Could not open demo. Try again." :
            "Could not sign in. Try again.")
    }
}

private final class AuthTokenTextField: UITextField {
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(x: bounds.minX, y: bounds.minY, width: AppTheme.Size.touch, height: bounds.height)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(
            x: bounds.maxX - AppTheme.Size.touch,
            y: bounds.minY,
            width: AppTheme.Size.touch,
            height: bounds.height
        )
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect { tokenTextRect(in: bounds) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { tokenTextRect(in: bounds) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { tokenTextRect(in: bounds) }

    private func tokenTextRect(in bounds: CGRect) -> CGRect {
        let horizontalInset = AppTheme.Size.touch + AppTheme.Space.small
        return CGRect(
            x: bounds.minX + horizontalInset,
            y: bounds.minY + AppTheme.Space.medium,
            width: max(0, bounds.width - horizontalInset * 2),
            height: max(0, bounds.height - AppTheme.Space.medium * 2)
        )
    }
}

private final class AuthActionButton: UIButton {
    private let primary: Bool
    private let caption = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let gradient = CAGradientLayer()
    private let contrast = CALayer()
    private var heightConstraint: Constraint?

    init(primary: Bool) {
        self.primary = primary
        super.init(frame: .zero)
        layer.cornerRadius = AppTheme.Radius.control
        clipsToBounds = true
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradient, at: 0)
        contrast.backgroundColor = UIColor.black.withAlphaComponent(AppTheme.Palette.buttonContrastOverlay)
            .cgColor
        layer.insertSublayer(contrast, above: gradient)
        caption.numberOfLines = 0
        caption.textAlignment = .center
        caption.adjustsFontForContentSizeCategory = true
        caption.isAccessibilityElement = false
        spinner.hidesWhenStopped = true
        spinner.isAccessibilityElement = false
        let stack = UIStackView(arrangedSubviews: [spinner, caption])
        stack.alignment = .center
        stack.spacing = AppTheme.Space.small
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(AppTheme.Space.regular)
            $0.trailing.lessThanOrEqualToSuperview().inset(AppTheme.Space.regular)
            $0.top.greaterThanOrEqualToSuperview().offset(AppTheme.Space.medium)
            $0.bottom.lessThanOrEqualToSuperview().inset(AppTheme.Space.medium)
        }
        snp.makeConstraints {
            heightConstraint = $0.height
                .greaterThanOrEqualTo(primary ? Layout.controlHeight : AppTheme.Size.button)
                .constraint
        }
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.88 : 1 }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = bounds
        contrast.frame = bounds
        CATransaction.commit()
    }

    func present(title: String, loading: Bool) {
        caption.text = title
        accessibilityLabel = title
        caption.font = UIFontMetrics(forTextStyle: .body).scaledFont(
            for: .systemFont(ofSize: 17, weight: .medium),
            compatibleWith: traitCollection
        )
        heightConstraint?.update(offset: max(
            primary ? Layout.controlHeight : AppTheme.Size.button,
            caption.font.lineHeight + AppTheme.Space.section
        ))
        if loading { spinner.startAnimating() }
        else { spinner.stopAnimating() }
        spinner.isHidden = !loading
        let filled = primary && (isEnabled || loading)
        gradient.isHidden = !filled
        contrast.isHidden = !filled
        gradient.colors = [AppTheme.Palette.buttonStart, AppTheme.Palette.buttonEnd]
            .map { $0.resolvedColor(with: traitCollection).cgColor }
        backgroundColor = AppTheme.Palette.secondarySurface
        caption
            .textColor = filled ? .white :
            (isEnabled ? AppTheme.Palette.accent : AppTheme.Palette.secondaryText)
        spinner.color = caption.textColor
    }
}

private struct Layout {
    static let logoWidth: CGFloat = 136
    static let controlHeight: CGFloat = 52
    static let descriptionWidth: CGFloat = 320
}
