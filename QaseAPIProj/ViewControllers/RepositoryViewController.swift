import SwiftUI
import UIKit
import Combine

final class RepositoryViewController: UIHostingController<RepositoryView> {
    let model: TestEntitiesViewModel
    private weak var router: RepositoryRouting?
    private var task: Task<Void, Never>?
    private var modelSubscription: AnyCancellable?
    init(model: TestEntitiesViewModel, selection: SelectedProjectStore, router: RepositoryRouting) {
        self.model = model; self.router = router
        super.init(rootView: RepositoryView(model: model, selection: selection, router: router))
    }
    required dynamic init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.Palette.canvas
        title = "Repository".localized
        navigationItem.largeTitleDisplayMode = .always
        let create = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
            guard let self, !self.model.levelUnavailable else { return }
            self.router?.createEntity(in: self.model.location)
        })
        create.accessibilityLabel = "Create entity".localized
        create.accessibilityIdentifier = "repository.create"
        navigationItem.rightBarButtonItem = create
        updateCreateAvailability()
        modelSubscription = model.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in
            self?.updateCreateAvailability()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        task?.cancel()
        task = Task { [weak self] in await self?.model.reload() }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        task?.cancel(); model.cancel()
    }
    private func updateCreateAvailability() {
        navigationItem.rightBarButtonItem?.isEnabled = !model.levelUnavailable
    }
    deinit { task?.cancel() }
}
