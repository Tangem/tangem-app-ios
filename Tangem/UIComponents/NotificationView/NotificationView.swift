//
//  NotificationView.swift
//  Tangem
//
//  Created by skibinalexander on 02.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct NotificationView: View {
    let settings: Settings
    let style: Style

    init(input: NotificationViewInput) {
        settings = input.settings
        style = input.style
    }

    /// Use this initializer when you need to refresh `MainButton`, e.g. when button can display spinned
    /// or `MainButton` can toggle enable state during notification lifetime
    init(settings: Settings, buttons: [MainButton.Settings]) {
        self.settings = settings
        style = .withButtons(buttons)
    }

    var body: some View {
        ZStack(alignment: .top) {
            content

            dismissOverlay
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(settings.colorScheme.color)
        .cornerRadiusContinuous(14)
    }

    @ViewBuilder
    private var dismissOverlay: some View {
        if settings.isDismissable {
            HStack {
                Spacer()

                Button(action: {
                    settings.dismissAction?(settings.id)
                }) {
                    Assets.cross.image
                        .foregroundColor(Colors.Icon.inactive)
                }
            }
            .padding(.top, -4)
            .padding(.trailing, -6)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .plain:
            messageIconContent
        case .tappable(let action):
            Button(action: { action(settings.id) }) {
                HStack(spacing: 0) {
                    messageIconContent

                    Spacer()

                    Assets.chevronRight.image
                        .foregroundColor(Colors.Icon.inactive)
                }
            }
        case .withButtons(let buttonSettings):
            VStack(alignment: .leading, spacing: 14) {
                messageIconContent

                HStack(spacing: 8) {
                    ForEach(buttonSettings) { settings in
                        MainButton(settings: settings)
                    }
                }
            }
        }
    }

    private var messageIconContent: some View {
        HStack(spacing: 12) {
            settings.icon.image
                .resizable()
                .foregroundColor(settings.icon.color)
                .frame(size: .init(bothDimensions: 20))

            VStack(alignment: .leading, spacing: 4) {
                Text(settings.title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                if let description = settings.description {
                    Text(description)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(3)
                        .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
                        .infinityFrame(axis: .horizontal, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .padding(.trailing, 20)
    }
}

// MARK: - Previews

struct NotificationView_Previews: PreviewProvider {
    class PreviewViewModel: ObservableObject {
        lazy var notificationInputs: [NotificationViewInput] = [
            .init(
                style: .tappable(action: { [weak self] id in
                    self?.notificationTapped(with: id)
                }),
                settings: .init(
                    colorScheme: .gray,
                    icon: .init(image: Assets.attentionRed.image),
                    title: "Used card",
                    description: "The card signed transactions in the past",
                    isDismissable: false,
                    dismissAction: nil
                )
            ),
            .init(
                style: .withButtons([
                    .init(
                        title: "Generate addresses",
                        icon: .trailing(Assets.tangemIcon),
                        style: .primary,
                        size: .notification,
                        isLoading: false,
                        isDisabled: false,
                        action: {
                            print("Generate addresses tapped")
                        }
                    ),
                ]),
                settings: .init(
                    colorScheme: .white,
                    icon: .init(image: Assets.warningIcon.image),
                    title: "Some addresses are missing",
                    description: "Generate addresses for 2 new networks using your card.",
                    isDismissable: false,
                    dismissAction: nil
                )
            ),
            .init(
                style: .withButtons([
                    .init(
                        title: "Buy ETH",
                        icon: nil,
                        style: .secondary,
                        size: .notification,
                        isLoading: false,
                        isDisabled: false,
                        action: {
                            print("Buy ETH button tapped on notification")
                        }
                    ),
                ]),
                settings: .init(
                    colorScheme: .white,
                    icon: .init(image: Image("ethereum.fill")),
                    title: "Unable to cover Ethereum fee",
                    description: "To make a USD Coin transaction you need to depo sit some Ethereum (ETH) to cover the network fee.",
                    isDismissable: true,
                    dismissAction: { [weak self] id in
                        self?.removeNotification(with: id)
                    }
                )
            ),
            .init(
                style: .plain,
                settings: .init(
                    colorScheme: .gray,
                    icon: .init(image: Assets.warningIcon.image),
                    title: "Network rent fee",
                    description: "The Solana network charges a fee of 0.0000056 every two days. Accounts without money will be removed from the network. Refill your account with 0.000465 to avoid paying the rent.",
                    isDismissable: true,
                    dismissAction: { [weak self] id in
                        self?.removeNotification(with: id)
                    }
                )
            ),
            .init(
                style: .plain,
                settings: .init(
                    colorScheme: .gray,
                    icon: .init(image: Assets.attentionRed.image),
                    title: "Development card",
                    description: "The card you scanned is a development card. Don't accept it as a payment",
                    isDismissable: false,
                    dismissAction: nil
                )
            ),
            .init(
                style: .tappable(action: { [weak self] id in
                    self?.notificationTapped(with: id)
                }),
                settings: .init(
                    colorScheme: .gray,
                    icon: .init(image: Assets.lock.image, color: Colors.Icon.primary1),
                    title: "Unlock needed",
                    description: "You need to unlock this wallet before you can use it",
                    isDismissable: false,
                    dismissAction: nil
                )
            ),
        ]

        @Published var notifications: [NotificationViewInput] = []

        init() {
            notifications = [
                notificationInputs[notificationInputs.count - 2],
                notificationInputs[3],
                notificationInputs[2],
            ]
        }

        func addNotification() {
            notifications.append(
                notificationInputs[(0 ..< notificationInputs.count).randomElement() ?? 0]
            )
        }

        func removeNotification(with id: NotificationViewId) {
            notifications.removeAll(where: { $0.settings.id == id })
        }

        func notificationTapped(with id: NotificationViewId) {
            notifications.removeAll(where: { $0.settings.id == id })
        }
    }

    struct Preview: View {
        @ObservedObject var viewModel: PreviewViewModel = .init()

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(viewModel.notifications) { input in
                        NotificationView(input: input)
                            .transition(AnyTransition.scale.combined(with: .opacity))
                    }

                    Button(action: viewModel.addNotification) {
                        Text("Add notification")
                    }
                }
                .padding(.vertical, 40)

                .padding(.horizontal, 16)
                .animation(.default, value: viewModel.notifications)
                .infinityFrame()
            }
            .infinityFrame()
            .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        }
    }

    static var previews: some View {
        Preview()
    }
}
