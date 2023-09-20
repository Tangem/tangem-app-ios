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

    case twitter
    case telegram
    case discord
    case reddit
    case instagram
    case facebook
    case linkedin
    case youtube
    case github

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
        case .youtube:
            return Assets.SocialNetwork.youTube
        case .linkedin:
            return Assets.SocialNetwork.linkedIn
        case .discord:
            return Assets.SocialNetwork.discord
        case .reddit:
            return Assets.SocialNetwork.reddit
        case .github:
            return Assets.SocialNetwork.github
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
        case .youtube:
            return URL(string: "https://youtube.com/channel/UCFGwLS7yggzVkP6ozte0m1w")
        case .linkedin:
            return URL(string: "https://www.linkedin.com/company/tangem")
        case .discord:
            return URL(string: "https://discord.gg/7AqTVyqdGS")
        case .reddit:
            return URL(string: "https://www.reddit.com/r/Tangem/")
        case .github:
            return URL(string: "https://github.com/tangem")
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
        case .youtube:
            return "YouTube"
        case .linkedin:
            return "LinkedIn"
        case .discord:
            return "Discord"
        case .reddit:
            return "Reddit"
        case .github:
            return "GitHub"
        }
    }

    static var list: [[SocialNetwork]] {
        [
            [.twitter, .telegram, .instagram, .facebook, .linkedin, .youtube],
            [.discord, .reddit, .github],
        ]
    }
}
