//
//  Ext+UIViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 24.10.2024.
//

import UIKit

extension UIViewController {
    // Universalized func for error handling
    @discardableResult
    func executeWithErrorHandling(
        presentingViewController: UIViewController? = nil,
        _ action: @escaping () async throws -> Void
    ) -> Task<Void, Never> {
        Task {
            do {
                try await action()
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else { return }
                var errorMessage = "Unknown Error".localized

                if let error = error as? API.NetError {
                    switch error {
                    case .invalidURL, .timeout:
                        errorMessage = "Something went wrong".localized
                    case .parsingError(let message), .otherNetworkError(let message),
                         .serializationError(let message):
                        errorMessage = message
                    case .noInternetConnection:
                        errorMessage = "Internet connection problem".localized
                    case .invalidCredantials:
                        errorMessage = "Invalid credentials".localized
                    case .invalidRequest(let message):
                        errorMessage = message
                    case .httpError(_, let message, _):
                        errorMessage = message
                    }
                } else {
                    errorMessage = error.localizedDescription
                }

                await MainActor.run {
                    UIAlertController.showSimpleAlert(
                        on: presentingViewController ?? self,
                        title: "Error".localized,
                        message: errorMessage
                    )
                }
            }
        }
    }
}
