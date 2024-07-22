//
//  MarketsPaginator.swift
//  Tangem
//
//  Created by skibinalexander on 22.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class MarketsPaginator {
//    func controllerBind() {
//        listDataController
//            .visableRangeAreaPublisher
//            .withWeakCaptureOf(self)
//            .sink { viewModel, visibleArea in
//                guard !viewModel.dataProvider.items.isEmpty, viewModel.viewDidAppear else { return }
//
//                if visibleArea.direction == .down {
//                    viewModel.downPaginationFlow(with: visibleArea)
//                } else {}
//            }
//            .store(in: &bag)
//    }

//    private func downPaginationFlow(with visibleArea: MarketsListDataController.VisabaleArea) {
//        let offsetConstant = 25
//        let memoryLastCount = tokenViewModels.count
//
//        let upperItemIndex = visibleArea.range.upperBound + 2 * offsetConstant < dataProvider.items.count ?
//            visibleArea.range.upperBound + 2 * offsetConstant : 0
//
//        print("upperItemIndex = \(visibleArea.range.upperBound)")
//        print("memoryLastCount = \(memoryLastCount)")
//
//        if memoryLastCount - visibleArea.range.upperBound < offsetConstant {
//            print("need append items")
//
//            let rangeItems = dataProvider.items[memoryLastCount ... upperItemIndex]
//
//            var copyTokenViewModels = tokenViewModels
//
//            let tokenViewModelsToAppend = rangeItems.enumerated().compactMap { index, item in
//                let tokenViewModel = mapToTokenViewModel(tokenItemModel: item, by: memoryLastCount + index)
//                return tokenViewModel
//            }
//
//            copyTokenViewModels.append(contentsOf: tokenViewModelsToAppend)
//
//            tokenViewModels = copyTokenViewModels
//
//            print("count = \(tokenViewModels.count)")
//        }
//    }
}
