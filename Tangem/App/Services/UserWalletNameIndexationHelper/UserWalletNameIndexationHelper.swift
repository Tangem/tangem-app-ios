//
//  UserWalletNameIndexationHelper.swift
//  Tangem
//
//  Created by Andrey Chukavin on 17.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class UserWalletNameIndexationHelper {
    private var existingNames: Set<String>

    private init(existingNames: [String]) {
        self.existingNames = Set(existingNames).filter { NameComponents(from: $0) != nil }
    }

    static func migratedWallets<T: NameableWallet>(_ wallets: [T]) -> [T]? {
        var didChangeNames = false

        var wallets = wallets.map { wallet in
            var wallet = wallet
            let trimmedName = wallet.name.trimmed()
            if trimmedName != wallet.name {
                didChangeNames = true
                wallet.name = trimmedName
            }
            return wallet
        }

        let helper = UserWalletNameIndexationHelper(existingNames: wallets.map(\.name))
        for (index, wallet) in wallets.enumerated() {
            let suggestedName = helper.suggestedName(for: wallet.name)
            if wallet.name != suggestedName {
                var wallet = wallet
                wallet.name = suggestedName
                wallets[index] = wallet
                didChangeNames = true
            }
        }

        return didChangeNames ? wallets : nil
    }

    static func suggestedName(_ rawName: String, names: [String]) -> String {
        if NameComponents(from: rawName) != nil {
            return rawName
        }

        let indicesByNameTemplate = names.reduce(into: [String: Set<Int>]()) { dict, name in
            guard let nameComponents = NameComponents(from: name) else {
                dict[name, default: []].insert(1)
                return
            }

            dict[nameComponents.template, default: []].insert(nameComponents.index)
        }

        let nameTemplate = rawName.trimmed()
        let nameIndex = indicesByNameTemplate.nextIndex(for: nameTemplate)

        if nameIndex == 1 {
            return nameTemplate
        } else {
            return "\(nameTemplate) \(nameIndex)"
        }
    }

    private func suggestedName(for rawName: String) -> String {
        let name = Self.suggestedName(rawName, names: Array(existingNames))
        existingNames.insert(name)
        return name
    }
}

private extension UserWalletNameIndexationHelper {
    struct NameComponents {
        static let nameComponentsRegex = try! NSRegularExpression(pattern: "^(.+)(\\s+\\d+)$")

        let template: String
        let index: Int

        init?(from rawName: String) {
            let name = rawName.trimmingCharacters(in: .whitespaces)
            let range = NSRange(location: 0, length: name.count)

            guard
                let match = Self.nameComponentsRegex.matches(in: name, range: range).first,
                match.numberOfRanges == 3,
                let templateRange = Range(match.range(at: 1), in: name),
                let indexRange = Range(match.range(at: 2), in: name),
                let index = Int(String(name[indexRange]).trimmingCharacters(in: .whitespaces))
            else {
                return nil
            }

            template = String(name[templateRange])
            self.index = index
        }
    }
}

private extension [String: Set<Int>] {
    func nextIndex(for nameTemplate: String) -> Int {
        let indices = self[nameTemplate, default: []]

        if indices.isEmpty {
            return 1
        }

        for i in 1 ... indices.count {
            if !indices.contains(i) {
                return i
            }
        }

        let defaultIndex = indices.count + 1
        return defaultIndex
    }
}
