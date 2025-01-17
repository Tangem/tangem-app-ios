//
//  ReceiveBottomSheetView.swift
//  Tangem
//
//  Created by Andrew Son on 16/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReceiveBottomSheetView: View {
    @ObservedObject var viewModel: ReceiveBottomSheetViewModel

    @State private var containerWidth: CGFloat = 0

    var body: some View {
        VStack {
            mainContent
        }
        .onAppear(perform: viewModel.onViewAppear)
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            PagerWithDots(
                viewModel.addressInfos,
                indexUpdateNotifier: viewModel.addressIndexUpdateNotifier,
                pageWidth: containerWidth
            ) { info in
                VStack(spacing: 0) {
                    Text(viewModel.headerForAddress(with: info))
                        .multilineTextAlignment(.center)
                        .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                        .padding(.horizontal, 60)
                        .padding(.top, 4)

                    Image(uiImage: info.addressQRImage)
                        .resizable()
                        .frame(width: 220, height: 220)
                        .padding(.top, 18)

                    SUILabel(viewModel.stringForAddress(info.address))
                        .padding(.horizontal, 60)
                        .padding(.top, 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.copyToClipboard()
                        }

                    if let memoWarningMessage = viewModel.memoWarningMessage {
                        Text(memoWarningMessage)
                            .padding(.top, 12)
                            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
                    }

                    NotificationView(
                        input: .init(
                            style: .plain,
                            severity: .info,
                            settings: .init(
                                event: ReceiveNotificationEvent(
                                    currencySymbol: viewModel.currencySymbol,
                                    networkName: viewModel.networkName
                                ),
                                dismissAction: nil
                            )
                        )
                    )
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            .frame(width: containerWidth)

            HStack(spacing: 12) {
                MainButton(
                    title: Localization.commonCopy,
                    icon: .leading(Assets.copy),
                    style: .secondary,
                    action: viewModel.copyToClipboard
                )

                MainButton(
                    title: Localization.commonShare,
                    icon: .leading(Assets.share),
                    style: .secondary,
                    action: viewModel.share
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)
        }
        .readGeometry(\.size.width, bindTo: $containerWidth)
    }
}

struct ReceiveBottomSheet_Previews: PreviewProvider {
    static var btcAddressBottomSheet: ReceiveBottomSheetViewModel {
        ReceiveBottomSheetViewModel(
            tokenItem: .blockchain(.init(.bitcoin(testnet: false), derivationPath: nil)),
            addressInfos: [
                .init(
                    address: "bc1qeguhvlnxu4lwg48p5sfhxqxz679v3l5fma9u0c",
                    type: .default,
                    localizedName: "default",
                    addressQRImage: QrCodeGenerator.generateQRCode(from: "bc1qeguhvlnxu4lwg48p5sfhxqxz679v3l5fma9u0c")
                ),
                .init(
                    address: "18VEbRSEASi1npnXnoJ6pVVBrhT5zE6qRz",
                    type: .legacy,
                    localizedName: "legacy",
                    addressQRImage: QrCodeGenerator.generateQRCode(from: "18VEbRSEASi1npnXnoJ6pVVBrhT5zE6qRz")
                ),
            ],
            hasMemo: false
        )
    }

    static var singleAddressBottomSheet: ReceiveBottomSheetViewModel {
        ReceiveBottomSheetViewModel(
            tokenItem: .token(.tetherMock, .init(.polygon(testnet: false), derivationPath: nil)),
            addressInfos: [
                .init(
                    address: "0xEF08EA3531D219EDE813FB521e6D89220198bcB1",
                    type: .default,
                    localizedName: "default",
                    addressQRImage: QrCodeGenerator.generateQRCode(from: "0xEF08EA3531D219EDE813FB521e6D89220198bcB1")
                ),
            ],
            hasMemo: false
        )
    }

    static var previews: some View {
        Group {
            VStack {
                Colors.Background.secondary
                    .overlay(
                        ReceiveBottomSheetView(viewModel: btcAddressBottomSheet)
                            .background(Colors.Background.primary),

                        alignment: .bottom
                    )
            }

            VStack {
                StatefulPreviewWrapper(
                    Optional(
                        btcAddressBottomSheet
                    )
                ) { viewModel in
                    VStack {
                        Button("BTC address bottom sheet") {
                            viewModel.wrappedValue = nil
                            viewModel.wrappedValue = btcAddressBottomSheet
                        }
                        .padding()

                        NavHolder()
                            .bottomSheet(
                                item: viewModel,
                                backgroundColor: Colors.Background.primary
                            ) { model in
                                ReceiveBottomSheetView(viewModel: model)
                            }
                    }
                }

                StatefulPreviewWrapper(
                    Optional(
                        singleAddressBottomSheet
                    )
                ) { viewModel in
                    VStack {
                        Button("Single address bottom sheet") {
                            viewModel.wrappedValue = nil
                            viewModel.wrappedValue = singleAddressBottomSheet
                        }
                        .padding()

                        NavHolder()
                            .bottomSheet(
                                item: viewModel,
                                backgroundColor: Colors.Background.primary
                            ) { model in
                                ReceiveBottomSheetView(viewModel: model)
                            }
                    }
                }
            }
        }
    }
}
