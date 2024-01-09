//
//  DetentBottomSheetContainer.swift
//  Tangem
//
//  Created by skibinalexander on 05.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

struct DetentBottomSheetContainer<ContentView: View>: View {
    private let content: () -> ContentView

    // MARK: - Internal

    private let indicatorSize = CGSize(width: 32, height: 4)

    init(content: @escaping () -> ContentView) {
        self.content = content
    }

    var body: some View {
        sheetView
    }

    private var sheetView: some View {
        content()
            .overlay(indicator, alignment: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var indicator: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Colors.Icon.inactive)
                .frame(size: indicatorSize)
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 20)
    }
}

// MARK: - Settings

extension DetentBottomSheetContainer {
    enum Detent: Hashable {
        case medium
        case large
        case custom(CGFloat)
        case fraction(CGFloat)

        @available(iOS 16.0, *)
        var detentsAboveIOS16: PresentationDetent {
            switch self {
            case .large:
                return PresentationDetent.large
            case .medium:
                return PresentationDetent.medium
            case .custom(let height):
                return .height(height)
            case .fraction(let value):
                return .fraction(value)
            }
        }

        @available(iOS 15.0, *)
        var detentsAboveIOS15: UISheetPresentationController.Detent {
            switch self {
            case .large, .custom(_), .fraction:
                return UISheetPresentationController.Detent.large()
            case .medium:
                return UISheetPresentationController.Detent.medium()
            }
        }
    }

    struct Settings {
        let cornerRadius: CGFloat

        init(cornerRadius: CGFloat = 24) {
            self.cornerRadius = cornerRadius
        }
    }
}
