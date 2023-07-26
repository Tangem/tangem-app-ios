//
//  ReferralView.swift
//  Tangem
//
//  Created by Andrew Son on 02/11/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import AlertToast

struct ReferralView: View {
    @ObservedObject var viewModel: ReferralViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Assets.referralDude.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, 40)

                    Text(Localization.referralTitle)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 57)
                        .padding(.top, 28)
                        .padding(.bottom, 32)

                    content
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 10))
                }
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height + geometry.safeAreaInsets.bottom)
            }
            .edgesIgnoringSafeArea(.bottom)
            .toast(isPresenting: $viewModel.showCodeCopiedToast) {
                AlertToast(type: .complete(Color.tangemGreen), title: Localization.referralPromoCodeCopied)
            }
        }
        .alert(item: $viewModel.errorAlert, content: { $0.alert })
        .navigationBarTitle(Text(Localization.detailsReferralTitle), displayMode: .inline)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isProgramInfoLoaded {
            referralContent
        } else {
            loaderContent
        }
    }

    @ViewBuilder
    private var referralContent: some View {
        VStack(spacing: 0) {
            IconWithMessageView(
                Assets.cryptoCurrencies,
                header: { Text(Localization.referralPointCurrenciesTitle) },
                description: {
                    Text(Localization.referralPointCurrenciesDescriptionPrefix + " ") +
                        Text(viewModel.award).foregroundColor(Colors.Text.primary1) +
                        Text(viewModel.awardDescriptionSuffix)
                }
            )

            IconWithMessageView(
                Assets.discount,
                header: { Text(Localization.referralPointDiscountTitle) },
                description: {
                    Text(Localization.referralPointDiscountDescriptionPrefix + " ") +
                        Text(viewModel.discount).foregroundColor(Colors.Text.primary1) +
                        Text(" " + Localization.referralPointDiscountDescriptionSuffix)
                }
            )
            .padding(.top, viewModel.isAlreadyReferral ? 20 : 38)

            Spacer()

            if viewModel.isAlreadyReferral {
                alreadyReferralBottomView
            } else {
                notReferralView
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var loaderContent: some View {
        VStack(alignment: .leading, spacing: 38) {
            IconWithMessagePlaceholderView(icon: Assets.cryptoCurrencies)

            IconWithMessagePlaceholderView(icon: Assets.discount)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var tosButton: some View {
        Button(action: viewModel.openTOS) {
            Text(viewModel.tosButtonPrefix) +
                Text(Localization.commonTermsAndConditions).foregroundColor(Colors.Text.accent) +
                Text(" " + Localization.referralTosSuffix)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .font(Fonts.Regular.footnote)
        .foregroundColor(Colors.Text.tertiary)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var alreadyReferralBottomView: some View {
        VStack(spacing: 14) {
            Spacer()

            VStack(spacing: 8) {
                Text(Localization.referralPromoCodeTitle)
                    .style(
                        Fonts.Bold.footnote,
                        color: Colors.Text.tertiary
                    )

                Text(viewModel.promoCode)
                    .style(
                        Fonts.Regular.title1,
                        color: Colors.Text.primary1
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Colors.Background.primary)
            .cornerRadius(14)

            HStack(spacing: 12) {
                TangemButton(
                    title: Localization.commonCopy,
                    systemImage: "square.on.square",
                    iconPosition: .leading,
                    iconPadding: 10,
                    action: viewModel.copyPromoCode
                )
                .buttonStyle(TangemButtonStyle(
                    colorStyle: .black,
                    layout: .flexibleWidth
                ))

                TangemButton(
                    title: Localization.commonShare,
                    systemImage: "arrowshape.turn.up.forward",
                    iconPosition: .leading,
                    iconPadding: 10,
                    action: viewModel.sharePromoCode
                )
                .buttonStyle(TangemButtonStyle(
                    colorStyle: .black,
                    layout: .flexibleWidth
                ))
            }

            HStack {
                Text(Localization.referralFriendsBoughtTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                Text(viewModel.numberOfWalletsBought)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }
            .roundedBackground(
                with: Colors.Background.primary,
                padding: 16,
                radius: 14
            )
            tosButton
        }
    }

    @ViewBuilder
    private var notReferralView: some View {
        VStack(spacing: 12) {
            tosButton

            TangemButton(
                title: Localization.referralButtonParticipate,
                image: "tangemIcon",
                iconPosition: .trailing,
                iconPadding: 10,
                action: {
                    runTask(viewModel.participateInReferralProgram)
                }
            )
            .buttonStyle(
                TangemButtonStyle(
                    colorStyle: .black,
                    layout: .flexibleWidth,
                    isLoading: viewModel.isProcessingRequest
                )
            )
        }
    }
}

struct ReferralView_Previews: PreviewProvider {
    private static let demoCard = PreviewCard.tangemWalletBackuped
    static var previews: some View {
        NavigationView {
            ReferralView(
                viewModel: ReferralViewModel(
                    userWalletId: Data(),
                    userTokensManager: UserTokensManagerMock(),
                    coordinator: ReferralCoordinator()
                )
            )
        }
        .previewGroup(devices: [.iPhone7], withZoomed: false)

        NavigationView {
            ReferralView(
                viewModel: ReferralViewModel(
                    userWalletId: Data(hexString: "6772C99F8B400E6F59FFCE0C4A66193BFD49DE2D9738868DE36F5E16569BB4F9"),
                    userTokensManager: UserTokensManagerMock(),
                    coordinator: ReferralCoordinator()
                )
            )
        }
        .previewGroup(devices: [.iPhone7], withZoomed: false)
    }
}
