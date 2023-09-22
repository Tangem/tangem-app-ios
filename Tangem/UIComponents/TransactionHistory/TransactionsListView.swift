//
//  TransactionsListView.swift
//  Tangem
//
//  Created by Andrew Son on 08/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TransactionsListView: View {
    let state: State
    let exploreAction: () -> Void
    let exploreTransactionAction: (String) -> Void
    let reloadButtonAction: () -> Void
    let isReloadButtonBusy: Bool
    let buyButtonAction: (() -> Void)?
    let fetchMore: FetchMore?

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(14)
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Text(Localization.commonTransactions)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            Button(action: exploreAction) {
                HStack(spacing: 4) {
                    Assets.compass.image
                        .foregroundColor(Colors.Icon.informative)

                    Text(Localization.commonExplorer)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .notSupported:
            notSupportedContent
        case .loading:
            loadingContent
        case .loaded(let items):
            transactionsContent(transactionItems: items)
        case .error:
            errorContent
        }
    }

    @ViewBuilder
    private var notSupportedContent: some View {
        VStack(spacing: 20) {
            Assets.compassBig.image
                .foregroundColor(Colors.Icon.informative)

            Text(Localization.transactionHistoryNotSupportedDescription)
                .multilineTextAlignment(.center)
                .lineSpacing(Constants.lineSpacing)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.horizontal, 36)

            FixedSizeButtonWithLeadingIcon(
                title: Localization.commonExploreTransactionHistory,
                icon: Assets.arrowRightUpMini.image,
                action: exploreAction
            )
        }
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private var loadingContent: some View {
        VStack(spacing: 12) {
            header

            ForEach(0 ... 2) { _ in
                TokenListItemLoadingPlaceholderView(style: .transactionHistory)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var noTransactionsContent: some View {
        VStack(spacing: 20) {
            Assets.emptyHistory.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)

            Text(Localization.transactionHistoryEmptyTransactions)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)

            if let buyButtonAction = buyButtonAction {
                simpleButton(with: Localization.commonBuy, and: buyButtonAction)
            }
        }
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private var errorContent: some View {
        VStack(spacing: 20) {
            Assets.fileExclamationMark.image
                .foregroundColor(Colors.Icon.informative)

            Text(Localization.transactionHistoryErrorFailedToLoad)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineSpacing(Constants.lineSpacing)
                .padding(.horizontal, 36)

            buttonWithLoader(title: Localization.commonReload, action: reloadButtonAction, isLoading: isReloadButtonBusy)
        }
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private func transactionsContent(transactionItems: [TransactionListItem]) -> some View {
        if transactionItems.isEmpty {
            noTransactionsContent
        } else {
            LazyVStack(spacing: 12) {
                ForEach(transactionItems.indexed(), id: \.1.id) { sectionIndex, item in
                    makeSectionHeader(for: item, atIndex: sectionIndex)

                    ForEach(item.items, id: \.id) { item in
                        Button {
                            exploreTransactionAction(item.hash)
                        } label: {
                            TransactionView(viewModel: item)
                                .ios14FixedHeight(Constants.ios14ListItemHeight)
                        }
                    }
                }

                if let fetchMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.primary1))
                        .padding(.vertical)
                        .onAppear {
                            fetchMore.start()
                        }
                        .id(fetchMore.id)
                }
            }
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func simpleButton(with title: String, and action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
        }
        .background(Colors.Button.secondary)
        .cornerRadiusContinuous(10)
    }

    @ViewBuilder
    private func buttonWithLoader(title: String, action: @escaping () -> Void, isLoading: Bool) -> some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .style(Fonts.Bold.subheadline, color: isLoading ? Color.clear : Colors.Text.primary1)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.primary1))
                        .hidden(!isLoading)
                        .disabled(!isLoading)
                )
        }
        .background(Colors.Button.secondary)
        .cornerRadiusContinuous(10)
    }

    @ViewBuilder
    private func makeSectionHeader(for item: TransactionListItem, atIndex sectionIndex: Int) -> some View {
        let sectionHeader = HStack {
            Text(item.header)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            Spacer()
        }
        .padding(.horizontal, 16)

        Group {
            // Section header for the very first section also includes the header for the list itself
            if sectionIndex == 0 {
                VStack(spacing: 0.0) {
                    header

                    Spacer(minLength: 12.0)

                    sectionHeader

                    Spacer(minLength: 12.0)
                }
            } else {
                sectionHeader
            }
        }
        .ios14FixedHeight(Constants.ios14ListItemHeight)
    }
}

extension TransactionsListView {
    enum State: Equatable {
        case loading
        case error(Error)
        case loaded([TransactionListItem])
        case notSupported

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.error, .error): return true
            case (.loaded(let lhsItems), .loaded(let rhsItems)): return lhsItems == rhsItems
            case (.notSupported, .notSupported): return true
            default: return false
            }
        }
    }
}

extension TransactionsListView {
    enum Constants {
        /// An approximate value from the design
        static let lineSpacing: CGFloat = 3.5
        @available(iOS, obsoleted: 15.0, message: "Delete when the minimum deployment target reaches 15.0")
        static let ios14ListItemHeight = 56.0
    }
}

struct TransactionsListView_Previews: PreviewProvider {
    class TxHistoryModel: ObservableObject {
        @Published var state: TransactionsListView.State

        let oldItems = [
            TransactionListItem(
                header: "Yesterday",
                items: TransactionView_Previews.previewViewModels
            ),
            TransactionListItem(
                header: "02.05.23",
                items: TransactionView_Previews.previewViewModels
            ),
        ]

        let todayItems = [
            TransactionListItem(
                header: "Today",
                items: TransactionView_Previews.previewViewModels
            ),
        ]

        private var onlyOldItems = true

        init() {
            state = .loaded(oldItems)
        }

        func toggleState() {
            switch state {
            case .loading:
                state = .loaded(oldItems)
            case .loaded:
                if onlyOldItems {
                    state = .loaded(todayItems + oldItems)
                    onlyOldItems = false
                    return
                }

                state = .error("Don't touch this!!!")
                onlyOldItems = true
            case .error:
                state = .notSupported
            case .notSupported:
                state = .loading
            }
        }
    }

    struct PreviewView: View {
        @ObservedObject var model: TxHistoryModel = .init()

        var body: some View {
            VStack {
                Button(action: model.toggleState) {
                    Text("Toggle state")
                }

                ScrollView {
                    TransactionsListView(
                        state: model.state,
                        exploreAction: {},
                        exploreTransactionAction: { _ in },
                        reloadButtonAction: {},
                        isReloadButtonBusy: false,
                        buyButtonAction: {},
                        fetchMore: nil
                    )
                    .animation(.default, value: model.state)
                    .padding(.horizontal, 16)
                }
            }
            .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        }
    }

    static var previews: some View {
        PreviewView()
    }
}
