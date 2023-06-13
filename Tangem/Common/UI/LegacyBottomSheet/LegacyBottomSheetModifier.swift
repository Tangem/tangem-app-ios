//
//  LegacyBottomSheetModifier.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 17.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

struct LegacyBottomSheetModifier<ContentView: View>: ViewModifier {
    @Binding private var isPresented: Bool
    @State private var bottomSheetViewController: BottomSheetBaseController?

    private let viewModelSettings: BottomSheetSettings
    private let contentView: () -> ContentView

    init(
        isPresented: Binding<Bool>,
        viewModelSettings: BottomSheetSettings,
        @ViewBuilder contentView: @escaping () -> ContentView
    ) {
        _isPresented = isPresented
        self.viewModelSettings = viewModelSettings
        self.contentView = contentView
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented, perform: updatePresentation(_:))
    }

    private func updatePresentation(_ isPresented: Bool) {
        let windowScene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        })

        guard let windowScene = windowScene as? UIWindowScene,
              let rootWindow = (windowScene.delegate as? UIWindowSceneDelegate)?.window,
              let root = rootWindow?.rootViewController else {
            return
        }

        var controllerToPresentFrom = root
        while let presented = controllerToPresentFrom.presentedViewController {
            controllerToPresentFrom = presented
        }

        if isPresented {
            let wrappedView = BottomSheetWrappedView(
                content: contentView(),
                settings: viewModelSettings
            ) {
                bottomSheetViewController?.dismiss(animated: true)
            }

            bottomSheetViewController = BottomSheetViewController(
                isPresented: $isPresented,
                content: wrappedView
            )

            bottomSheetViewController?.cornerRadius = viewModelSettings.cornerRadius
            bottomSheetViewController?.backgroundColor = UIColor(viewModelSettings.overlayColor)
            bottomSheetViewController?.contentBackgroundColor = UIColor(viewModelSettings.contentBackgroundColor)
            bottomSheetViewController?.swipeDownToDismissEnabled = viewModelSettings.swipeDownToDismissEnabled
            bottomSheetViewController?.tapOutsideToDismissEnabled = viewModelSettings.tapOutsideToDismissEnabled

            controllerToPresentFrom.present(bottomSheetViewController!, animated: true)
        } else {
            bottomSheetViewController?.dismiss(animated: true)
        }
    }
}
