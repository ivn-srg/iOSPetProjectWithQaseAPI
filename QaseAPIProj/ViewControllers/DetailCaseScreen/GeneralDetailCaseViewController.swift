//
//  GeneralDetailCaseViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

final class GeneralDetailCaseViewController: UIViewController {
    
    private let vm: DetailTabbarControllerViewModel
    weak var delegate: DetailTestCaseProtocol?
    private var isDataEditing = false
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, StepsInTestCase>!
    private var steps: [StepsInTestCase] = []
    
    // MARK: - UI components
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsHorizontalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 30
        sv.alignment = .fill
        return sv
    }()
    
    private lazy var titleField = GeneralCaseTextField(
        textType: .title,
        textViewValue: vm.testCase?.title,
        detailVM: vm
    )
    
    private lazy var descriptionField = GeneralCaseTextField(
        textType: .description,
        textViewValue: vm.testCase?.description,
        detailVM: vm
    )
    
    private lazy var preconditionField = GeneralCaseTextField(
        textType: .precondition,
        textViewValue: vm.testCase?.preconditions,
        detailVM: vm
    )
    
    private lazy var postconditionField = GeneralCaseTextField(
        textType: .postcondition,
        textViewValue: vm.testCase?.postconditions,
        detailVM: vm
    )
    
    private lazy var stepsCollectionViewTitle: UILabel = {
        let vc = UILabel()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.font = .systemFont(ofSize: 16, weight: .bold)
        vc.numberOfLines = 0
        vc.text = "Steps".localized
        return vc
    }()
    
    private lazy var stepsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width - 40, height: 60)
        layout.minimumLineSpacing = 10
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(StepCell.self, forCellWithReuseIdentifier: StepCell.identifier)
        return collectionView
    }()
    
    private lazy var panRecognize: UISwipeGestureRecognizer = {
        let gestureRecognizer = UISwipeGestureRecognizer()
        gestureRecognizer.addTarget(self, action: #selector(swipeBetweenViewsDelegate))
        return gestureRecognizer
    }()
    
    // MARK: - Lifecycle

    init(vm: DetailTabbarControllerViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupCustomFields()
        setupCollectionView()
        loadSteps()
        updateUI()
    }
    
    // MARK: - Setup Methods for UI
    private func setupView() {
        view.addSubview(scrollView)
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.left.right.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.top.equalTo(scrollView.contentLayoutGuide.snp.top).offset(20)
            $0.left.right.equalTo(scrollView.frameLayoutGuide).inset(20)
            $0.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom).offset(-20)
        }
        
        view.addGestureRecognizer(panRecognize)
    }
    
    private func setupCustomFields() {
        stackView.addArrangedSubview(titleField)
        stackView.addArrangedSubview(descriptionField)
        stackView.addArrangedSubview(preconditionField)
        stackView.addArrangedSubview(postconditionField)
        stackView.addArrangedSubview(stepsCollectionViewTitle)
        stackView.addArrangedSubview(stepsCollectionView)
    }
    
    // MARK: - CollectionView Diffable logic
    private func setupCollectionView() {
        dataSource = UICollectionViewDiffableDataSource<Int, StepsInTestCase>(
            collectionView: stepsCollectionView,
            cellProvider: { collectionView, indexPath, step in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: StepCell.identifier,
                    for: indexPath
                ) as? StepCell else {
                    fatalError("Could not dequeue StepCell")
                }
                cell.configure(with: step, at: indexPath.row)
                return cell
            }
        )
    }
    
    private func updateCollectionViewHeight() {
        let contentHeight = stepsCollectionView.contentSize.height
        stepsCollectionView.snp.updateConstraints { make in
            make.height.equalTo(contentHeight)
        }
    }
    
    private func loadSteps() {
        steps = vm.testCase?.steps ?? []
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, StepsInTestCase>()
        snapshot.appendSections([0])
        snapshot.appendItems(steps)
        dataSource.apply(snapshot, animatingDifferences: true)
        
        updateCollectionViewHeight()
    }
    
    // MARK: - objc funcs for responder
    @objc func swipeBetweenViewsDelegate() {
        guard let delegate = delegate else { return }
        delegate.swipeBetweenViews(panRecognize)
    }
}

extension GeneralDetailCaseViewController: DetailTestCaseProtocol {
    func swipeBetweenViews(_ gesture: UISwipeGestureRecognizer) {
        print("swipeBetweenViews called")
    }
    
    func checkConditionAndToggleRightBarButton() {
        print("checkConditionAndToggleRightBarButton called")
    }
    
    func updateUI() {
        Task { @MainActor in
            if let testCase = vm.testCase {
                titleField.updateTextViewValue(testCase.title)
                descriptionField.updateTextViewValue(testCase.description)
                preconditionField.updateTextViewValue(testCase.preconditions)
                postconditionField.updateTextViewValue(testCase.postconditions)
                loadSteps()
            }
        }
    }
    
    @objc func pull2Refresh() {
        Task { @MainActor in updateUI() }
    }
}

// MARK: - UICollectionViewDelegate
extension GeneralDetailCaseViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath)
        // Handle selection logic
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ViewControllerRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> some UIViewController {
        return TestCaseViewController(caseUniqueKey: "\(317)_\(PROJECT_NAME)")
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}

struct ViewController_Preview: PreviewProvider {
    static var previews: some View {
        ViewControllerRepresentable()
    }
}
#endif
