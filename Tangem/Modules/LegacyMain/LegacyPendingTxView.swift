//
//  LegacyPendingTxView.swift
//  Tangem
//
//  Created by Alexander Osokin on 14.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct LegacyPendingTxView: View, Identifiable {
    var id: Int { pendingTx.id }
    let pendingTx: TransactionRecord
    var pushAction: (() -> Void)?

    var address: String {
        pendingTx.destination
    }

    var titlePrefixLocalized: String {
        switch pendingTx.direction {
        case .outgoing:
            return Localization.walletPendingTxSending
        case .incoming:
            return Localization.walletPendingTxReceiving
        }
    }

    func titleFormat(address: String) -> String {
        switch pendingTx.direction {
        case .outgoing:
            return Localization.walletPendingTxSendingAddressFormat(address)
        case .incoming:
            return Localization.walletPendingTxReceivingAddressFormat(address)
        }
    }

    var text: String {
        if address == "unknown" {
            return Localization.walletBalanceTxInProgress
        } else {
            return titlePrefixLocalized + " " + pendingTx.transferAmount + " " + titleFormat(address: AddressFormatter(address: address).truncated())
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                if address != "unknown" {
                    Image(systemName: pendingTx.direction == .incoming ? "arrow.down" :
                        "arrow.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color.tangemGrayDark6)
                        .frame(width: 12.0, height: 12.0)
                        .padding(.trailing, 8)
                }

                Text(text)
                    .font(Font.system(size: 13.0, weight: .medium, design: .default))
                    .foregroundColor(Color.tangemGrayDark6)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if pendingTx.canBePushed {
                    RoundedRectButton(action: {
                        pushAction?()
                    }, title: Localization.commonPush)
                }
            }
            .padding(.horizontal, 20.0)
            .padding(.vertical, 11.0)
        }
        .background(Color.white)
        .cornerRadius(6.0)
    }
}

struct LegacyPendingTxView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemBgGray
            VStack {
                LegacyPendingTxView(pendingTx: TransactionRecord(amountType: .coin, destination: "0x2314719083467891237649123675478612354", timeFormatted: "05:06", transferAmount: "0.00000002 BTC", canBePushed: false, direction: .incoming, status: .inProgress))
                LegacyPendingTxView(pendingTx: TransactionRecord(amountType: .coin, destination: "0x2314719083467891237649123675478612354", timeFormatted: "05:06", transferAmount: "0.00000002 BTC", canBePushed: false, direction: .outgoing, status: .inProgress))
                LegacyPendingTxView(pendingTx: TransactionRecord(amountType: .coin, destination: "0x2314719083467891237649123675478612354", timeFormatted: "05:06", transferAmount: "0.2 BTC", canBePushed: true, direction: .outgoing, status: .inProgress))
            }
            .padding(.horizontal, 16)
        }
    }
}
