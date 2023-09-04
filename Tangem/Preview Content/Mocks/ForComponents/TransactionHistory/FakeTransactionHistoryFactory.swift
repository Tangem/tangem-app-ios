//
//  FakeTransactionHistoryFactory.swift
//  Tangem
//
//  Created by Andrew Son on 26/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct FakeTransactionHistoryFactory {
    func createFakeTxs(address: String, currencyCode: String) -> [TransactionRecord] {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        return [
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 433)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 433)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 3.3, decimals: 8)),
                status: .unconfirmed,
                isOutgoing: false,
                type: .transfer,
                date: today
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 50)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 50)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 1.3, decimals: 8)),
                status: .unconfirmed,
                isOutgoing: false,
                type: .transfer,
                date: calendar.date(byAdding: .hour, value: -4, to: today)
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 0.5)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 0.5)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 2.1, decimals: 8)),
                status: .unconfirmed,
                isOutgoing: true,
                type: .transfer,
                date: calendar.date(byAdding: .hour, value: -5, to: today)
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 15)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 15)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 2.1, decimals: 8)),
                status: .confirmed,
                isOutgoing: true,
                type: .transfer,
                date: yesterday
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 0.000000532154)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 0.000000532154)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 2.1, decimals: 8)),
                status: .unconfirmed,
                isOutgoing: true,
                type: .transfer,
                date: calendar.date(byAdding: .hour, value: -3, to: yesterday)
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 0.532154)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 0.532154)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 2.1, decimals: 8)),
                status: .confirmed,
                isOutgoing: true,
                type: .transfer,
                date: calendar.date(byAdding: .hour, value: -8, to: yesterday)
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 15)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 15)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 2.1, decimals: 8)),
                status: .confirmed,
                isOutgoing: true,
                type: .transfer,
                date: yesterday
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 0.000000532154)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 0.000000532154)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 2.1, decimals: 8)),
                status: .unconfirmed,
                isOutgoing: true,
                type: .transfer,
                date: calendar.date(byAdding: .hour, value: -3, to: yesterday)
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 0.532154)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 0.532154)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 2.1, decimals: 8)),
                status: .confirmed,
                isOutgoing: true,
                type: .transfer,
                date: calendar.date(byAdding: .hour, value: -8, to: yesterday)
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 15)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 15)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 2.1, decimals: 8)),
                status: .confirmed,
                isOutgoing: true,
                type: .transfer,
                date: yesterday
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 0.000000532154)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 0.000000532154)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 2.1, decimals: 8)),
                status: .unconfirmed,
                isOutgoing: true,
                type: .transfer,
                date: calendar.date(byAdding: .hour, value: -3, to: yesterday)
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 0.532154)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 0.532154)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 2.1, decimals: 8)),
                status: .confirmed,
                isOutgoing: true,
                type: .transfer,
                date: calendar.date(byAdding: .hour, value: -8, to: yesterday)
            ),
            TransactionRecord(
                hash: UUID().uuidString,
                source: .single(.init(address: address, amount: 15)),
                destination: .single(.init(address: .user("0x01230...3feed"), amount: 15)),
                fee: Fee(.init(type: .coin, currencySymbol: currencyCode, value: 2.1, decimals: 8)),
                status: .confirmed,
                isOutgoing: true,
                type: .transfer,
                date: yesterday
            ),
        ]
    }
}
