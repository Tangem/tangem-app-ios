//___FILEHEADER___

import SwiftUI

struct ___VARIABLE_moduleName___CoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ___VARIABLE_moduleName___Coordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                ___VARIABLE_moduleName___View(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
    }

    @ViewBuilder
    private var sheets: some View {
        EmptyView()
    }
}
