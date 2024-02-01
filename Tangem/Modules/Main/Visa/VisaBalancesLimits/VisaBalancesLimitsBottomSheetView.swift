//
//  VisaBalancesLimitsBottomSheetView.swift
//  Tangem
//
//  Created by Andrew Son on 10/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaBalancesLimitsBottomSheetView: View {
    @ObservedObject var viewModel: VisaBalancesLimitsBottomSheetViewModel

    var body: some View {
        VStack(spacing: 10) {
            Text("Balances & Limits")
                .style(Fonts.Bold.headline, color: Colors.Text.primary1)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)

            VStack(spacing: 14) {
                balancesView
                    .roundedBackground(with: Colors.Background.action, verticalPadding: 8, horizontalPadding: 14)

                limitsView
                    .roundedBackground(with: Colors.Background.action, verticalPadding: 8, horizontalPadding: 14)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .bindAlert($viewModel.alert)
    }

    private var balancesView: some View {
        VStack(spacing: 0) {
            sectionHeaderLine(leadingText: "Balance", infoAction: viewModel.openBalancesInfo)

            recordLine(with: "Total", amount: viewModel.totalAmount)

            recordLine(with: "AML verified", amount: viewModel.amlVerifiedAmount)

            recordLine(with: "Available", amount: viewModel.availableAmount)

            recordLine(with: "Blocked", amount: viewModel.blockedAmount)

            recordLine(with: "Debt", amount: viewModel.debtAmount)

            recordLine(with: "Pending refund", amount: viewModel.pendingRefundAmount)
        }
    }

    private var limitsView: some View {
        VStack(spacing: 0) {
            sectionHeaderLine(leadingText: "Limits", trailingText: viewModel.availabilityDescription, infoAction: viewModel.openLimitsInfo)

            recordLine(with: "Total", amount: viewModel.remainingOTPAmount)

            recordLine(with: "Other (no-otp)", amount: viewModel.remainingNoOtpAmount)

            recordLine(with: "Single transaction", amount: viewModel.singleTransactionAmount)
        }
    }

    private func sectionHeaderLine(leadingText: String, trailingText: String? = nil, infoAction: @escaping () -> Void) -> some View {
        HStack {
            Text(leadingText)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            Button(action: infoAction) {
                Assets.infoCircle20.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.inactive)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    private func recordLine(with title: String, amount: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            Spacer()

            SensitiveText(amount)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
        }
        .padding(.vertical, 8)
    }
}

private struct PreviewBottomSheet: View {
    @State private var viewModel: VisaBalancesLimitsBottomSheetViewModel?

    var body: some View {
        Button(action: generateBottomSheet) {
            Text("Open Balances & Limits")
        }
        .bottomSheet(item: $viewModel, settings: .init(backgroundColor: Colors.Background.tertiary)) { model in
            VisaBalancesLimitsBottomSheetView(viewModel: model)
        }
    }

    private func generateBottomSheet() {
        viewModel = .init(
            balances: .init(
                totalBalance: 492.45,
                verifiedBalance: 392.45,
                available: 356.45,
                blocked: 36.00,
                debt: 0.0,
                pendingRefund: 20.99
            ),
            limit: .init(
                limitExpirationDate: Date().addingTimeInterval(3600 * 24 * 1.5),
                limitDurationSeconds: 3600 * 24 * 3,
                singleTransaction: 100.00,
                otpLimit: 600.00,
                spentOTPAmount: 59.45,
                noOTPLimit: 50.0,
                spentNoOTPAmount: 12.5
            )
        )
    }
}

#Preview {
    PreviewBottomSheet()
}
