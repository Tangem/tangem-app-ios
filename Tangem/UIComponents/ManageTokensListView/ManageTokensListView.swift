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
    let isReadOnly: Bool
    let header: Header?
    let footer: Footer?

    private var contentOffsetObserver: Binding<CGPoint>? = nil
    private let bottomPadding: CGFloat

    init(
        viewModel: ManageTokensListViewModel,
        bottomPadding: CGFloat = Constants.bottomPadding,
        isReadOnly: Bool = false,
        @ViewBuilder header: HeaderFactory,
        @ViewBuilder footer: FooterFactory
    ) {
        self.viewModel = viewModel
        self.bottomPadding = bottomPadding
        self.isReadOnly = isReadOnly
        self.header = header()
        self.footer = footer()
    }

    init(
        viewModel: ManageTokensListViewModel,
        bottomPadding: CGFloat = Constants.bottomPadding,
        isReadOnly: Bool = false,
        @ViewBuilder header: HeaderFactory
    ) where Footer == EmptyView {
        self.viewModel = viewModel
        self.bottomPadding = bottomPadding
        self.isReadOnly = isReadOnly
        self.header = header()
        footer = nil
    }

    init(
        viewModel: ManageTokensListViewModel,
        bottomPadding: CGFloat = Constants.bottomPadding,
        isReadOnly: Bool = false
    ) where Header == EmptyView, Footer == EmptyView {
        self.viewModel = viewModel
        self.bottomPadding = bottomPadding
        self.isReadOnly = isReadOnly
        header = nil
        footer = nil
    }

    private let namespace = UUID()

    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                if let header {
                    header
                }

                tokenList

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

    private var tokenList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.tokenListItemModels) {
                ManageTokensListItemView(viewModel: $0, isReadOnly: isReadOnly)
            }

            if viewModel.hasNextPage {
                ManageTokensListLoaderView()
                    .onAppear(perform: viewModel.fetch)
            }
        }
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
