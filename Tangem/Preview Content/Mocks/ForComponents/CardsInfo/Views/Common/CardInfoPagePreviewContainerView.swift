//
//  CardInfoPagePreviewContainerView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 20.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardInfoPagePreviewContainerView: View {
    @StateObject private var previewProvider = CardsInfoPagerPreviewProvider()
    @State private var isHorizontalScrollDisabled = false
    @State private var selectedIndex: Int

    private let hasPullToRefresh: Bool

    private var onPullToRefresh: OnRefresh? {
        guard hasPullToRefresh else { return nil }

        return { completionHandler in
            AppLogger.info("\(self) Starting pull to refresh at \(CACurrentMediaTime())")
            isHorizontalScrollDisabled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                AppLogger.info("\(self) Finishing pull to refresh at \(CACurrentMediaTime())")
                completionHandler()
                isHorizontalScrollDisabled = false
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Colors.Background.secondary
                    .ignoresSafeArea()

                CardsInfoPagerView(
                    data: previewProvider.pages,
                    selectedIndex: $selectedIndex,
                    headerFactory: { pageViewModel in
                        MainHeaderView(viewModel: pageViewModel.header)
                            .cornerRadius(14.0)
                    },
                    contentFactory: { pageViewModel in
                        CardInfoPagePreviewView(viewModel: pageViewModel)
                    },
                    onPullToRefresh: onPullToRefresh
                )
                .pageSwitchThreshold(0.4)
                .contentViewVerticalOffset(64.0)
                .horizontalScrollDisabled(isHorizontalScrollDisabled)
                .navigationTitle("CardsInfoPagerView")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    init(
        previewConfig: CardInfoPagePreviewConfig
    ) {
        _selectedIndex = .init(initialValue: previewConfig.initiallySelectedIndex)
        hasPullToRefresh = previewConfig.hasPullToRefresh
    }
}
