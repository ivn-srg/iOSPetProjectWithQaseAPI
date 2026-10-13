import UIKit

final class SuitePickerViewController: UITableViewController, UISearchResultsUpdating,
    UIAdaptivePresentationControllerDelegate {
    private let viewModel: SuitePickerViewModel
    private let onSelection: (Int?) -> Void
    private let search = UISearchController(searchResultsController: nil)
    private var loadTask: Task<Void, Never>?
    private var didChoose = false
    private var footerState: String?
    private var footerWidth: CGFloat = 0

    init(viewModel: SuitePickerViewModel, onSelection: @escaping (Int?) -> Void) {
        self.viewModel = viewModel
        self.onSelection = onSelection
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = FieldType.parentSuite.localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closePicker)
        )
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "suitePicker.close"
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search suites".localized
        search.searchBar.accessibilityIdentifier = "suitePicker.search"
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        tableView.backgroundColor = AppTheme.Palette.canvas
        tableView.tintColor = AppTheme.Palette.accent
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.accessibilityIdentifier = "suitePicker.list"
        viewModel.onChange = { [weak self] in self?.render() }
        render()
        reloadCatalog()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.presentationController?.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed == true || isMovingFromParent {
            cancelLoading()
        }
    }

    deinit { loadTask?.cancel() }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        cancelLoading()
    }

    private func cancelLoading() {
        loadTask?.cancel()
        viewModel.cancel()
    }

    @objc private func closePicker() {
        cancelLoading()
        navigationController?.dismiss(animated: true)
    }

    @objc private func reloadCatalog() {
        loadTask?.cancel()
        viewModel.cancel()
        loadTask = Task { [weak self] in await self?.viewModel.load() }
    }

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.query = searchController.searchBar.text ?? ""
    }

    private func render() {
        guard isViewLoaded else { return }
        tableView.reloadData()
        updateFooter()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFooter()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        footerWidth = 0
        if isViewLoaded { updateFooter() }
    }

    private func updateFooter() {
        let text: String?
        if !viewModel.isSessionCurrent {
            text = "The session is no longer active".localized
        } else if viewModel.isLoading {
            text = "Loading suites".localized
        } else if let error = viewModel.errorMessage {
            text = viewModel.catalogComplete ? error : "Only saved suites are available. Retry to load the full catalog."
                .localized
        } else if viewModel.catalogComplete && viewModel.filteredSuites.isEmpty {
            text = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "The project has no suites yet".localized : "No suites found".localized
        } else {
            text = nil
        }
        let width = max(1, tableView.bounds.width)
        let state = text
            .map {
                "\($0)|\(viewModel.isLoading)|\(viewModel.errorMessage != nil)|\(viewModel.isSessionCurrent)"
            }
        guard state != footerState || abs(width - footerWidth) > 0.5 else { return }
        footerState = state
        footerWidth = width
        guard let text else { tableView.tableFooterView = nil
            return }
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = AppTheme.Palette.secondaryText
        label.textAlignment = .center
        label.accessibilityIdentifier = "suitePicker.status"
        let stack = UIStackView(arrangedSubviews: [label])
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        if viewModel.isLoading {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.color = AppTheme.Palette.accent
            spinner.startAnimating()
            stack.addArrangedSubview(spinner)
        } else if viewModel.errorMessage != nil && viewModel.isSessionCurrent {
            let retry = UIButton(type: .system)
            retry.setTitle("Retry".localized, for: .normal)
            retry.tintColor = AppTheme.Palette.accent
            retry.titleLabel?.font = .preferredFont(forTextStyle: .body)
            retry.titleLabel?.adjustsFontForContentSizeCategory = true
            retry.accessibilityIdentifier = "suitePicker.retry"
            retry.addTarget(self, action: #selector(reloadCatalog), for: .touchUpInside)
            retry.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            stack.addArrangedSubview(retry)
        }
        let size = stack.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        stack.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
        tableView.tableFooterView = stack
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : viewModel.filteredSuites.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? (viewModel.projectTitle ?? viewModel.projectCode) : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let reused = tableView.dequeueReusableCell(withIdentifier: "suitePicker.row") {
            cell = reused
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "suitePicker.row")
            cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        }
        let suite = indexPath.section == 1 ? viewModel.filteredSuites[indexPath.row] : nil
        let id = suite?.id
        cell.textLabel?.text = suite?.title ?? "Project root".localized
        cell.detailTextLabel?.text = suite.map { viewModel.pathTitle(to: $0.id) }
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .footnote)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.textLabel?.textColor = AppTheme.Palette.text
        cell.detailTextLabel?.textColor = AppTheme.Palette.secondaryText
        cell.imageView?.image = UIImage(systemName: "folder")
        cell.imageView?.tintColor = id == viewModel.selectedID ? AppTheme.Palette.accent : AppTheme.Palette
            .secondaryText
        cell.backgroundColor = AppTheme.Palette.secondarySurface
        cell.accessoryType = id == viewModel.selectedID ? .checkmark : .none
        cell.accessibilityIdentifier = id.map { "suitePicker.suite.\($0)" } ?? "suitePicker.root"
        cell.accessibilityLabel = [cell.textLabel?.text, cell.detailTextLabel?.text].compactMap { $0 }
            .joined(separator: ", ")
        cell.accessibilityTraits = id == viewModel.selectedID ? [.button, .selected] : .button
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !didChoose, viewModel.isSessionCurrent else { return }
        didChoose = true
        let id = indexPath.section == 0 ? nil : viewModel.filteredSuites[indexPath.row].id
        cancelLoading()
        onSelection(id)
        navigationController?.dismiss(animated: true)
    }
}
