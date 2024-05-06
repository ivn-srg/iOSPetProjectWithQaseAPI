//
//  RunsDetailCaseViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class RunsDetailCaseViewController: UIViewController {
    
    let vm: DetailTabbarControllerViewModel
    
    init(vm: DetailTabbarControllerViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
