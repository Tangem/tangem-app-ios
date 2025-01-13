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

    private var isLoading: Bool = false

    init(input: NotificationViewInput) {
        settings = input.settings
        style = input.style
    }

    /// Use this initializer when you need to refresh `MainButton`, e.g. when button can display spinned
    /// or `MainButton` can toggle enable state during notification lifetime
    init(settings: Settings, buttons: [NotificationButton]) {
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
        .background(settings.event.colorScheme.background)
        .overlay(settings.event.colorScheme.overlay)
        .cornerRadiusContinuous(14)
    }

    @ViewBuilder
    private var dismissOverlay: some View {
        if settings.event.isDismissable {
            HStack {
                Spacer()

                Button(action: {
                    settings.dismissAction?(settings.id)
                }) {
                    Assets.cross.image
                        .foregroundColor(settings.event.colorScheme.dismissButtonColor)
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
                    ForEach(buttonSettings, id: \.id) { buttonInfo in
                        MainButton(
                            title: buttonInfo.actionType.title,
                            icon: buttonInfo.actionType.icon,
                            style: buttonInfo.actionType.style,
                            size: .notification,
                            action: {
                                buttonInfo.action(settings.id, buttonInfo.actionType)
                            }
                        )
                        .setIsLoading(to: buttonInfo.isWithLoader && isLoading)
                    }
                }
            }
        }
    }

    private var messageIconContent: some View {
        HStack(spacing: 12) {
            icon

            VStack(alignment: .leading, spacing: 4) {
                switch settings.event.title {
                case .string(let string):
                    Text(string)
                        .style(Fonts.Bold.footnote, color: settings.event.colorScheme.titleColor)
                        .fixedSize(horizontal: false, vertical: true)
                case .attributed(let attributedString):
                    Text(attributedString)
                        .fixedSize(horizontal: false, vertical: true)
                case .none:
                    EmptyView()
                }

                if let description = settings.event.description {
                    // We use the `LocalizedStringKey` here for the `RichText` support
                    Text(LocalizedStringKey(description))
                        .multilineTextAlignment(.leading)
                        .style(Fonts.Regular.footnote, color: settings.event.colorScheme.messageColor)
                        .infinityFrame(axis: .horizontal, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .padding(.trailing, 20)
    }

    private var icon: some View {
        Group {
            switch settings.event.icon.iconType {
            case .image(let image):
                image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(settings.event.icon.color)
            case .icon(let tokenIconInfo):
                TokenIcon(tokenIconInfo: tokenIconInfo, size: settings.event.icon.size)
            case .progressView:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .foregroundColor(Colors.Icon.informative)
            case .placeholder:
                Color.clear
            }
        }
        .frame(size: settings.event.icon.size)
    }
}

extension NotificationView: Setupable {
    /// Toggles `MainButton` to new state.
    /// - Note: This will only work for notifications with `.withButtons` style. Also note that all buttons simultaneously will change `isLoading` state
    func setButtonsLoadingState(to isLoading: Bool) -> Self {
        map { $0.isLoading = isLoading }
    }
}

// MARK: - Previews

struct NotificationView_Previews: PreviewProvider {
    class PreviewViewModel: ObservableObject {
        lazy var notificationInputs: [NotificationViewInput] = [
            .init(
                style: .withButtons([
                    .init(action: { _, _ in

                    }, actionType: .backupCard, isWithLoader: false),
                ]),
                severity: .info,
                settings: NotificationView.Settings(event: GeneralNotificationEvent.missingBackup, dismissAction: { [weak self] id in
                    self?.removeNotification(with: id)
                })
            ),
            .init(
                style: .withButtons([
                    .init(action: { _, _ in

                    }, actionType: .generateAddresses, isWithLoader: false),
                ]),
                severity: .warning,
                settings: NotificationView.Settings(event: GeneralNotificationEvent.missingDerivation(numberOfNetworks: 1), dismissAction: { [weak self] id in
                    self?.removeNotification(with: id)
                })
            ),
            .init(
                style: .plain,
                severity: .critical,
                settings: NotificationView.Settings(
                    event: GeneralNotificationEvent.devCard,
                    dismissAction: nil
                )
            ),
        ]

        @Published var notifications: [NotificationViewInput] = []

        init() {
            notifications = notificationInputs
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
                            .transition(.notificationTransition)
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
