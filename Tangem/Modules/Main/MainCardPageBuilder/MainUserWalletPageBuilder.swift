//
//  MainUserWalletPageBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum MainUserWalletPageBuilder: Identifiable {
    case singleWallet(id: UserWalletId, headerModel: MainHeaderViewModel, bodyModel: SingleWalletMainContentViewModel?)
    case multiWallet(id: UserWalletId, headerModel: MainHeaderViewModel, bodyModel: MultiWalletMainContentViewModel)
    case lockedWallet(id: UserWalletId, headerModel: MainHeaderViewModel, bodyModel: LockedWalletMainContentViewModel)
    case visaWallet(id: UserWalletId, headerModel: MainHeaderViewModel, bodyModel: VisaWalletMainContentViewModel)

    var id: UserWalletId {
        switch self {
        case .singleWallet(let id, _, _):
            return id
        case .multiWallet(let id, _, _):
            return id
        case .lockedWallet(let id, _, _):
            return id
        case .visaWallet(let id, _, _):
            return id
        }
    }

    var isLockedWallet: Bool {
        switch self {
        case .lockedWallet: return true
        case .singleWallet, .multiWallet, .visaWallet: return false
        }
    }

    private var footerViewModel: MainFooterViewModel? {
        switch self {
        case .singleWallet:
            return nil
        case .multiWallet(_, _, let bodyModel):
            return bodyModel.footerViewModel
        case .lockedWallet(_, _, let bodyModel):
            return bodyModel.footerViewModel
        case .visaWallet:
            return nil
        }
    }

    private var bottomSheetFooterViewModel: MainBottomSheetFooterViewModel? {
        switch self {
        case .singleWallet(_, _, let bodyModel):
            return bodyModel?.bottomSheetFooterViewModel
        case .multiWallet(_, _, let bodyModel):
            return bodyModel.bottomSheetFooterViewModel
        case .lockedWallet(_, _, let bodyModel):
            return bodyModel.bottomSheetFooterViewModel
        case .visaWallet:
            return nil
        }
    }

    @ViewBuilder
    var header: some View {
        switch self {
        case .singleWallet(_, let headerModel, _):
            MainHeaderView(viewModel: headerModel)
        case .multiWallet(_, let headerModel, _):
            MainHeaderView(viewModel: headerModel)
        case .lockedWallet(_, let headerModel, _):
            MainHeaderView(viewModel: headerModel)
        case .visaWallet(_, let headerModel, _):
            MainHeaderView(viewModel: headerModel)
        }
    }

    @ViewBuilder
    func makeActionButtons(viewModel: ActionButtonsViewModel) -> some View {
        if FeatureProvider.isAvailable(.actionButtons) {
            switch self {
            case .singleWallet:
                EmptyView()
            case .multiWallet, .lockedWallet, .visaWallet:
                ActionButtonsView(viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    var body: some View {
        switch self {
        case .singleWallet(let id, _, let bodyModel):
            if let bodyModel {
                SingleWalletMainContentView(viewModel: bodyModel)
                    .id(id)
            } else {
                LoadingSingleWalletMainContentView()
                    .id(id)
            }
        case .multiWallet(let id, _, let bodyModel):
            MultiWalletMainContentView(viewModel: bodyModel)
                .id(id)
        case .lockedWallet(let id, _, let bodyModel):
            LockedWalletMainContentView(viewModel: bodyModel)
                .id(id)
        case .visaWallet(let id, _, let bodyModel):
            VisaWalletMainContentView(viewModel: bodyModel)
                .id(id)
        }
    }

    var missingBodyModel: Bool {
        switch self {
        case .singleWallet(_, _, let bodyModel):
            return bodyModel == nil
        case .multiWallet, .lockedWallet, .visaWallet:
            return false
        }
    }

    @ViewBuilder
    func makeBottomOverlay(_ overlayParams: CardsInfoPagerBottomOverlayFactoryParams) -> some View {
        if let viewModel = bottomSheetFooterViewModel {
            MainBottomSheetFooterView(viewModel: viewModel)
                .overlay {
                    MainBottomSheetHintView(
                        isDraggingHorizontally: overlayParams.isDraggingHorizontally,
                        didScrollToBottom: overlayParams.didScrollToBottom,
                        scrollOffset: overlayParams.scrollOffset,
                        viewportSize: overlayParams.viewportSize,
                        contentSize: overlayParams.contentSize,
                        scrollViewBottomContentInset: overlayParams.scrollViewBottomContentInset
                    )
                }
        } else if let viewModel = footerViewModel {
            MainFooterView(viewModel: viewModel, didScrollToBottom: overlayParams.didScrollToBottom)
        } else {
            EmptyMainFooterView()
        }
    }
}

// MARK: - MainViewPage protocol conformance

extension MainUserWalletPageBuilder: MainViewPage {
    func onPageAppear() {
        switch self {
        case .singleWallet(_, _, let bodyModel):
            bodyModel?.onPageAppear()
        case .multiWallet(_, _, let bodyModel):
            bodyModel.onPageAppear()
        case .lockedWallet, .visaWallet:
            break
        }
    }

    func onPageDisappear() {
        switch self {
        case .singleWallet(_, _, let bodyModel):
            bodyModel?.onPageDisappear()
        case .multiWallet(_, _, let bodyModel):
            bodyModel.onPageDisappear()
        case .lockedWallet, .visaWallet:
            break
        }
    }
}
