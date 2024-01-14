//
//  LoaderView.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import UIKit

class LoadingIndicator {
    static let shared = LoadingIndicator()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.isHidden = true
        return view
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemBlue
        indicator.layer.cornerRadius = 12
        indicator.backgroundColor = .white
        indicator.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        return indicator
    }()
    
    private init() {
        guard let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        let firstWindow = firstScene.windows.first
        
        if let keyWindow = firstWindow {
            keyWindow.addSubview(overlayView)
            overlayView.addSubview(activityIndicator)
            
            overlayView.frame = keyWindow.bounds
            activityIndicator.center = overlayView.center
        }
    }
    
    static func startLoading() {
        DispatchQueue.main.async {
            shared.overlayView.isHidden = false
            shared.activityIndicator.startAnimating()
        }
    }
    
    static func stopLoading() {
        DispatchQueue.main.async {
            shared.overlayView.isHidden = true
            shared.activityIndicator.stopAnimating()
        }
    }
}


//class LoaderView: UIView {
//    
//    private var progView: UIActivityIndicatorView = {
//        let pv = UIActivityIndicatorView(style: .large)
//        pv.translatesAutoresizingMaskIntoConstraints = false
//        pv.layer.borderColor = UIColor(.gray).cgColor
//        pv.layer.borderWidth = 1
//        pv.layer.cornerRadius = 12
//        pv.backgroundColor = .white
//        pv.color = .systemBlue
//        return pv
//    }()
//    
//    private var textLoader: UILabel = {
//        let tl = UILabel()
//        tl.translatesAutoresizingMaskIntoConstraints = false
//        tl.text = "Loading..."
//        return tl
//    }()
//    
//    private var darkView: UIView = {
//        let dw = UIView()
//        dw.translatesAutoresizingMaskIntoConstraints = false
//        dw.backgroundColor = UIColor(white: 0, alpha: 0.5)
//        dw.isHidden = true
//        return dw
//    }()
//    
//    func configureView(superView: UIView) {
//        superView.addSubview(darkView)
//        
//        NSLayoutConstraint.activate([
//            darkView.topAnchor.constraint(equalTo: superView.topAnchor),
//            darkView.bottomAnchor.constraint(equalTo: superView.bottomAnchor),
//            darkView.leadingAnchor.constraint(equalTo: superView.leadingAnchor),
//            darkView.trailingAnchor.constraint(equalTo: superView.trailingAnchor),
//            
//            progView.centerYAnchor.constraint(equalTo: darkView.centerYAnchor),
//            progView.centerXAnchor.constraint(equalTo: darkView.centerXAnchor),
//            progView.widthAnchor.constraint(equalToConstant: 100),
//            progView.heightAnchor.constraint(equalToConstant: 100),
//        ])
//    }
//    
//    func showLoader() {
//        self.darkView.isHidden = false
//        progView.startAnimating()
//    }
//    
//    func hideLoader() {
//        self.darkView.isHidden = true
//        self.progView.stopAnimating()
//    }
//    
//}
