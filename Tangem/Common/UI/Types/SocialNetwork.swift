//
//  SocialNetwork.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SocialNetwork {
    var name: String {
        networkType.name
    }

    var icon: ImageType {
        networkType.icon
    }

    var url: URL {
        fatalError()
    }

    private let networkType: SocialNetworkType
}

struct DefaultSocialNetworkURLBuilder {
    private let host: String

    init(host: String) {
        self.host = host
    }

    init(socialNetworkType: SocialNetworkType) {
        host = socialNetworkType.linkHost
    }

    func url(id: String) -> URL? {
        guard let url = URL(string: host) else {
            return nil
        }

        return url.appendingPathComponent(id)
    }
}

// var url: URL? {
//    switch self {
//    case .telegram:
//        switch Locale.current.languageCode {
//        case LanguageCode.ru, LanguageCode.by:
//            return URL(string: "https://t.me/tangem_chat_ru")
//        default:
//            return URL(string: "https://t.me/tangem_chat")
//        }
//    case .twitter:
//        return URL(string: "https://twitter.com/tangem")
//    case .facebook:
//        return URL(string: "https://www.facebook.com/tangemwallet")
//    case .instagram:
//        return URL(string: "https://www.instagram.com/tangemwallet")
//    case .youtube:
//        return URL(string: "https://youtube.com/channel/UCFGwLS7yggzVkP6ozte0m1w")
//    case .linkedin:
//        return URL(string: "https://www.linkedin.com/company/tangem")
//    case .discord:
//        return URL(string: "https://discord.gg/7AqTVyqdGS")
//    case .reddit:
//        return URL(string: "https://www.reddit.com/r/Tangem/")
//    case .github:
//        return URL(string: "https://github.com/tangem")
//    }
// }
enum SocialNetworkType: Hashable, Identifiable {
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

    var linkHost: String {
        switch self {
        case .telegram:
            return "https://t.me"
        case .twitter:
            return "https://twitter.com"
        case .facebook:
            return "https://www.facebook.com"
        case .instagram:
            return "https://www.instagram.com"
        case .youtube:
            return "https://youtube.com/channel"
        case .linkedin:
            return "https://www.linkedin.com/company"
        case .discord:
            return "https://discord.gg"
        case .reddit:
            return "https://www.reddit.com/r"
        case .github:
            return "https://github.com"
        }
    }
}

extension SocialNetworkType {
    enum DiscordLinkType {
        case plain(String)
        case serverInvite(String)

        var path: String {
            switch self {
            case .plain(let string):
                return string
            case .serverInvite(let string):
                return "invite/\(string)"
            }
        }
    }
}

enum TangemSocialNetwork: Hashable, CaseIterable, Identifiable {
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
            return URL(string: "https://www.facebook.com/tangemwallet")
        case .instagram:
            return URL(string: "https://www.instagram.com/tangemwallet")
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

    static var list: [[TangemSocialNetwork]] {
        [
            [.twitter, .telegram, .instagram, .facebook, .linkedin, .youtube],
            [.discord, .reddit, .github],
        ]
    }
}
