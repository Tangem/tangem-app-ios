//
//  MarketsTokenDetailsExchangesListViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 25.09.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsTokenDetailsExchangesListViewModel: MarketsBaseViewModel {
    @Published var exchangesList: LoadingValue<[MarketsTokenDetailsExchangeItemInfo]> = .loading

    /// For unknown reasons, the `@self` and `@identity` of our view change when push navigation is performed in other
    /// navigation controllers in the application (on the main screen for example), which causes the state of
    /// this property to be lost if it were stored in the view as a `@State` variable.
    /// Therefore, we store it here in the view model as the `@Published` property instead of storing it in a view.
    ///
    /// Our view is initially presented when the sheet is expanded, hence the `1.0` initial value.
    @Published private(set) var overlayContentHidingInitialProgress = 1.0

    var isMarketsSheetStyle: Bool { presentationStyle == .marketsSheet }
    let numberOfExchangesListedOn: Int
    let onBackButtonAction: () -> Void

    private let exchangesListLoader: MarketsTokenExchangesListLoader
    private let tokenId: String
    private let presentationStyle: MarketsTokenDetailsPresentationStyle

    private let exchangesListMinReloadInterval: TimeInterval = 10.0

    private var loadingCancellable: AnyCancellable?
    private var lastLoadAttemptDate: Date?

    init(
        tokenId: String,
        numberOfExchangesListedOn: Int,
        presentationStyle: MarketsTokenDetailsPresentationStyle,
        exchangesListLoader: MarketsTokenExchangesListLoader,
        onBackButtonAction: @escaping () -> Void
    ) {
        self.tokenId = tokenId
        self.numberOfExchangesListedOn = numberOfExchangesListedOn
        self.presentationStyle = presentationStyle
        self.exchangesListLoader = exchangesListLoader
        self.onBackButtonAction = onBackButtonAction

        super.init(overlayContentProgressInitialValue: 1.0)
    }

    func reloadExchangesList() {
        exchangesList = .loading
        loadExchangesList()
    }

    func onOverlayContentStateChange(_ state: OverlayContentState) {
        // Our view can be recreated when the bottom sheet is in a collapsed state
        // In this case, content should be hidden (i.e. the initial progress should be zero)
        overlayContentHidingInitialProgress = state.isCollapsed ? 0.0 : 1.0
    }
}

extension MarketsTokenDetailsExchangesListViewModel {
    func loadExchangesList() {
        guard loadingCancellable == nil else {
            return
        }

        let date = Date()
        let remainingTime: TimeInterval
        if let lastLoadAttemptDate {
            remainingTime = max(exchangesListMinReloadInterval - date.timeIntervalSince(lastLoadAttemptDate), 0)
        } else {
            remainingTime = 0
        }
        loadingCancellable = Task.delayed(withDelay: remainingTime) { [weak self] in
            do {
                guard let self else {
                    return
                }

                let response = try await exchangesListLoader.loadExchangesList(for: tokenId)
                await handleLoadResult(.success(response))
            } catch {
                await self?.handleLoadResult(.failure(error))
            }
        }.eraseToAnyCancellable()
    }
}

private extension MarketsTokenDetailsExchangesListViewModel {
    @MainActor
    func handleLoadResult(_ result: Result<[MarketsTokenDetailsExchangeItemInfo], Error>) async {
        lastLoadAttemptDate = Date()
        do {
            let list = try result.get()

            exchangesList = .loaded(list)
        } catch {
            if error.isCancellationError {
                return
            }

            exchangesList = .failedToLoad(error: error)
        }

        loadingCancellable = nil
    }
}
