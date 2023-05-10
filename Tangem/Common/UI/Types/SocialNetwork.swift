//
//  SocialNetwork.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum SocialNetwork: Hashable, CaseIterable, Identifiable {
    var id: Int { hashValue }

    case telegram
    case twitter
    case facebook
    case instagram
    case github
    case youtube
    case linkedin
    case discord

    var icon: ImageType {
        switch self {
        case .telegram:
            return Assets.SocialNetwork.telegram
        case .twitter:
            return Assets.SocialNetwork.twitter
        case .facebook:
            return Assets.SocialNetwork.facebook
        case .instagram:
            return Assets.SocialNetwork.instagram
        case .github:
            return Assets.SocialNetwork.gitHub
        case .youtube:
            return Assets.SocialNetwork.youTube
        case .linkedin:
            return Assets.SocialNetwork.linkedIn
        case .discord:
            return Assets.SocialNetwork.discord
        }
    }

    var url: URL? {
        switch self {
        case .telegram:
            switch Locale.current.languageCode {
            case LanguageCode.ru, LanguageCode.by:
                return URL(string: "https://t.me/tangem_chat_ru")
            default:
                return URL(string: "https://t.me/tangem_chat")
            }
        case .twitter:
            return URL(string: "https://twitter.com/tangem")
        case .facebook:
            return URL(string: "https://facebook.com/TangemCards/")
        case .instagram:
            return URL(string: "https://instagram.com/tangemcards")
        case .github:
            return URL(string: "https://github.com/tangem")
        case .youtube:
            return URL(string: "https://youtube.com/channel/UCFGwLS7yggzVkP6ozte0m1w")
        case .linkedin:
            return URL(string: "https://www.linkedin.com/company/tangem")
        case .discord:
            return URL(string: "https://discord.gg/7AqTVyqdGS")
        }
    }

    var name: String {
        switch self {
        case .telegram:
            return "Telegram"
        case .twitter:
            return "Twitter"
        case .facebook:
            return "Facebook"
        case .instagram:
            return "Instagram"
        case .github:
            return "GitHub"
        case .youtube:
            return "YouTube"
        case .linkedin:
            return "LinkedIn"
        case .discord:
            return "Discord"
        }
    }
}
