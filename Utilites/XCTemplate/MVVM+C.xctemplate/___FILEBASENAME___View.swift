//___FILEHEADER___

import SwiftUI

struct ___VARIABLE_moduleName:identifier___View: View {
    @ObservedObject var viewModel: ___VARIABLE_moduleName:identifier___ViewModel

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

#Preview {
    ___VARIABLE_moduleName: identifier___View(
        viewModel: ___VARIABLE_moduleName:identifier___ViewModel(coordinator: ___VARIABLE_moduleName:identifier___Coordinator())
    )
}
