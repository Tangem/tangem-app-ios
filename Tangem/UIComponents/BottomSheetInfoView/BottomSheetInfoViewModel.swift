//
//  BottomSheetInfoViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 05.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct BottomSheetInfoViewModel: Identifiable {
    // MARK: - Access

    public var icon: ImageType {
        input.icon
    }

    public var title: String {
        input.title
    }

    public var description: String? {
        input.description
    }

    public var buttonTitle: String? {
        input.buttonTitle
    }

    // MARK: - Properties

    public let id: UUID = .init()
    public let buttonTapAction: (() -> Void)?

    private let input: Input

    // MARK: - Init

    public init(input: Input, buttonTapAction: (() -> Void)?) {
        self.input = input
        self.buttonTapAction = buttonTapAction
    }
}

public extension BottomSheetInfoViewModel {
    struct Input {
        let icon: ImageType
        let title: String
        let description: String?
        let buttonTitle: String?
    }
}
