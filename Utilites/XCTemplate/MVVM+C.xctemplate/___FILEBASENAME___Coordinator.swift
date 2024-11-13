//___FILEHEADER___

import Foundation
import Combine

class ___VARIABLE_moduleName___Coordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: ___VARIABLE_moduleName___ViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(coordinator: self)
    }
}

// MARK: - Options

extension ___VARIABLE_moduleName___Coordinator {
    enum Options {
        case `default`
    }
}

// MARK: - ___VARIABLE_moduleName___Routable

extension ___VARIABLE_moduleName___Coordinator: ___VARIABLE_moduleName___Routable {}
