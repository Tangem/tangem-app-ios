//
//  ManageTokensListView.swift
//  Tangem
//
//  Created by Andrew Son on 22/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensListView<Header, Footer>: View where Header: View, Footer: View {
    typealias HeaderFactory = () -> Header?
    typealias FooterFactory = () -> Footer?

    @ObservedObject var viewModel: ManageTokensListViewModel
    let header: Header?
    let footer: Footer?

    private var contentOffsetObserver: Binding<CGPoint>? = nil
    private let bottomPadding: CGFloat

    init(
        viewModel: ManageTokensListViewModel,
        bottomPadding: CGFloat = Constants.bottomPadding,
        @ViewBuilder header: HeaderFactory,
        @ViewBuilder footer: FooterFactory
    ) {
        self.viewModel = viewModel
        self.bottomPadding = bottomPadding
        self.header = header()
        self.footer = footer()
    }

    init(
        viewModel: ManageTokensListViewModel,
        bottomPadding: CGFloat = Constants.bottomPadding
    ) where Header == EmptyView, Footer == EmptyView {
        self.viewModel = viewModel
        self.bottomPadding = bottomPadding
        header = nil
        footer = nil
    }

    private let namespace = UUID()

    var body: some View {
        ScrollView {
            LazyVStack {
                if let header {
                    header
                }

                ForEach(viewModel.coinViewModels) {
                    ManageTokensCoinView(model: $0)
                        .padding(.horizontal)
                }

                if viewModel.hasNextPage {
                    HStack(alignment: .center) {
                        ActivityIndicatorView(color: .gray)
                            .onAppear(perform: viewModel.fetch)
                    }
                }

                if let footer {
                    footer
                }
            }
            .padding(.bottom, bottomPadding)
            .readContentOffset(inCoordinateSpace: .named(namespace)) { value in
                contentOffsetObserver?.wrappedValue = value
            }
        }
        .coordinateSpace(name: namespace)
    }
}

extension ManageTokensListView: Setupable {
    func addContentOffsetObserver(_ observer: Binding<CGPoint>) -> Self {
        map {
            $0.contentOffsetObserver = observer
        }
    }
}

extension ManageTokensListView {
    enum Constants {
        static var bottomPadding: CGFloat { 60 }
    }
}
