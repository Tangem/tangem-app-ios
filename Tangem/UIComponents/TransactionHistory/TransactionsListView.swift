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
                        .renderingMode(.template)
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
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.transactionHistoryNotSupportedDescription)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.horizontal, 36)

            makeExploreTransactionHistoryButton(withTitle: Localization.commonExploreTransactionHistory, hasFixedSize: true)
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
        VStack(spacing: 22) {
            Assets.emptyHistory.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.transactionHistoryEmptyTransactions)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            makeExploreTransactionHistoryButton(withTitle: Localization.commonExplore, hasFixedSize: true)
        }
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private var errorContent: some View {
        VStack(spacing: 20) {
            Assets.fileExclamationMark.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.transactionHistoryErrorFailedToLoad)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.horizontal, 36)

            HStack(spacing: 8.0) {
                makeReloadTransactionHistoryButton()

                makeExploreTransactionHistoryButton(withTitle: Localization.commonExploreHistory, hasFixedSize: false)
            }
            .padding(.horizontal, 16.0)
        }
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private func transactionsContent(transactionItems: [TransactionListItem]) -> some View {
        if transactionItems.isEmpty {
            noTransactionsContent
        } else {
            LazyVStack(spacing: 0) {
                ForEach(transactionItems.indexed(), id: \.1.id) { sectionIndex, sectionItem in
                    VStack(spacing: 0) {
                        if sectionIndex == 0 {
                            header
                        }

                        if #available(iOS 15, *) {
                            makeSectionHeader(for: sectionItem, atIndex: sectionIndex, withVerticalPadding: true)
                        } else {
                            Spacer(minLength: 0)

                            // Remove vertical padding from iOS 14 header to make it fit into fixed-height cell
                            makeSectionHeader(for: sectionItem, atIndex: sectionIndex, withVerticalPadding: false)

                            Spacer(minLength: 0)
                        }
                    }
                    .ios14FixedHeight(Constants.ios14ListItemHeight)

                    ForEach(sectionItem.items.indexed(), id: \.1.id) { cellIndex, cellItem in
                        Button {
                            exploreTransactionAction(cellItem.hash)
                        } label: {
                            // Extra padding to implement "cell spacing" without resorting to VStack spacing
                            TransactionView(viewModel: cellItem)
                                .padding(.bottom, cellIndex == (sectionItem.items.count - 1) ? 0 : 16)
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
    private func makeSectionHeader(
        for item: TransactionListItem,
        atIndex sectionIndex: Int,
        withVerticalPadding useVerticalPadding: Bool
    ) -> some View {
        HStack {
            Text(item.header)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, useVerticalPadding ? 14 : 0)
    }

    @ViewBuilder
    private func makeExploreTransactionHistoryButton(withTitle title: String, hasFixedSize: Bool) -> some View {
        if hasFixedSize {
            FixedSizeButtonWithLeadingIcon(
                title: title,
                icon: Assets.arrowRightUpMini.image,
                action: exploreAction
            )
            .overrideBackgroundColor(Constants.buttonBackgroundColor)
        } else {
            FlexySizeButtonWithLeadingIcon(
                title: title,
                icon: Assets.arrowRightUpMini.image,
                action: exploreAction
            )
            .overrideBackgroundColor(Constants.buttonBackgroundColor)
        }
    }

    @ViewBuilder
    private func makeReloadTransactionHistoryButton() -> some View {
        FlexySizeButtonWithLeadingIcon(
            title: Localization.commonReload,
            icon: Assets.reload.image,
            action: reloadButtonAction
        )
        .overrideBackgroundColor(Constants.buttonBackgroundColor)
        .overlay(
            ZStack {
                Constants.buttonBackgroundColor
                    .cornerRadiusContinuous(FlexySizeButtonWithLeadingIcon.Constants.cornerRadius)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.primary1))
            }
            .hidden(!isReloadButtonBusy)
        )
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

// MARK: - Constants

extension TransactionsListView {
    enum Constants {
        @available(iOS, obsoleted: 15.0, message: "Delete when the minimum deployment target reaches 15.0")
        static let ios14ListItemHeight = 56.0
        static let buttonBackgroundColor = Colors.Button.secondary
    }
}

struct TransactionsListView_Previews: PreviewProvider {
    class TxHistoryModel: ObservableObject {
        @Published var state: TransactionsListView.State

        static let oldItems = [
            TransactionListItem(
                header: "Yesterday",
                items: TransactionView_Previews.previewViewModels
            ),
            TransactionListItem(
                header: "02.05.23",
                items: TransactionView_Previews.previewViewModels
            ),
        ]

        static let todayItems = [
            TransactionListItem(
                header: "Today",
                items: TransactionView_Previews.previewViewModels
            ),
        ]

        private var onlyOldItems = true

        init(state: TransactionsListView.State) {
            self.state = state
        }

        func toggleState() {
            switch state {
            case .loading:
                state = .loaded(Self.oldItems)
            case .loaded:
                if onlyOldItems {
                    state = .loaded(Self.todayItems + Self.oldItems)
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
        @ObservedObject var model: TxHistoryModel

        init(state: TransactionsListView.State) {
            model = .init(state: state)
        }

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
        Group {
            PreviewView(state: .loaded(TxHistoryModel.oldItems))
                .previewDisplayName("Yesterday")

            PreviewView(state: .loaded(TxHistoryModel.todayItems + TxHistoryModel.oldItems))
                .previewDisplayName("Today")

            PreviewView(state: .loaded(
                [
                    TransactionListItem(header: "Today", items: TransactionView_Previews.figmaViewModels1),
                    TransactionListItem(header: "Yesterday", items: TransactionView_Previews.figmaViewModels2),
                ]
            ))
            .previewDisplayName("Figma")

            PreviewView(state: .loaded([]))
                .previewDisplayName("Empty")

            PreviewView(state: .loading)
                .previewDisplayName("Loading")

            PreviewView(state: .notSupported)
                .previewDisplayName("Not supported")

            PreviewView(state: .error("eror!"))
                .previewDisplayName("Error")
        }
    }
}
