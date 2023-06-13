//
//  LearnView.swift
//
//
//  Created by Andrey Chukavin on 30.05.2023.
//

import SwiftUI

struct PromotionView: View {
    @ObservedObject private var viewModel: PromotionViewModel

    init(viewModel: PromotionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            WebView(url: viewModel.url, headers: viewModel.headers, urlActions: viewModel.urlActions)
                .navigationBarItems(leading: Button(Localization.commonClose, action: viewModel.close))
        }
    }
}

struct PromotionView_Preview: PreviewProvider {
    static let viewModel = PromotionViewModel(options: .default, coordinator: PromotionCoordinator())

    static var previews: some View {
        PromotionView(viewModel: viewModel)
    }
}
