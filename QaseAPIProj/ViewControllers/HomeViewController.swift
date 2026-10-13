import SwiftUI
import UIKit

@MainActor
final class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel
    private let router: HomeRouting
    private var hostingController: UIHostingController<HomeView>?

    init(viewModel: HomeViewModel, router: HomeRouting) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.Palette.canvas
        navigationItem.title = "Home".localized
        let hosting = UIHostingController(rootView: HomeView(viewModel: viewModel, router: router))
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
        hostingController = hosting
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshOnForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.appear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.disappear()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @objc private func refreshOnForeground() {
        if viewIfLoaded?.window != nil { viewModel.refresh() }
    }
}
