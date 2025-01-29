//
//  LogsViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 22.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import Foundation
import TangemFoundation
import TangemLogger

class LogsViewModel: ObservableObject {
    var categories: [String] {
        ["All"] + (entries.value.value.map { $0.map(\.log.category) } ?? []).toSet().sorted()
    }

    var selectedCategory: String { categories[selectedCategoryIndex] }
    @Published var selectedCategoryIndex: Int = .zero
    @Published var logs: LoadingResult<[LogRowViewData], Error> = .loading

    private let entries: CurrentValueSubject<LoadingResult<[LogRowViewData], Error>, Never> = .init(.loading)
    private var refreshCancellable: AnyCancellable?

    init() {
        setup()
    }

    func share() {
        let url = OSLogFileParser.logFile
        AppPresenter.shared.show(
            UIActivityViewController(activityItems: [url], applicationActivities: nil)
        )
    }

    func setup() {
        entries.send(.result(.init {
            try OSLogFileParser.entries()
                .reversed()
                .map { LogRowViewData(log: $0) }
        }))

        refreshCancellable = Publishers
            .CombineLatest(entries, $selectedCategoryIndex)
            .receive(on: DispatchQueue.global())
            .withWeakCaptureOf(self)
            .map { viewModel, args in
                let (entries, categoryIndex) = args

                return entries.mapValue { entries in
                    if categoryIndex > 0 {
                        return entries
                            .filter { $0.log.category == viewModel.categories[categoryIndex] }
                    }

                    return entries
                }
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .receiveValue { viewModel, entries in
                viewModel.logs = entries
            }
    }
}
