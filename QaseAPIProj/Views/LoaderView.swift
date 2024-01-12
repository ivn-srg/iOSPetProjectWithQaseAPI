//
//  LoaderView.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import UIKit

class LoaderView: UIView {
    
    private var progView: UIActivityIndicatorView = {
        let pv = UIActivityIndicatorView(style: .large)
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.layer.borderColor = UIColor(.gray).cgColor
        pv.layer.borderWidth = 1
        pv.layer.cornerRadius = 12
        pv.backgroundColor = .white
        pv.color = .systemBlue
        return pv
    }()
    
    private var textLoader: UILabel = {
        let tl = UILabel()
        tl.translatesAutoresizingMaskIntoConstraints = false
        tl.text = "Loading..."
        return tl
    }()
    
    private var darkView: UIView = {
        let dw = UIView()
        dw.translatesAutoresizingMaskIntoConstraints = false
        dw.backgroundColor = UIColor(white: 0, alpha: 0.5)
        dw.isHidden = true
        return dw
    }()
    
    func configureView(superView: UIView) {
        superView.addSubview(darkView)
        
        NSLayoutConstraint.activate([
            darkView.topAnchor.constraint(equalTo: superView.topAnchor),
            darkView.bottomAnchor.constraint(equalTo: superView.bottomAnchor),
            darkView.leadingAnchor.constraint(equalTo: superView.leadingAnchor),
            darkView.trailingAnchor.constraint(equalTo: superView.trailingAnchor),
            
            progView.centerYAnchor.constraint(equalTo: darkView.centerYAnchor),
            progView.centerXAnchor.constraint(equalTo: darkView.centerXAnchor),
            progView.widthAnchor.constraint(equalToConstant: 100),
            progView.heightAnchor.constraint(equalToConstant: 100),
        ])
    }
    
    func showLoader() {
        self.darkView.isHidden = false
        progView.startAnimating()
    }
    
    func hideLoader() {
        self.darkView.isHidden = true
        self.progView.stopAnimating()
    }
    
}
