//
//  MainBottomSheetHeaderViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MainBottomSheetHeaderViewModel: ObservableObject {
    var enteredSearchInputPublisher: AnyPublisher<SearchInput, Never> {
        searchInputSubject.eraseToAnyPublisher()
    }

    @Published var enteredSearchText = ""
    @Published var inputShouldBecomeFocused = false

    private let searchInputSubject = CurrentValueSubject<SearchInput, Never>(.textInput(""))
    private var shouldSkipNextTextInput = false

    private var inputSubscription: AnyCancellable?

    weak var delegate: MainBottomSheetHeaderViewModelDelegate?

    init() {
        bind()
    }

    func onBottomSheetExpand(isTapGesture: Bool) {
        guard
            isTapGesture,
            delegate?.isViewVisibleForHeaderViewModel(self) == true
        else {
            return
        }

        inputShouldBecomeFocused = true
    }

    func clearSearchBarAction() {
        if enteredSearchText.isEmpty {
            return
        }

        searchInputSubject.send(.clearInput)
        shouldSkipNextTextInput = true
        enteredSearchText = ""
    }

    private func bind() {
        inputSubscription = $enteredSearchText
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .filter { viewModel, input in
                if viewModel.shouldSkipNextTextInput {
                    viewModel.shouldSkipNextTextInput = false
                    return false
                }

                return true
            }
            .map { SearchInput.textInput($1) }
            .assign(to: \.value, on: searchInputSubject, ownership: .weak)
    }
}

extension MainBottomSheetHeaderViewModel {
    enum SearchInput: Equatable {
        case textInput(String)
        case clearInput

        var textValue: String? {
            switch self {
            case .textInput(let textInput): return textInput
            case .clearInput: return nil
            }
        }

        static func == (lhs: SearchInput, rhs: SearchInput) -> Bool {
            switch (lhs, rhs) {
            case (.textInput(let lhsText), .textInput(let rhsText)):
                return lhsText.compare(rhsText) == .orderedSame
            case (.clearInput, .clearInput):
                return true
            default:
                return false
            }
        }
    }
}
