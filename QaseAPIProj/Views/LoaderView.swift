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
        indicator.backgroundColor = AppTheme.bgSecondaryColor
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
        Task { @MainActor in
            shared.overlayView.isHidden = false
            shared.activityIndicator.startAnimating()
        }
    }
    
    static func stopLoading() {
        Task { @MainActor in
            shared.overlayView.isHidden = true
            shared.activityIndicator.stopAnimating()
        }
    }
}
