//
//  PushNotificationsBottomSheetView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct PushNotificationsBottomSheetView: View {
    let viewModel: PushNotificationsPermissionRequestViewModel

    var body: some View {
        VStack {
            PushNotificationsPermissionRequestView(
                viewModel: viewModel,
                topInset: -32.0, // The mock-ups are messy, so this value is found by trial and error
                buttonsAxis: .horizontal
            )
        }
        .fixedSize(horizontal: false, vertical: true) // Compresses all child views to their intrinsic content sizes
    }
}

// MARK: - Previews

#Preview {
    let viewModel = PushNotificationsPermissionRequestViewModel(
        permissionManager: PushNotificationsPermissionManagerStub(),
        delegate: PushNotificationsPermissionRequestDelegateStub()
    )

    return PushNotificationsBottomSheetView(viewModel: viewModel)
}
