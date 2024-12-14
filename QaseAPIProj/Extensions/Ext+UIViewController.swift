//
//  Ext+UIViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 24.10.2024.
//

import UIKit

extension UIViewController {
    // Universalized func for error handling
    func executeWithErrorHandling(
        presentingViewController: UIViewController? = nil,
        _ action: @escaping () async throws -> Void
    ) {
        Task {
            do {
                try await action()
            } catch let error as APIError {
                var errorMessage = "Unknown Error".localized
                
                switch error {
                case .invalidURL, .timeout:
                    errorMessage = "Something went wrong".localized
                case .parsingError(let message), .otherNetworkError(let message), .serializationError(let message):
                    errorMessage = message
                case .noInternetConnection:
                    errorMessage = "Internet connection problem".localized
                }
                
                await MainActor.run {
                    UIAlertController.showSimpleAlert(
                        on: presentingViewController == nil ? self : presentingViewController!,
                        message: errorMessage
                    )
                }
            }
        }
    }
}
