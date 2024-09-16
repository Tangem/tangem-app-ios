//
//  MainBottomSheetFooterView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 28.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomSheetFooterView: View {
    @ObservedObject var viewModel: MainBottomSheetFooterViewModel

    var body: some View {
        VStack(spacing: 0.0) {
            FixedSpacer.vertical(14.0)

            // `MainBottomSheetHeaderInputView` is used here as a dummy view, used for layout calculation (i.e. footer height)
            MainBottomSheetHeaderInputView(
                searchText: .constant(""),
                isTextFieldFocused: .constant(false),
                allowsHitTestingForTextField: false
            )
            .padding(.bottom, bottomInset)
            .background(Colors.Background.primary) // Fills a small gap at the bottom on notchless devices
            .overlay(alignment: .top) {
                snapshotOverlay
            }
            .cornerRadius(cornerRadius, corners: .topEdge)
            .bottomScrollableSheetGrabber()
            .bottomScrollableSheetShadow()
        }
    }

    @ViewBuilder
    private var snapshotOverlay: some View {
        if let snapshotImage = viewModel.snapshotImage {
            Image(uiImage: snapshotImage)
        }
    }

    private var bottomInset: CGFloat {
        return max(
            // Devices with a notch
            UIApplication.safeAreaInsets.bottom - MainBottomSheetHeaderInputView.Constants.bottomInset,
            // Notchless devices
            MainBottomSheetHeaderInputView.Constants.topInset - MainBottomSheetHeaderInputView.Constants.bottomInset,
            // Fallback
            .zero
        )
    }

    private var cornerRadius: CGFloat {
        UIDevice.current.hasHomeScreenIndicator
            ? RootViewControllerFactory.Constants.notchDevicesOverlayCornerRadius
            : RootViewControllerFactory.Constants.notchlessDevicesOverlayCornerRadius
    }
}
