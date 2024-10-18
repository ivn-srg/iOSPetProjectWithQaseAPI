//
//  SuitesAndCasesTableViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 09.01.2024.
//

import UIKit

final class SuitesAndCasesTableViewController: UIViewController {

    var viewModel: SuitesAndCasesViewModel
    
    // MARK: - UI
    
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 44
        tv.register(SuitesAndCasesTableViewCell.self, forCellReuseIdentifier: SuitesAndCasesTableViewCell.cellId)
        return tv
    }()
    
    private let emptyDataLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "There's nothing here yet 🙁"
        label.textAlignment = .center
        label.textColor = .gray
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    func showErrorAlert(titleAlert: String, messageAlert: String) {
        let ac = UIAlertController(title: titleAlert, message: messageAlert, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    // MARK: - Lifecycles
    
    init(parentSuite: ParentSuite? = nil) {
        self.viewModel = parentSuite != nil ? SuitesAndCasesViewModel(parentSuite: parentSuite) : SuitesAndCasesViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.delegate = self
        setupTableView()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewEntity))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        viewModel.requestEntitiesData()
    }
    
    // MARK: - Setuping UI for tableView
    func setupTableView() {
        title = viewModel.parentSuite == nil ? PROJECT_NAME
        : self.viewModel.suitesAndCaseData.filter( {$0.isSuites && $0.id == self.viewModel.parentSuite?.id} ).first?.title
        navigationItem.largeTitleDisplayMode = .never
        
        view.backgroundColor = .white
        
        tableVw.delegate = self
        tableVw.dataSource = self
        
        view.addSubview(tableVw)
        tableVw.addSubview(emptyDataLabel)
        
        tableVw.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide.snp.edges)
        }
        emptyDataLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    private func updateEmptyDataLabelVisibility() {
        emptyDataLabel.isHidden = viewModel.countOfRows() > 0
    }
    
    // MARK: - @objc funcs
    @objc func addNewEntity() {
        let vc = CreateSuiteOrCaseViewController(viewModel: .init())
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}

// MARK: - UpdateTableViewProtocol
extension SuitesAndCasesTableViewController: UpdateTableViewProtocol {
    func updateTableView() {
        DispatchQueue.main.async {
            self.tableVw.reloadData()
        }
    }
}

// MARK: - NextViewControllerPusher
extension SuitesAndCasesTableViewController: NextViewControllerPusher {
    func pushToNextVC(to item: Int?) {
        guard let item = item else { return }
        let vc: UIViewController
        let parentSuite = ParentSuite(id: viewModel.suitesAndCaseData[item].id, title: viewModel.suitesAndCaseData[item].title)
        let caseItem = viewModel.suitesAndCaseData[item]
        
        if viewModel.suitesAndCaseData[item].isSuites {
            vc = SuitesAndCasesTableViewController(parentSuite: parentSuite)
        } else {
            vc = DetailTabBarController(caseId: caseItem.id)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Table view data source
extension SuitesAndCasesTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        updateEmptyDataLabelVisibility()
        return viewModel.suitesAndCaseData.count > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.countOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SuitesAndCasesTableViewCell.cellId, for: indexPath) as? SuitesAndCasesTableViewCell else { return UITableViewCell() }
        
        let dataForCell = viewModel.suitesAndCaseData[indexPath.row]
        cell.configure(with: dataForCell)
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pushToNextVC(to: indexPath.row)
    }
}

extension SuitesAndCasesTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

